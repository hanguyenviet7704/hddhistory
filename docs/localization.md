# Localization Workflow (slang + Google Sheets)

Modular localization now uses `slang` with namespace files and a secure Google Sheet. Legacy `flutter_localizations` + merged ARB files are deprecated and kept only for historical reference.

## Quick Links
- Active sheet (new schema): https://docs.google.com/spreadsheets/d/1h4IG705T9sdpKz-oXGbqMrlUfvsPDsuESpZqH0fN-aY/edit?id=0#gid=0
- Legacy sheet (for migration only): https://docs.google.com/spreadsheets/d/1WX5ZeUfasdp1wxO_4RVZLL2ND42habrDqmQhfDfkIcs/edit?gid=288536257#gid=288536257
- Template/example CSV: `tools/linux/localization/templates/sample_localization.csv`

## File Layout
- Per-locale folders with module namespaces: `assets/i18n/<locale>/<module>.yaml`
- Generated translations (checked in): `lib/config/l10n/generated/strings*.g.dart`
- CLI cache/intermediate: `build/localization/records.json`
- Config: `.info/app/localization.json`
- Slang config: `slang.yaml`

## Sheet Schema (columns)
- `Module`: slug/namespace (e.g., `home`, `auth`), normalized to snake_case.
- `Key`: translation key within the module (e.g., `homeGreetingTitle`).
- `Type`: `text | rich | plural | select | selectordinal | context` (validation only).
- `Context`: optional axis (gender/platform/experiment).
- `Params`: `name:String, count:int` (typed placeholders).
- `Description`: copy guidance for translators.
- `Status`: `active | deprecated | draft`.
- `Tags`: free-form, comma/semicolon delimited.
- `EN`, `VI`, `ZH`: ICU-capable translations (plural/select allowed). Placeholders should match `Params`; non-ICU placeholders use `${name}`.

## CLI (tools/linux/localization/localization.sh)
Runs inside `.venv_localization`, installs deps from `requirements.txt`, and uses `.info/app/localization.json`.

```bash
# Pull active sheet -> YAML + build/localization/records.json
tools/linux/localization/localization.sh pull

# Migrate legacy sheet or local ARB into new schema/YAML (dry-run by default)
tools/linux/localization/localization.sh migrate --source sheet   # uses legacy sheet id/gid
tools/linux/localization/localization.sh migrate --source arb    # uses assets/arb
tools/linux/localization/localization.sh migrate --source sheet --apply  # also push to active sheet

# Push local records.json back to the active sheet (requires service account)
tools/linux/localization/localization.sh push --apply

# Validate records.json for schema/placeholders/missing locales
tools/linux/localization/localization.sh validate
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
flutter pub run slang                            # regenerates strings.g.dart
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
- `flutter pub run slang` (or `dart run slang`) regenerates code from YAML.
- `flutter test test/unit/` at minimum for l10n changes; run `flutter analyze` on larger refactors.

## Security
- No secrets in the repo. Sheet access is restricted via service account credentials provided at runtime through env vars.
