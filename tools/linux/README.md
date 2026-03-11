# Platform Notes (Linux)

For shared commands, flags, and flow, see `../README.md`. This file only lists Linux-specific notes.

- Shell: bash. Keep scripts executable (`chmod +x tools/linux/**/*.sh`).
- Install deps via apt/dnf/pacman equivalents: Java 17, Android SDK/commandline-tools (`ANDROID_HOME`/`ANDROID_SDK_ROOT`), Node + `firebase-tools`, `jq`, Git, and FlutterFire CLI (`dart pub global activate flutterfire_cli`). Flutter via `puro` or `fvm` is auto-detected.
- No iOS support here; Android/localization/Firebase flows must match macOS/Windows interfaces.
- Run app + tracking logs: `build/run_app.sh` (supports `run`, `logs`, `devices`, `clear`).
- Quick smoke checks after changes: `./build/build_apk.sh --help`, `./localization/localization.sh --help`, `./config/flutterfire_config.sh --help`.
