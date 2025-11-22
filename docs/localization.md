# Localization Workflow (slang + Google Sheets)

Modular localization now uses `slang` with namespace files and a secure Google Sheet. Legacy `flutter_localizations` + merged ARB files are deprecated and kept only for historical reference.

## Quick Links
- Active sheet (new schema): see `.info/app/localization.json` (`googleSheets.active.sheetId`, per-tab gids/tabs there).
- Legacy sheet (for migration only): see `.info/app/localization.json` (`googleSheets.legacy.sheetId/gids`).
- Template/example CSV: `.info/templates/sample_localization.csv`

## File Layout
- Per-locale folders with module namespaces: `assets/i18n/<locale>/<module>.yaml`
- Generated translations (checked in): `lib/config/l10n/l10n*.dart` (`output_file_name` set to `l10n.g.dart` per slang recommendations: https://pub.dev/packages/slang#configuration)
- CLI cache/intermediate: `build/localization/records.json`
- Config: `.info/app/localization.json` (sheet ids/GIDs, module tabs, paths, default service account path/env)
- Slang config: `slang.yaml`

## Sheet Schema (columns)
- Tab name = module/namespace (e.g., `home`, `auth`). `common` and `auth` are shared tabs usable by other apps.
- `Key`: translation key within the module (e.g., `homeGreetingTitle`).
- `Type`: `text | rich | plural | select | selectordinal | context` (validation only).
- `Context`: optional axis (gender/platform/experiment).
- `Params`: `name:String, count:int` (typed placeholders).
- `Description`: copy guidance for translators.
- `Status`: `active | deprecated | draft`.
- `Tags`: free-form, comma/semicolon delimited.
- `UpdatedAt`: optional ISO8601 timestamp for last change (auto-filled on push for new/changed rows).
- Language columns: `English (EN)`, `Vietnamese (VI)`, `Chinese (ZH)` (names are configurable via `.info/app/localization.json`). ICU is allowed; placeholders should match `Params`; non-ICU placeholders use `${name}`. Missing translations are auto-filled from the default language with a prefix of the missing locale code (e.g., `(ZH) <default>`).

## CLI (Linux/macOS/Windows)
Wrappers live under `tools/<platform>/localization/`, run inside `.venv_localization`, install deps from `requirements.txt`, and use `.info/app/localization.json`.

- Linux/macOS: `tools/linux/localization/localization.sh ...` or `tools/macos/localization/localization.sh ...`
- Windows: `tools/windows/localization/localization.bat ...`

Common commands:
```bash
# Pull active sheet -> YAML + build/localization/records.json
tools/linux/localization/localization.sh pull
tools/macos/localization/localization.sh pull
tools/windows/localization/localization.bat pull

# Migrate legacy sheet or local ARB into new schema/YAML (dry-run by default)
tools/<platform>/localization/localization.(sh|bat) migrate --source sheet   # uses legacy sheet id/gid
tools/<platform>/localization/localization.(sh|bat) migrate --source arb    # uses assets/arb
tools/<platform>/localization/localization.(sh|bat) migrate --source sheet --apply  # also push to active sheet

# Push local records.json back to the active sheet (requires service account). Modules are written to individual tabs (auto-created if missing).
tools/<platform>/localization/localization.(sh|bat) push --apply

# Validate records.json for schema/placeholders/missing locales
tools/<platform>/localization/localization.(sh|bat) validate
```

Service account credentials (push only):
- `LOCALIZATION_SA_PATH=/abs/path/to/sa.json` **or** `LOCALIZATION_SA_JSON=<raw json>`.
- Falls back to `GOOGLE_APPLICATION_CREDENTIALS` if set.

## Developer Workflow
1) Pull or migrate data  
2) Edit/add translations in the sheet (or update `records.json`), keeping keys stable  
3) Regenerate YAML + code:  
```bash
tools/linux/localization/localization.sh pull    # or migrate
flutter pub run slang                            # regenerates lib/config/l10n/l10n*.dart
```
4) Use translations in code: wrap app with `TranslationProvider` (see `lib/main.dart`) and access via `context.text.<module>.<key>()`.
5) Validate/tests: `tools/linux/localization/localization.sh validate`, `flutter test test/unit/` (or full suite).

## Content Workflow
- Edit only value columns and `Description/Status/Tags`; never rename existing keys.
- Keep placeholders ${name} consistent across locales; plural/select must include all branches.
- Use `Status=deprecated` instead of deleting keys; devs can prune later.

## Migration Notes
- Legacy ARB import skips merged `assets/arb/app` files to avoid duplicate keys.
- Missing translations report is printed during migration/pull; zh gaps currently exist and will fall back to `en`.
- Push (`--apply`) writes the normalized dataset back to the active sheet with a dry-run diff by default.

## Testing & Validation
- `flutter pub run slang` (or `dart run slang`) regenerates code from YAML (output in `lib/config/l10n/l10n*.dart`).
- `flutter test test/unit/` at minimum for l10n changes; run `flutter analyze` on larger refactors.

## Security
- No secrets in the repo. Sheet access is restricted via service account credentials provided at runtime through env vars.
