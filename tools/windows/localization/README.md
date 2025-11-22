# Localization Tooling (Sheets ⇄ slang)

New pipeline uses the active Google Sheet (`.info/app/localization.json`) to produce module-based YAML files for `slang` and an intermediate dataset. Legacy ARB scripts remain for reference only.

## Commands

Sheet IDs/tabs are read from `.info/app/localization.json` (`googleSheets.active/legacy`); no IDs are hardcoded in the scripts.

```bash
# Pull active sheet -> YAML under assets/i18n + build/localization/records.json
tools/windows/localization/localization.bat pull

# Migrate legacy sheet/ARB -> new schema -> YAML (use --apply to push to active sheet)
tools/windows/localization/localization.bat migrate --source sheet
tools/windows/localization/localization.bat migrate --source arb --apply   # use local ARB as source

# Validate local dataset (records.json)
tools/windows/localization/localization.bat validate

# Push local dataset back to active sheet (dry-run by default)
tools/windows/localization/localization.bat push --apply
```

## Configuration
- `.info/app/localization.json` defines the active sheet, legacy sheet, column mappings, supported locales, module tabs, paths, encoding, and the default service account path/env names.
- Service account credentials (for push) via `LOCALIZATION_SA_PATH` (file path) or `LOCALIZATION_SA_JSON` (raw JSON). Falls back to the path in `.info/app/localization.json` and then `GOOGLE_APPLICATION_CREDENTIALS`.
- Dependencies are installed automatically from `tools/windows/localization/requirements.txt` into `.venv_localization`.
- Template/example CSV lives in `.info/templates/sample_localization.csv` (shared across platforms).

## Outputs
- YAML per module/locale: `assets/i18n/<locale>/<module>.yaml` (fed to slang).
- Intermediate dataset: `build/localization/records.json` (used for push/diff/validation).

## Tips
- Ensure `.info/app/localization.json` points to the correct sheet IDs/GIDs before running.
- `--apply` writes to the sheet; without it, operations are dry-run. Per-module tabs are auto-created when pushing if missing.
- After pulling/migrating, regenerate `lib/config/l10n/l10n*.dart` via `dart run slang` or `dart run build_runner build --delete-conflicting-outputs` (slang_build_runner enabled; `output_file_name: l10n.g.dart`).
