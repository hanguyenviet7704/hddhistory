# Localization Tooling (Updated)

Localization now uses `slang` + Google Sheets with module namespaces. The legacy `flutter gen-l10n` + merged ARB flow is deprecated (see `l10n.yaml` for historical reference only).

## Commands
```bash
# Pull active sheet -> YAML + build/localization/records.json
tools/linux/localization/localization.sh pull

# Migrate legacy sheet/ARB -> new schema (dry-run by default)
tools/linux/localization/localization.sh migrate --source sheet   # legacy sheet id/gid from .info/app/localization.json
tools/linux/localization/localization.sh migrate --source arb
tools/linux/localization/localization.sh migrate --source sheet --apply  # push to active sheet

# Push local records.json back to the active sheet (requires service account). Modules are written to per-module tabs (auto-created if missing).
tools/linux/localization/localization.sh push --apply

# Validate placeholders/missing translations
tools/linux/localization/localization.sh validate
```

Service account for push: set `LOCALIZATION_SA_PATH` (file path) or `LOCALIZATION_SA_JSON` (raw JSON). Falls back to `GOOGLE_APPLICATION_CREDENTIALS`.

## Data Layout
- Sheet schema: `Module`, `Key`, `Type`, `Context`, `Params`, `Description`, `Status`, `Tags`, `EN/VI/ZH`. ICU is allowed; placeholders use `${name}`. One tab per module; `common` and `auth` are shared tabs.
- Files: `assets/i18n/<locale>/<module>.yaml`
- Generated code: `lib/config/l10n/generated/strings*.g.dart`
- Config: `.info/app/localization.json`, `slang.yaml`
- Template: `.info/templates/sample_localization.csv`

## Using Translations
- App is wrapped with `TranslationProvider` (see `lib/main.dart`).
- Access strings via `context.text.<module>.<key>` (e.g., `context.text.common.cancel`, `context.text.home.homeCourseButton`).
- Regenerate after changes: `flutter pub run slang`.

## Migration Notes
- Legacy sheet: https://docs.google.com/spreadsheets/d/1WX5ZeUfasdp1wxO_4RVZLL2ND42habrDqmQhfDfkIcs/edit?gid=288536257#gid=288536257
- New sheet: https://docs.google.com/spreadsheets/d/1h4IG705T9sdpKz-oXGbqMrlUfvsPDsuESpZqH0fN-aY/edit?id=0#gid=0
- `migrate --source arb` imports existing ARB modules and skips merged `assets/arb/app` to avoid duplicate keys.
- Missing translations are reported in the CLI; zh currently falls back to en where empty.

For full details, see `docs/localization.md`.
