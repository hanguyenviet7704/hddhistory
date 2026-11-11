# Platform Notes (Windows)

For shared commands, flags, and flow, see `../README.md`. This file only lists Windows-specific notes.

- Preferred shell: PowerShell 7+ (cmd also works for the `.bat` scripts). If using WSL, follow `tools/linux` instructions instead.
- Allow script execution when needed: `Set-ExecutionPolicy -Scope Process Bypass -Force`.
- Install deps: Flutter (via `puro` or `fvm`, auto-detected), Java 17, Android SDK (`ANDROID_HOME`/`ANDROID_SDK_ROOT`), Node + `firebase-tools`, `jq` (e.g., `choco install jq`), Git, and FlutterFire CLI (`dart pub global activate flutterfire_cli`).
- iOS is not supported on Windows; Android/localization/Firebase flows must mirror macOS/Linux interfaces.
- Run app + tracking logs: `build\\run_app.bat` (supports `run`, `logs`, `devices`, `clear`).
- Quick smoke checks after changes: `./build/build_apk.bat --help`, `./build/build_appbundle.bat --help`, `./localization/localization.bat --help`, `./config/flutterfire_config.bat --help`.
