# Meup Flutter Application

Meup is a multi-platform Flutter product for interactive language learning.
The app uses Clean Architecture with feature modules under `lib/src`, `TaskEither<AppException, T>` use cases, and cross-platform build/localization tooling.

## Quick Start
1. Bootstrap tooling
```bash
# macOS
tools/macos/config/setup_project.sh --non-interactive

# Linux
tools/linux/config/setup_project.sh --non-interactive

tools/smoke.sh

# Windows
tools\\windows\\config\\setup_project.bat --non-interactive
tools\\windows\\smoke.bat
```

2. Generate code and localization
```bash
dart run build_runner build --delete-conflicting-outputs

# macOS
tools/macos/localization/localization.sh pull
tools/macos/localization/localization.sh slang

# Linux
tools/linux/localization/localization.sh pull
tools/linux/localization/localization.sh slang

# Windows
tools\\windows\\localization\\localization.bat pull
tools\\windows\\localization\\localization.bat slang
```

3. Run quality checks
```bash
flutter analyze
flutter test
```

4. Launch a flavor
```bash
flutter run --flavor dev -t lib/main_dev.dart
# stg: --flavor stg -t lib/main_stg.dart
# prod: --flavor prod -t lib/main_prod.dart
```

## Current Repo Facts
- Feature modules in `lib/src`: **22**.
- Module folders: `achievenment`, `auth`, `common`, `course`, `daily_warm_up`, `data_collect`, `feedback`, `home`, `home_widget`, `in_app_survey`, `learning_streak`, `lesson`, `monetization`, `onboard`, `onboard_branching`, `onboard_v2`, `output_practice`, `profile`, `progress`, `roleplay`, `setting`, `video_lesson`.
- Dart SDK constraint (`pubspec.yaml`): `>=3.11.0 <4.0.0`.
- iOS deployment target (`ios/Podfile`): `15.0`.

## Core Documentation
| Topic | Location |
| --- | --- |
| Project Overview & PDR | `docs/project-overview-pdr.md` |
| Code Standards | `docs/code-standards.md` |
| System Architecture | `docs/system-architecture.md` |
| Codebase Summary | `docs/codebase-summary.md` |
| Project Roadmap | `docs/project-roadmap.md` |
| Deployment | `docs/deployment-guide.md` |
| Design Guidelines | `docs/design-guidelines.md` |
| API Integration | `docs/api-integration-guide.md` |
| GitLab CI/CD Setup | `docs/gitlab-cicd-setup-guide.md` |
| Tooling & Configuration | `tools/README.md`, `.info/README.md` |

## Architecture Highlights
- `lib/config/di` wires `get_it` + `injectable`.
- `lib/config/routes` uses typed `go_router` route data.
- Feature state uses Cubit/BLoC with `runUseCase`, `runUseCaseList`, `runUseCaseVoid`, `runUseCasePageBreak` mixins.
- Localization source is `assets/i18n/<locale>/<module>.yaml`; generated output is in `lib/config/l10n/`.
- Build scripts in `tools/macos|linux|windows/` apply flavor env files from `.env/.env.<flavor>`.

## License
See `LICENSE.md`.
