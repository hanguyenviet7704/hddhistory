# Localization Tooling (Updated)

Localization now uses `slang` + Google Sheets with module namespaces. The legacy `flutter gen-l10n` + merged ARB flow is deprecated (l10n.yaml has been removed).

## Commands (per platform wrappers)
```bash
# Pull active sheet -> YAML + build/localization/records.json
tools/linux/localization/localization.sh pull
tools/macos/localization/localization.sh pull
tools/windows/localization/localization.bat pull

# Migrate legacy sheet/ARB -> new schema (dry-run by default)
tools/<platform>/localization/localization.(sh|bat) migrate --source sheet   # legacy sheet id/gid from .info/app/localization.json
tools/<platform>/localization/localization.(sh|bat) migrate --source arb
tools/<platform>/localization/localization.(sh|bat) migrate --source sheet --apply  # push to active sheet

# Push local records.json back to the active sheet (requires service account). Modules are written to per-module tabs (auto-created if missing).
tools/<platform>/localization/localization.(sh|bat) push --apply

# Validate placeholders/missing translations
tools/<platform>/localization/localization.(sh|bat) validate
```

Service account for push: set `LOCALIZATION_SA_PATH` (file path) or `LOCALIZATION_SA_JSON` (raw JSON). Falls back to defaults in `.info/app/localization.json` and then `GOOGLE_APPLICATION_CREDENTIALS`.

## Data Layout
- Sheet schema: `Key`, `Type`, `Context`, `Params`, `Description`, `Status`, `Tags`, `UpdatedAt`, `EN/VI/ZH` (module is inferred from the tab name). ICU is allowed; placeholders use `${name}`. One tab per module; `common` and `auth` are shared tabs. `UpdatedAt` is optional and will be auto-populated for added/changed rows on push.
- Files: `assets/i18n/<locale>/<module>.yaml`
- Generated code: `lib/config/l10n/l10n*.dart` (`output_file_name: l10n.g.dart`)
- Config: `.info/app/localization.json` (sheet ids/tabs, paths, default SA path/env), `slang.yaml`
- Template: `.info/templates/sample_localization.csv`

## Using Translations
- App is wrapped with `TranslationProvider` (see `lib/main.dart`).
- Access strings via `context.text.<module>.<key>` (e.g., `context.text.common.cancel`, `context.text.home.homeCourseButton`).
- Regenerate after changes: `flutter pub run slang`.

## Migration Notes
- Legacy sheet: see `.info/app/localization.json` (`googleSheets.legacy.sheetId/gids`).
- New sheet: see `.info/app/localization.json` (`googleSheets.active.sheetId/tabs`).
- `migrate --source arb` imports existing ARB modules and skips merged `assets/arb/app` to avoid duplicate keys.
- Missing translations are reported in the CLI; zh currently falls back to en where empty.

For full details, see `docs/localization.md`.
