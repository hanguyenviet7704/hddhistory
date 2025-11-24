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
2) Pull latest sheet data:
   - `LOCALIZATION_SA_PATH=.info/key/multilang_key.json tools/<os>/localization/localization.sh pull`
     (`tools/linux/...`, `tools/macos/...`, or `tools/windows/.../localization.bat` depending on OS).
3) Detect raw strings not already localized:
   - `rg --glob '*.dart' --no-heading --color never -n "\"[^\"]{2,}\"" {path} | rg -v "context\\.text|AppLocale|\\.tr\\(|l10n|Slang"`
   - Deduplicate; skip tests unless user asked.
4) Propose keys:
   - Naming update (no module prefix): use concise lowerCamelCase that describes the text itself, e.g., `welcomeTitle`, `skipButton`, `emailPlaceholder`. Do **not** prepend the module name (`onboardingWelcomeTitle` -> `welcomeTitle`).
   - If you touch a module that still has prefixed keys, migrate them while you are there: rename in all locale YAML files and update Dart references in the scanned `path` to remove the module prefix.
   - Default text: English string found.
   - Other locales: **translate vi/zh now**; only fall back to English if truly unsure, never leave blanks. Keep placeholders `${param}`, avoid double `$`.
5) Write entries into `assets/i18n/en/<module>.yaml` **and** `assets/i18n/{vi,zh}/<module>.yaml`, then mirror the same values into `build/localization/records.json` (push reads from this file). Keep placeholders `${param}`, avoid double `$`.
6) Push updates:
   - `tools/<os>/localization/localization.sh push --apply`
7) Regenerate + verify:
   - `tools/<os>/localization/localization.sh pull` (or when `clean=true` to force sync)
   - `tools/<os>/localization/localization.sh slang` (respects flutter/fvm/puro)
   - Re-scan `path`; optionally `flutter analyze`.

## Reporting
- List new keys added with file references.
- Call out any legacy prefixed keys you migrated and where references were updated.
- Note commands run and any warnings.
- Call out remaining raw strings, placeholder issues, or sheet auth problems.
