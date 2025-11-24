Description: Find raw strings in a Dart file/folder, add them to the localization sheets, and regenerate slang outputs.

# /sync-localization

## What This Does
- Scans the target Dart file/folder for raw user-facing strings that are not yet localized.
- Maps them to the correct sheet tab (module) and default language text.
- Pushes updates to the active Google Sheet via `localization.sh`/`.bat`.
- Regenerates slang outputs so the app can build without manual edits to generated files.

## Required Input
- `path`: Dart file or folder to scan.
- Optional: `module` (sheet tab). If omitted, derive from feature folder name; fallback `common`.

## Flow
1. **Ask upfront**
   - Confirm `path`.
   - Confirm `module` tab (common, auth, home, exercise, allcourse, courseroadmap, keypoint, lesson, onboarding, roleplay, setting).
   - Ask permission to auto-create keys (default yes).

2. **Sync latest data**
   - `LOCALIZATION_SA_PATH=.info/key/multilang_key.json tools/<os>/localization/localization.sh pull`
     (linux/macos paths; windows uses `tools/windows/localization/localization.bat`).

3. **Detect raw strings**
   - `rg --glob '*.dart' --no-heading --color never -n "\"[^\"]{2,}\"" {path} | rg -v "context\\.text|AppLocale|\\.tr\\(|l10n|Slang"`
   - Deduplicate results; ignore tests unless asked.

4. **Propose keys**
   - Key style (no module prefix): concise lowerCamelCase that describes the string itself, e.g., `welcomeTitle`, `skipButton`, `emailPlaceholder`. Do **not** prepend the module name.
   - If the target YAML still uses prefixed keys, migrate them while you are there: rename keys in all locale YAML files and update Dart references in the scanned `path` to drop the module prefix.
   - Default text: English source string.
   - Other locales: okay to leave empty; tool will prefix `(VI)` / `(ZH)` with default text on push.

5. **Write + push**
   - Add entries to `assets/i18n/en/<module>.yaml` (mirror files for other locales if needed).
   - Keep placeholders as `${param}`; remove stray extra `$`.
   - Run `tools/<os>/localization/localization.sh push --apply`.
   - If you created/renamed tabs, run `tools/<os>/localization/localization.sh cache-gids --ensure-readme` to refresh the gid cache and ensure the README tab exists.

6. **Regenerate + verify**
   - `tools/<os>/localization/localization.sh pull`
   - `tools/<os>/localization/localization.sh slang` (respects flutter/fvm/puro)
   - Re-scan to confirm no raw strings remain; run `flutter analyze` if time permits.

## Notes
- First sheet tab is `README` (instructions only); module tabs hold data. GID cache is stored in `.info/app/localization.json` and refreshed by the tools.

## Output
- Summary of new keys added (with file refs).
- Note any legacy prefixed keys migrated and where references were updated.
- Commands executed and their results.
- Any remaining raw strings or warnings to resolve.
