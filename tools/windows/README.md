# Platform Notes (Windows)

For shared commands, flags, and flow, see `../README.md`. This file only lists Windows-specific notes.

- Preferred shell: PowerShell 7+ (cmd also works for the `.bat` scripts). If using WSL, follow `tools/linux` instructions instead.
- Allow script execution when needed: `Set-ExecutionPolicy -Scope Process Bypass -Force`.
- Install deps: Flutter (via `puro` or `fvm`, auto-detected), Java 17, Android SDK (`ANDROID_HOME`/`ANDROID_SDK_ROOT`), Node + `firebase-tools`, `jq` (e.g., `choco install jq`), Git.
- iOS is not supported on Windows; Android/localization/Firebase flows must mirror macOS/Linux interfaces.
- Quick smoke checks after changes: `./smoke.bat` (preferred) or `./build/build_apk.bat --help`, `./build/build_appbundle.bat --help`, `./localization/localization.sh --help`, `./config/flutterfire_config.sh --help` (use WSL for `.sh` helpers).
