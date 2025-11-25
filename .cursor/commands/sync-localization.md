# Sync Localization

## Overview
Given a Dart file or folder, find raw user-facing strings, convert them into the new sheets-first localization flow, and regenerate slang outputs. Works across Linux/macOS/Windows tooling.

## Inputs
- **path** (required): Dart file or folder to scan.
- **module/tab** (optional): Sheet tab to write to (defaults to feature folder name, then `common`).

## Flow
1) **Clarify**
   - Confirm `path` and target `module` tab (common/auth/home/...).
   - Ask whether to auto-create keys (default yes).

2) **Sync latest source**
   - Run `LOCALIZATION_SA_PATH=.info/key/multilang_key.json tools/<os>/localization/localization.sh pull --sheet-gids "<gid>"`  
     - Use the module gid from `.info/app/localization.json` (active.tabs[].gid). Omit `--sheet-gids` for a full pull.
     - `tools/linux/...` on Linux, `tools/macos/...` on macOS, `tools/windows/.../localization.bat` on Windows.

3) **Detect raw strings**
   - Use ripgrep to find literal strings not already localized:  
     `rg --glob '*.dart' --no-heading --color never -n "\"[^\"]{2,}\"" {path} | rg -v "context\\.text|AppLocale|.tr\\(|Slang|S\\.|l10n"`
   - Collect candidates and deduplicate.

4) **Propose keys & values**
   - Key style (no module prefix): concise lowerCamelCase describing the text, e.g., `welcomeTitle`, `skipButton`, `emailPlaceholder`. Do **not** prepend the module name (module == tab name already).
   - If the target YAML still has prefixed keys, migrate them while working: rename keys across locale YAML files and update Dart references in the scanned `path` to remove the module prefix.
   - Default text: the English source string.
   - Other locales: leave empty — the tool will prefix `(VI)` / `(ZH)` with default text on push.

5) **Write records**
   - Add entries to `assets/i18n/en/<module>.yaml` (and leave mirrors for other langs if needed).
   - Keep placeholder syntax `${param}`; avoid double `$`. For plurals/select, keep YAML maps; add `zero` or explicit `=0` cases when needed, e.g.:
     ```yaml
     itemCount(param=count):
       zero: No items
       one: ${count} item
       other: ${count} items
     ```

6) **Push to sheet + regenerate**
   - `tools/<os>/localization/localization.sh push --apply [--sheet-gids "<gid>"]` (push reads YAML and refreshes `records.json`)
   - `tools/<os>/localization/localization.sh cache-gids --ensure-readme` (only if you created/renamed tabs)
   - `tools/<os>/localization/localization.sh pull [--sheet-gids "<gid>"]` (ensures YAML matches sheet; partial pulls keep other modules intact)
   - `tools/<os>/localization/localization.sh slang` (uses flutter/fvm/puro automatically)

7) **Verify**
   - Re-scan `path` to ensure no raw strings remain.
   - Optionally run `flutter analyze`.

## Notes
- Do **not** edit generated files (`lib/config/l10n/*.g.dart`); rely on slang.
- Service account path comes from `.info/app/localization.json`; override with `LOCALIZATION_SA_PATH` if needed.
- When you migrate legacy prefixed keys, mention which keys changed and where references were updated in your summary.
- The first sheet tab is `README` (instructions only); real data tabs are per module. GID cache lives in `.info/app/localization.json` and is refreshed by the tools.
- Partial pulls (`--sheet-gids`) merge into the dataset and only rewrite YAML for targeted modules; full pulls clean/rebuild all locale YAMLs.
