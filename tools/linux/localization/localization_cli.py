#!/usr/bin/env python3
"""
Localization management CLI.

Features:
- Pull active sheet (module-per-tab) -> validate -> write module/locale YAML for slang and an intermediate JSON.
- Migrate legacy sheet/ARB -> new schema -> optional push to new sheet -> write YAML.
- Push local dataset back to the active sheet with a dry-run diff (auto-creates tabs).
- Validate placeholders/params/completeness before generation.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
import textwrap
from collections import defaultdict, OrderedDict
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Tuple

import requests
import yaml

try:
    import gspread
    from google.oauth2.service_account import Credentials
except Exception:  # pragma: no cover - optional dependency path
    gspread = None
    Credentials = None


class Colors:
    RED = "\033[0;31m"
    GREEN = "\033[0;32m"
    YELLOW = "\033[1;33m"
    BLUE = "\033[0;34m"
    PURPLE = "\033[0;35m"
    CYAN = "\033[0;36m"
    NC = "\033[0m"  # No Color


def log_info(message: str) -> None:
    print(f"{Colors.BLUE}ℹ️  {message}{Colors.NC}")


def log_success(message: str) -> None:
    print(f"{Colors.GREEN}✅ {message}{Colors.NC}")


def log_warning(message: str) -> None:
    print(f"{Colors.YELLOW}⚠️  {message}{Colors.NC}")


def log_error(message: str) -> None:
    print(f"{Colors.RED}❌ {message}{Colors.NC}")


def log_step(message: str) -> None:
    print(f"{Colors.PURPLE}🔸 {message}{Colors.NC}")


ALLOWED_TYPES = {"text", "rich", "plural", "select", "selectordinal", "context"}
VALID_STATUSES = {"active", "deprecated", "draft"}
DEFAULT_SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive.file",
]


@dataclass
class LocalizationRecord:
    module: str
    key: str
    type: str
    params: List[str]
    context: str
    description: str
    status: str
    tags: List[str]
    translations: Dict[str, str]
    last_updated: str = ""
    source: str = ""

    def identity(self) -> str:
        return f"{self.module}.{self.key}"

    def missing_languages(self, supported: Sequence[str]) -> List[str]:
        return [lang for lang in supported if not self.translations.get(lang)]


def load_config(path: str) -> Dict:
    cfg_path = Path(path)
    if not cfg_path.exists():
        log_error(f"Config not found: {path}")
        sys.exit(1)
    with cfg_path.open(encoding="utf-8") as f:
        return json.load(f)


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def slugify(text: str) -> str:
    cleaned = re.sub(r"[^\w\s-]", "", text.strip())
    cleaned = re.sub(r"[-\s]+", "_", cleaned)
    return cleaned.lower()


def parse_params(params_raw: str) -> List[str]:
    if not params_raw:
        return []
    parts = re.split(r"[;,]", params_raw)
    params: List[str] = []
    for part in parts:
        piece = part.strip()
        if not piece:
            continue
        if ":" in piece:
            name, _type = piece.split(":", 1)
            params.append(name.strip())
        else:
            params.append(piece)
    return [p for p in params if p]


def detect_placeholders(text: str) -> List[str]:
    if not text:
        return []
    # Ignore ICU plural/select placeholders after the first comma (e.g., {count, plural, ...})
    brace_placeholders = re.findall(r"\{([a-zA-Z_][\w]*)\}", text)
    dollar_placeholders = re.findall(r"\$\{?([a-zA-Z_][\w]*)\}?", text)
    candidates = set(brace_placeholders + dollar_placeholders)
    return sorted(candidates)


def normalize_placeholders(value: str, params: Sequence[str]) -> str:
    if not value:
        return value
    if re.search(r"\{\s*\w+\s*,\s*(plural|select)", value):
        # ICU string: keep as-is
        return value
    # Collapse accidental repeated dollars and normalize parameter placeholders to ${param}
    normalized = re.sub(r"\$\$+", lambda m: "$", value)
    for param in params:
        # Patterns: {param}, ${param}, $param, $$param, $ {param}, etc.
        normalized = re.sub(
            rf"\$+\s*\{{?\s*{re.escape(param)}\s*\}}?",
            lambda m, p=param: f"${{{p}}}",
            normalized,
        )
        normalized = re.sub(
            rf"\{{\s*{re.escape(param)}\s*\}}",
            lambda m, p=param: f"${{{p}}}",
            normalized,
        )
    normalized = re.sub(r"\$\$+", lambda m: "$", normalized)
    return normalized


def read_csv_text(csv_text: str) -> List[Dict[str, str]]:
    reader = csv.DictReader(csv_text.splitlines())
    return [row for row in reader]


def normalize_type(raw_type: str) -> str:
    value = (raw_type or "text").strip().lower()
    if value not in ALLOWED_TYPES:
        return "text"
    return value


def normalize_status(raw_status: str) -> str:
    value = (raw_status or "active").strip().lower()
    if value not in VALID_STATUSES:
        return "active"
    return value


def parse_sheet_rows(
    rows: List[Dict[str, str]],
    columns: Dict[str, str],
    languages: Sequence[str],
    source: str,
    default_module: Optional[str] = None,
) -> List[LocalizationRecord]:
    records: List[LocalizationRecord] = []
    for row in rows:
        module_col = (columns.get("module") or "").strip()
        module_raw = row.get(module_col, "").strip() if module_col else ""
        if not module_raw and default_module:
            module_raw = default_module
        key = row.get(columns.get("key", "") or "", "").strip()
        if not module_raw or not key:
            continue

        module = slugify(module_raw)
        type_value = normalize_type(row.get(columns.get("type", "") or "", "text"))
        params = parse_params(row.get(columns.get("params", "") or "", ""))
        context = row.get(columns.get("context", "") or "", "").strip()
        description = row.get(columns.get("description", "") or "", "").strip()
        status = normalize_status(row.get(columns.get("status", "") or "", "active"))
        tags_raw = row.get(columns.get("tags", "") or "", "")
        tags = [t.strip() for t in re.split(r"[;,]", tags_raw) if t.strip()]
        updated_at_col = (columns.get("updatedAt") or "").strip()
        updated_at = row.get(updated_at_col, "").strip() if updated_at_col else ""

        translations: Dict[str, str] = {}
        for lang in languages:
            col_name = columns.get(lang) or lang
            translations[lang] = (row.get(col_name, "") or "").strip()

        record = LocalizationRecord(
            module=module,
            key=key,
            type=type_value,
            params=params,
            context=context,
            description=description,
            status=status,
            tags=tags,
            translations=translations,
            last_updated=updated_at,
            source=source,
        )
        records.append(record)
    return records


def load_legacy_arb(arb_dir: Path, languages: Sequence[str]) -> List[LocalizationRecord]:
    records: List[LocalizationRecord] = []
    if not arb_dir.exists():
        return records

    for path in arb_dir.rglob("*.arb"):
        # Skip merged app-level ARB files to avoid duplicating module keys
        if "/app/" in path.as_posix():
            continue
        module = path.stem.split("_")[0]
        locale = path.stem.split("_")[-1]
        if locale not in languages:
            continue
        with path.open(encoding="utf-8") as f:
            data = json.load(f)

        for key, value in data.items():
            if key.startswith("@") or key.startswith("@@"):
                continue
            description_key = f"@{key}"
            description = ""
            params = []
            if isinstance(data.get(description_key), dict):
                description = data.get(description_key, {}).get("description", "")
                placeholders = data.get(description_key, {}).get("placeholders", {})
                params = list(placeholders.keys())

            translations = {locale: value}
            record = LocalizationRecord(
                module=module,
                key=key,
                type="text",
                params=params,
                context="",
                description=description,
                status="active",
                tags=[],
                translations=translations,
                last_updated="",
                source="legacy-arb",
            )
            records.append(record)
    return records


def merge_records_by_identity(records: Iterable[LocalizationRecord], languages: Sequence[str]) -> List[LocalizationRecord]:
    merged: Dict[str, LocalizationRecord] = {}
    for record in records:
        identity = record.identity()
        if identity not in merged:
            merged[identity] = record
            continue

        existing = merged[identity]
        for lang in languages:
            value = record.translations.get(lang)
            if value:
                existing.translations[lang] = value
        if not existing.description and record.description:
            existing.description = record.description
        if not existing.params and record.params:
            existing.params = record.params
        existing.tags = sorted(set(existing.tags + record.tags))
        existing.source = ",".join(sorted(set(filter(None, [existing.source, record.source]))))
        if record.last_updated:
            existing.last_updated = record.last_updated
    return list(merged.values())


def normalize_translations(
    records: List[LocalizationRecord],
    languages: Sequence[str],
    default_language: Optional[str],
    fill_missing_from_default: bool = True,
) -> None:
    for record in records:
        default_value = record.translations.get(default_language or "", "")
        # If params are empty, try to infer from the default translation placeholders
        if not record.params:
            inferred = detect_placeholders(default_value)
            if inferred:
                record.params = inferred

        for lang in languages:
            value = record.translations.get(lang, "")
            if fill_missing_from_default and not value and default_language and default_value:
                record.translations[lang] = default_value
        for lang, value in list(record.translations.items()):
            # Fall back to inferring placeholders from each translation if params are still empty
            params_for_norm = record.params or detect_placeholders(value)
            record.translations[lang] = normalize_placeholders(value, params_for_norm)
            # If we still have no declared params, strip stray placeholders to avoid accidental function signatures
            if not record.params:
                record.translations[lang] = re.sub(
                    r"\$+\s*\{?\s*([a-zA-Z_][\w]*)\s*\}?", r"\1", record.translations[lang]
                )


def validate_records(records: List[LocalizationRecord], supported_languages: Sequence[str]) -> Tuple[List[str], List[str]]:
    warnings: List[str] = []
    errors: List[str] = []

    seen_identities = set()
    for record in records:
        identity = record.identity()
        if identity in seen_identities:
            warnings.append(f"Duplicate key {identity}")
        seen_identities.add(identity)

        if record.type not in ALLOWED_TYPES:
            warnings.append(f"{identity}: unsupported type '{record.type}', falling back to text")

        placeholders = detect_placeholders(record.translations.get(supported_languages[0], ""))
        missing_params = sorted(set(placeholders) - set(record.params))
        if missing_params:
            warnings.append(f"{identity}: placeholders in text not declared in Params: {', '.join(missing_params)}")
        missing_declared = sorted(set(record.params) - set(placeholders))
        if missing_declared:
            warnings.append(f"{identity}: declared params missing in text: {', '.join(missing_declared)}")

        missing_languages = record.missing_languages(supported_languages)
        if missing_languages:
            warnings.append(f"{identity}: missing translations for {', '.join(missing_languages)}")

        if record.status not in VALID_STATUSES:
            warnings.append(f"{identity}: invalid status '{record.status}', expected one of {', '.join(sorted(VALID_STATUSES))}")

    return warnings, errors


def write_intermediate(records: List[LocalizationRecord], temp_dir: Path) -> Path:
    ensure_dir(temp_dir)
    dataset_path = temp_dir / "records.json"
    serializable = [
        {
            "module": r.module,
            "key": r.key,
            "type": r.type,
            "params": r.params,
            "context": r.context,
            "description": r.description,
            "status": r.status,
            "tags": r.tags,
            "translations": r.translations,
            "last_updated": r.last_updated,
            "source": r.source,
        }
        for r in sorted(records, key=lambda rec: rec.identity())
    ]
    dataset_path.write_text(json.dumps(serializable, ensure_ascii=False, indent=2), encoding="utf-8")
    return dataset_path


def build_yaml_payload(records: List[LocalizationRecord], languages: Sequence[str]) -> Dict[str, Dict[str, Dict[str, str]]]:
    payload: Dict[str, Dict[str, Dict[str, str]]] = {}
    for record in sorted(records, key=lambda r: (r.module, r.key)):
        for lang in languages:
            translated_value = record.translations.get(lang)
            if not translated_value:
                continue
            locale_bucket = payload.setdefault(lang, {})
            module_bucket = locale_bucket.setdefault(record.module, {})
            module_bucket[record.key] = translated_value
    return payload


def write_yaml_files(payload: Dict[str, Dict[str, Dict[str, str]]], i18n_dir: Path, encoding: str) -> None:
    if i18n_dir.exists():
        for child in i18n_dir.iterdir():
            if child.is_dir():
                for file in child.glob("*.yaml"):
                    file.unlink()
    ensure_dir(i18n_dir)

    for locale, modules in payload.items():
        locale_dir = i18n_dir / locale
        ensure_dir(locale_dir)
        for module, content in modules.items():
            if not content:
                continue
            target = locale_dir / f"{module}.yaml"
            target.write_text(
                yaml.safe_dump(dict(content), allow_unicode=True, sort_keys=False, default_flow_style=False),
                encoding=encoding,
            )
            log_success(f"Generated {target}")


def fetch_sheet_csv(sheet_id: str, gid: str, encoding: str) -> str:
    url = f"https://docs.google.com/spreadsheets/d/{sheet_id}/export?format=csv&gid={gid}"
    resp = requests.get(url, timeout=30)
    resp.raise_for_status()
    resp.encoding = encoding
    return resp.text


def load_sheet_records(sheet_cfg: Dict, languages: Sequence[str], encoding: str, source_label: str, auth_cfg: Optional[Dict] = None) -> List[LocalizationRecord]:
    sheet_id = sheet_cfg["sheet_id"]
    tabs = sheet_cfg.get("tabs", [])
    gids = sheet_cfg.get("sheet_gids", [])
    columns = sheet_cfg.get("columns", {})

    if tabs:
        records: List[LocalizationRecord] = []
        for tab in tabs:
            gid = tab.get("gid")
            module_override = slugify(tab.get("module", "") or tab.get("title", ""))
            title = tab.get("title") or tab.get("module") or gid
            if not module_override:
                log_warning(f"Tab {title} has no module name; skipping.")
                continue

            try:
                if gid:
                    log_step(f"Fetching sheet gid={gid} ({title}) from {sheet_id}")
                    csv_text = fetch_sheet_csv(sheet_id, str(gid), encoding=encoding)
                    rows = read_csv_text(csv_text)
                else:
                    if gspread is None or Credentials is None:
                        log_warning(f"Skipping tab '{title}' (no gid and gspread unavailable).")
                        continue
                    creds = get_credentials(auth_cfg)
                    if creds is None:
                        log_warning(f"Skipping tab '{title}' (no gid and credentials missing).")
                        continue
                    log_step(f"Fetching sheet '{title}' via gspread from {sheet_id}")
                    client = gspread.authorize(creds)
                    worksheet = client.open_by_key(sheet_id).worksheet(title)
                    rows = worksheet.get_all_records()
                records.extend(parse_sheet_rows(rows, columns, languages, source_label, default_module=module_override))
            except Exception as exc:
                log_warning(f"Failed to fetch tab '{title}': {exc}")
                continue
        return records

    all_rows: List[Dict[str, str]] = []
    for gid in gids:
        log_step(f"Fetching sheet gid={gid} from {sheet_id}")
        csv_text = fetch_sheet_csv(sheet_id, str(gid), encoding=encoding)
        all_rows.extend(read_csv_text(csv_text))
    return parse_sheet_rows(all_rows, columns, languages, source_label)


def dataset_to_rows(records: List[LocalizationRecord], columns: Dict[str, str], languages: Sequence[str]) -> List[List[str]]:
    module_col = (columns.get("module") or "").strip()
    updated_at_col = (columns.get("updatedAt") or "").strip()
    header: List[str] = []
    if module_col:
        header.append(module_col)
    header.extend(
        [
            columns.get("key", "Key"),
            columns.get("type", "Type"),
            columns.get("context", "Context"),
            columns.get("params", "Params"),
            columns.get("description", "Description"),
            columns.get("status", "Status"),
            columns.get("tags", "Tags"),
        ]
    )
    if updated_at_col:
        header.append(updated_at_col)
    header.extend([columns.get(lang, lang).strip() or lang for lang in languages])

    rows: List[List[str]] = [header]
    for record in sorted(records, key=lambda r: (r.module, r.key)):
        row: List[str] = []
        if module_col:
            row.append(record.module)
        row.extend(
            [
                record.key,
                record.type,
                record.context,
                ", ".join(record.params),
                record.description,
                record.status,
                ", ".join(record.tags),
            ]
        )
        if updated_at_col:
            row.append(record.last_updated)
        for lang in languages:
            row.append(record.translations.get(lang, ""))
        rows.append(row)
    return rows


def get_credentials(auth_cfg: Optional[Dict] = None) -> Optional[Credentials]:
    json_path = (
        os.environ.get("LOCALIZATION_SA_PATH")
        or (auth_cfg or {}).get("service_account_path")
        or os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    )
    raw_json = os.environ.get("LOCALIZATION_SA_JSON") or (auth_cfg or {}).get("service_account_json")

    if json_path and Path(json_path).expanduser().exists():
        return Credentials.from_service_account_file(str(Path(json_path).expanduser()), scopes=DEFAULT_SCOPES)
    if raw_json:
        return Credentials.from_service_account_info(json.loads(raw_json), scopes=DEFAULT_SCOPES)
    return None


def resolve_worksheet(spreadsheet, tab_cfg: Dict, columns: Dict[str, str], languages: Sequence[str], apply: bool):
    gid = tab_cfg.get("gid")
    title = tab_cfg.get("title") or tab_cfg.get("module") or str(gid or "")

    worksheet = None
    if gid is not None:
        try:
            worksheet = spreadsheet.get_worksheet_by_id(int(gid))
        except Exception:
            worksheet = None

    if worksheet is None and title:
        try:
            worksheet = spreadsheet.worksheet(title)
        except Exception:
            worksheet = None

    if worksheet is None and apply and title:
        cols = len(columns) + len(languages)
        worksheet = spreadsheet.add_worksheet(title=title, rows=500, cols=cols)
        log_success(f"Created worksheet '{title}' (cols={cols})")

    return worksheet


def push_to_sheet(records: List[LocalizationRecord], sheet_cfg: Dict, languages: Sequence[str], apply: bool, auth_cfg: Optional[Dict] = None) -> None:
    if gspread is None or Credentials is None:
        log_error("gspread/google-auth not available. Install requirements via requirements.txt")
        sys.exit(1)

    creds = get_credentials(auth_cfg)
    if creds is None:
        log_error("Service account credentials not found. Set LOCALIZATION_SA_PATH/LOCALIZATION_SA_JSON or configure googleSheets.auth.serviceAccountPath.")
        sys.exit(1)

    sheet_id = sheet_cfg["sheet_id"]
    columns = sheet_cfg.get("columns", {})
    tabs = sheet_cfg.get("tabs", [])

    client = gspread.authorize(creds)
    spreadsheet = client.open_by_key(sheet_id)

    if not tabs:
        gid = int(sheet_cfg.get("sheet_gids", [0])[0])
        worksheet = spreadsheet.get_worksheet_by_id(gid)
        if worksheet is None:
            log_error(f"Worksheet gid={gid} not found in sheet {sheet_id}")
            sys.exit(1)

        rows = dataset_to_rows(records, columns, languages)
        if not apply:
            log_info("Dry-run push: no data written. Preview:")
            log_info(f"Rows to write (including header): {len(rows)}")
            log_info(f"First payload row: {rows[1] if len(rows) > 1 else 'n/a'}")
            return

        worksheet.clear()
        worksheet.update(rows, value_input_option="USER_ENTERED")
        log_success(f"Pushed {len(rows) - 1} rows to sheet gid={gid}")
        return

    tab_map = {slugify(tab.get("module", "") or tab.get("title", "")): tab for tab in tabs if tab.get("module") or tab.get("title")}

    for module in sorted(set(r.module for r in records)):
        module_records = [r for r in records if r.module == module]
        tab_cfg = tab_map.get(module, {"module": module, "title": module})
        title = tab_cfg.get("title") or tab_cfg.get("module") or module
        rows = dataset_to_rows(module_records, columns, languages)
        worksheet = resolve_worksheet(spreadsheet, tab_cfg, columns, languages, apply)

        if worksheet is None:
            if not apply:
                log_info(f"Dry-run: tab '{title}' missing; would create and push {len(rows) - 1} rows.")
                continue
            log_error(f"Worksheet for module '{module}' not found and could not be created (title={title}).")
            sys.exit(1)

        if not apply:
            log_info(f"Dry-run push for module '{module}' -> tab '{title}': {len(rows) - 1} rows.")
            continue

        worksheet.clear()
        worksheet.update(rows, value_input_option="USER_ENTERED")
        log_success(f"Pushed {len(rows) - 1} rows to tab '{worksheet.title}' (id={worksheet.id})")


def diff_datasets(new_records: List[LocalizationRecord], existing_records: List[LocalizationRecord], languages: Sequence[str]) -> Tuple[List[str], List[str], List[str]]:
    new_map = {r.identity(): r for r in new_records}
    existing_map = {r.identity(): r for r in existing_records}

    added = sorted(set(new_map.keys()) - set(existing_map.keys()))
    removed = sorted(set(existing_map.keys()) - set(new_map.keys()))
    changed: List[str] = []

    for identity, new_record in new_map.items():
        if identity not in existing_map:
            continue
        old_record = existing_map[identity]
        for lang in languages:
            if (new_record.translations.get(lang) or "").strip() != (old_record.translations.get(lang) or "").strip():
                changed.append(identity)
                break

    return added, removed, sorted(set(changed))


def handle_pull(cfg: Dict) -> None:
    languages = cfg["languages"]["supported"]
    default_language = cfg["languages"]["default"]
    auth_cfg = cfg.get("auth", {})
    temp_dir = Path(cfg["paths"]["temp_dir"])
    i18n_dir = Path(cfg["paths"]["i18n_dir"])
    encoding = cfg["generation"]["encoding"]

    records = load_sheet_records(cfg["active_sheet"], languages, encoding, "active-sheet", auth_cfg)
    normalize_translations(records, languages, default_language)
    warnings, errors = validate_records(records, languages)

    if errors:
        for err in errors:
            log_error(err)
        sys.exit(1)

    for warn in warnings:
        log_warning(warn)

    dataset_path = write_intermediate(records, temp_dir)
    payload = build_yaml_payload(records, languages)
    write_yaml_files(payload, i18n_dir, encoding)

    log_success(f"Wrote intermediate dataset to {dataset_path}")
    log_success("Pull complete")


def handle_migrate(cfg: Dict, source: str, apply: bool) -> None:
    languages = cfg["languages"]["supported"]
    default_language = cfg["languages"]["default"]
    auth_cfg = cfg.get("auth", {})
    temp_dir = Path(cfg["paths"]["temp_dir"])
    i18n_dir = Path(cfg["paths"]["i18n_dir"])
    encoding = cfg["generation"]["encoding"]

    records: List[LocalizationRecord] = []
    if source == "sheet":
        records.extend(load_sheet_records(cfg["legacy_sheet"], languages, encoding, "legacy-sheet", auth_cfg))
    else:
        records.extend(load_legacy_arb(Path(cfg["paths"]["legacy_arb_dir"]), languages))

    if not records:
        log_error("No legacy records found to migrate.")
        sys.exit(1)

    # Fill optional metadata defaults
    for record in records:
        if not record.type:
            record.type = "text"
        if not record.status:
            record.status = "active"
        record.tags = sorted(set(record.tags))

    records = merge_records_by_identity(records, languages)
    normalize_translations(records, languages, default_language)
    warnings, errors = validate_records(records, languages)
    for warn in warnings:
        log_warning(warn)
    if errors:
        for err in errors:
            log_error(err)
        sys.exit(1)

    dataset_path = write_intermediate(records, temp_dir)
    payload = build_yaml_payload(records, languages)
    write_yaml_files(payload, i18n_dir, encoding)

    log_success(f"Migrated dataset written to {dataset_path}")

    # Optionally push migrated dataset into active sheet
    if apply:
        log_step("Pushing migrated dataset into active sheet...")
        push_to_sheet(records, cfg["active_sheet"], languages, apply=True, auth_cfg=auth_cfg)
    else:
        log_info("Migration completed in dry-run mode (no push).")


def handle_push(cfg: Dict, apply: bool) -> None:
    languages = cfg["languages"]["supported"]
    default_language = cfg["languages"]["default"]
    auth_cfg = cfg.get("auth", {})
    encoding = cfg["generation"]["encoding"]
    temp_dir = Path(cfg["paths"]["temp_dir"])

    dataset_path = temp_dir / "records.json"
    if not dataset_path.exists():
        log_error(f"records.json not found at {dataset_path}. Run pull or migrate first.")
        sys.exit(1)

    records_raw = json.loads(dataset_path.read_text(encoding=encoding))
    records = [
        LocalizationRecord(
            module=item["module"],
            key=item["key"],
            type=item.get("type", "text"),
            params=item.get("params", []),
            context=item.get("context", ""),
            description=item.get("description", ""),
            status=item.get("status", "active"),
            tags=item.get("tags", []),
            translations=item.get("translations", {}),
            last_updated=item.get("last_updated", ""),
            source=item.get("source", "local"),
        )
        for item in records_raw
    ]

    normalize_translations(records, languages, default_language)
    warnings, errors = validate_records(records, languages)
    for warn in warnings:
        log_warning(warn)
    if errors:
        for err in errors:
            log_error(err)
        sys.exit(1)

    try:
        existing_records = load_sheet_records(cfg["active_sheet"], languages, encoding, "active-sheet", auth_cfg)
    except Exception as exc:  # pragma: no cover - depends on network
        log_warning(f"Could not load remote sheet for diff: {exc}")
        existing_records = []

    added, removed, changed = diff_datasets(records, existing_records, languages)
    log_step("Diff against remote:")
    log_info(f"Added: {len(added)} | Removed: {len(removed)} | Changed: {len(changed)}")
    if added:
        log_info(f"Added keys (sample): {', '.join(added[:5])}" + (" ..." if len(added) > 5 else ""))
    if changed:
        log_info(f"Changed keys (sample): {', '.join(changed[:5])}" + (" ..." if len(changed) > 5 else ""))

    if apply:
        now_iso = datetime.now(timezone.utc).isoformat()
        touched = set(added + changed)
        for record in records:
            if record.identity() in touched or not record.last_updated:
                record.last_updated = now_iso

    push_to_sheet(records, cfg["active_sheet"], languages, apply=apply, auth_cfg=auth_cfg)


def handle_validate(cfg: Dict) -> None:
    languages = cfg["languages"]["supported"]
    default_language = cfg["languages"]["default"]
    encoding = cfg["generation"]["encoding"]
    temp_dir = Path(cfg["paths"]["temp_dir"])

    dataset_path = temp_dir / "records.json"
    if not dataset_path.exists():
        log_error("records.json not found. Run pull or migrate first.")
        sys.exit(1)

    records_raw = json.loads(dataset_path.read_text(encoding=encoding))
    records = [
        LocalizationRecord(
            module=item["module"],
            key=item["key"],
            type=item.get("type", "text"),
            params=item.get("params", []),
            context=item.get("context", ""),
            description=item.get("description", ""),
            status=item.get("status", "active"),
            tags=item.get("tags", []),
            translations=item.get("translations", {}),
            last_updated=item.get("last_updated", ""),
            source=item.get("source", "local"),
        )
        for item in records_raw
    ]
    normalize_translations(records, languages, default_language)
    warnings, errors = validate_records(records, languages)
    for warn in warnings:
        log_warning(warn)
    if errors:
        for err in errors:
            log_error(err)
        sys.exit(1)
    log_success("Validation passed")


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Localization CLI (sheets <-> slang yaml)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=textwrap.dedent(
            """
            Commands:
              pull                  Fetch active sheet -> YAML + records.json
              migrate               Import from legacy sheet/ARB -> YAML (+ optional push)
              push                  Push records.json to active sheet (dry-run by default)
              validate              Validate records.json for placeholder/supported locale issues
            """
        ),
    )
    parser.add_argument("--config", required=True, help="Path to generated localization config (JSON)")
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("pull", help="Pull active sheet into YAML + records.json")

    migrate_parser = subparsers.add_parser("migrate", help="Migrate legacy sheet/ARB into new schema")
    migrate_parser.add_argument(
        "--source", choices=["sheet", "arb"], default="sheet", help="Use legacy sheet (default) or local ARB assets"
    )
    migrate_parser.add_argument("--apply", action="store_true", help="Push migrated data to active sheet")

    push_parser = subparsers.add_parser("push", help="Push local records.json to active sheet")
    push_parser.add_argument("--apply", action="store_true", help="Apply changes (default is dry-run)")

    subparsers.add_parser("validate", help="Validate local records.json")
    return parser


def main() -> None:
    args = build_arg_parser().parse_args()
    cfg = load_config(args.config)

    command = args.command
    if command == "pull":
        handle_pull(cfg)
    elif command == "migrate":
        handle_migrate(cfg, source=args.source, apply=args.apply)
    elif command == "push":
        handle_push(cfg, apply=args.apply)
    elif command == "validate":
        handle_validate(cfg)
    else:
        log_error(f"Unknown command {command}")
        sys.exit(1)


if __name__ == "__main__":
    main()
