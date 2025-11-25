---
description: Scan a Dart file/folder for raw strings, add them to the localization sheet via CLI, and regenerate slang outputs.
argument-hint: path=<file-or-folder> [module=<sheet-tab>] [clean=false]
---
You are Codex in the Meup Flutter repo. Given a `path`, remove raw strings by pushing them into the sheet-driven localization flow, then regenerate slang.

## Inputs
- `path` (required): Dart file or folder to scan.
- `module` (optional): Sheet tab (common/auth/home/...); derive from feature folder name when omitted, fallback `common`.
- `clean` (optional): If true, re-run pull after push even if unchanged (default false).

## Workflow
1) Confirm `path` exists and pick `module` (ask once if ambiguous).
2) Pull latest sheet data (scope to the module when possible to avoid rewriting other YAML files):
   - `LOCALIZATION_SA_PATH=.info/key/multilang_key.json tools/<os>/localization/localization.sh pull --sheet-gids "<gid>"`
     - Look up the module gid in `.info/app/localization.json` (active.tabs[].gid). If unsure, omit `--sheet-gids` for a full pull.
     - Linux/macOS use `tools/<os>/localization/localization.sh`; Windows uses `tools/windows/localization/localization.bat`.
3) Detect raw strings not already localized:
   - `rg --glob '*.dart' --no-heading --color never -n "\"[^\"]{2,}\"" {path} | rg -v "context\\.text|AppLocale|\\.tr\\(|l10n|Slang"`
   - Deduplicate; skip tests unless user asked.
4) Propose keys:
   - Naming update (no module prefix): use concise lowerCamelCase that describes the text itself, e.g., `welcomeTitle`, `skipButton`, `emailPlaceholder`. Do **not** prepend the module name (`onboardingWelcomeTitle` -> `welcomeTitle`).
   - If you touch a module that still has prefixed keys, migrate them while you are there: rename in all locale YAML files and update Dart references in the scanned `path` to remove the module prefix.
   - Default text: English string found.
   - Other locales: you may leave blank; tools will fill `(VI)/(ZH) <default text>` on push when missing. Keep placeholders `${param}`, avoid double `$`.
5) Write entries into `assets/i18n/en/<module>.yaml` and mirror to other locale files. Keep placeholders `${param}`, avoid double `$`. For plurals/select, use YAML maps (include `zero`/`=0` when needed):
   ```yaml
   itemCount(param=count):
     zero: No items
     one: ${count} item
     other: ${count} items
   ```
6) Push updates (push reads YAML and refreshes `build/localization/records.json`):
   - `tools/<os>/localization/localization.sh push --apply [--sheet-gids "<gid>"]`
   - If you created/renamed tabs, run `tools/<os>/localization/localization.sh cache-gids --ensure-readme` to refresh the gid cache and ensure the README tab exists.
7) Regenerate + verify:
   - `tools/<os>/localization/localization.sh pull [--sheet-gids "<gid>"]` (or when `clean=true` to force sync)
   - `tools/<os>/localization/localization.sh slang` (respects flutter/fvm/puro)
   - Re-scan `path`; optionally `flutter analyze`.

## Notes
- First sheet tab is `README` (instructions only); module tabs hold data. GID cache is stored in `.info/app/localization.json` and refreshed by the tools.
- Partial pulls (`--sheet-gids`) merge into the dataset and only rewrite YAML for the targeted modules; full pulls clean/rebuild all locale YAMLs.
- Do **not** edit generated files (`lib/config/l10n/*.g.dart`); rely on slang.
- Service account path is defined in `.info/app/localization.json`; override via `LOCALIZATION_SA_PATH` if necessary.
- Mention renamed keys (from prefixed to unprefixed) in your summary.

## Reporting
- List new keys added with file references.
- Call out any legacy prefixed keys you migrated and where references were updated.
- Note commands run and any warnings.
- Call out remaining raw strings, placeholder issues, or sheet auth problems.
