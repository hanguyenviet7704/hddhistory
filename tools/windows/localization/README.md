# Localization Tooling (Sheets ⇄ slang)

New pipeline uses the active Google Sheet (`.info/app/localization.json`) to produce module-based YAML files for `slang` and an intermediate dataset. Legacy ARB scripts remain for reference only.

## Commands (wrapper auto-detects flutter/fvm/puro)

Sheet IDs/tabs come from `.info/app/localization.json`; nothing is hardcoded.

```bat
:: Pull active sheet -> YAML + build/localization/records.json
tools\windows\localization\localization.bat pull

:: Migrate legacy sheet/ARB -> new schema (add --apply to push)
tools\windows\localization\localization.bat migrate --source sheet
tools\windows\localization\localization.bat migrate --source arb --apply

:: Push local records.json back to active sheet (dry-run unless --apply)
tools\windows\localization\localization.bat push --apply

:: Validate local dataset
tools\windows\localization\localization.bat validate

:: Refresh cached tab gids and ensure README tab exists
tools\windows\localization\localization.bat cache-gids --ensure-readme

:: Regenerate slang outputs
tools\windows\localization\localization.bat slang
```

## Configuration
- `.info/app/localization.json` holds active/legacy sheet IDs, tab list, cached `sheetGids`, column labels, paths, locales, encoding, and service-account env names. Tools update the gid cache automatically after `push/migrate --apply` or via `cache-gids`.
- Sheet structure: first tab is `README` (instructions only). Each module gets its own tab named after the module; columns: `Key`, `Type`, `Context`, `Params`, `Description`, `Status`, `Tags`, `UpdatedAt`, `English (EN)`, `Vietnamese (VI)`, `Chinese (ZH)`. Module name is the namespace—do **not** prefix keys with the module.
- Missing translation rule: when a locale cell is empty, push fills it with `(LANGCODE) <default text>` so gaps are obvious.
- Service account for push: `LOCALIZATION_SA_PATH` (file) or `LOCALIZATION_SA_JSON` (raw). Defaults come from `.info/app/localization.json`; `GOOGLE_APPLICATION_CREDENTIALS` is a fallback.
- Dependencies install into `.venv_localization` from `requirements.txt`. Template CSV: `.info/templates/sample_localization.csv`.

## Outputs
- YAML per module/locale: `assets/i18n/<locale>/<module>.yaml` (consumed by slang).
- Intermediate dataset: `build/localization/records.json` (source for push/diff/validate). `UpdatedAt` is auto-stamped on changed/added rows when applying.

## Recommended workflow (per task)
1) `localization.bat pull`
2) Edit/add keys (lowerCamelCase, no module prefix) in YAML or sheet; keep `${param}` placeholders tidy.
3) `localization.bat push --apply`
4) If you added/renamed tabs: `localization.bat cache-gids --ensure-readme`
5) `localization.bat pull`
6) `localization.bat slang`
