# Codebase Summary

**Last Updated:** 2026-03-05  
**Source Inputs:** `repomix-output.xml` (refreshed 2026-02-27) + direct repository verification

## 1. Snapshot Metrics
### Repomix package metrics
- Total packed files: **1,154**
- Total tokens: **990,724**
- Total chars: **4,197,465**
- Security-sensitive files under `.info/key/`: **8** (excluded from normal documentation scope)
- Binary-excluded files: **3**

### Dart metrics (live repository)
- Dart files in `lib/`: **889**
- Dart LOC in `lib/`: **140,541**
- Dart files in `test/`: **26**
- Dart LOC in `test/`: **2,390**

### Major app layers
| Path | Dart files | Dart LOC |
| --- | ---: | ---: |
| `lib/config` | 87 | 16,868 |
| `lib/core` | 105 | 13,668 |
| `lib/src` | 691 | 109,876 |

## 2. Repository Structure (High-Level)
```text
meup/
├── lib/
│   ├── main.dart + main_<flavor>.dart
│   ├── config/      # DI, routes, services, themes, l10n
│   ├── core/        # base models, request handlers, helpers, shared utils
│   └── src/         # feature modules
├── assets/          # fonts, images, i18n YAML
├── docs/            # project documentation
├── tools/           # macOS/Linux/Windows scripts
├── .github/         # GitHub workflows
├── .gitlab/         # GitLab CI templates + bootstrap scripts
└── .info/           # app/build/firebase/localization/distribution configs
```

## 3. Feature Module Inventory (`lib/src`)
`lib/src` currently has **16** modules:

| Module | Dart files | Dart LOC | Notes |
| --- | ---: | ---: | --- |
| `achievenment` | 15 | 2,268 | Spelling matches codebase path |
| `auth` | 48 | 5,675 | Auth/session lifecycle |
| `common` | 21 | 2,508 | Shared state/pages/widgets |
| `course` | 76 | 11,299 | Course, roadmap, course lessons |
| `data_collect` | 45 | 4,178 | Intake/onboarding data collection |
| `feedback` | 29 | 4,683 | User feedback flow |
| `home` | 18 | 2,083 | Dashboard/skillset entry + streak chip trigger |
| `learning_streak` | 20 | 2,435 | Home streak popup + completion streak success flow |
| `lesson` | 146 | 27,696 | Largest module: learning/exercise runtime |
| `monetization` | 38 | 5,650 | Products, purchase, verification |
| `onboard` | 37 | 5,553 | Intro/onboarding flow |
| `onboard_branching` | 44 | 9,832 | Remote-config controlled branching onboarding flow with fallback engine and course handoff |
| `profile` | 35 | 4,879 | User profile and upload |
| `progress` | 34 | 8,261 | Progress and achievement progress |
| `roleplay` | 70 | 11,362 | Roleplay + AI feedback |
| `setting` | 14 | 1,498 | Theme/language/settings |

## 4. Architecture and Runtime Contracts
- Architecture style: feature-based Clean Architecture (`presentation`, `domain`, `data`).
- State management: `flutter_bloc` + HydratedCubit where persistence is needed.
- Use-case execution helpers: `runUseCase`, `runUseCaseList`, `runUseCaseVoid`, `runUseCasePageBreak`.
- Error/result flow: `TaskEither<AppException, T>`.
- REST integration: Retrofit + Dio, unified request helpers in the restful request handler mixin.

## 5. API and Pagination Contract Summary
- API endpoint constants live in `lib/core/constants/manual/endpoint.dart`.
- Standard paginated request object: `PageBreakRequest`.
  - App fields: `page`, `limit`, `orderBy`, `order`, `search`, `filter`.
  - Serialized query keys: `page`, `take`, `orderBy`, `order`, `search`.
- Standard paginated response object: `BasePageBreak<T>` (`totalPages`, `currentPage`, `itemsPerPage`, `items`).

## 6. Build, Flavor, and Platform Summary
- Flavors: `dev`, `stg`, `prod` via `main_dev.dart`, `main_stg.dart`, `main_prod.dart`.
- Dart SDK constraint: `>=3.11.0 <4.0.0`.
- iOS deployment target: `15.0`.
- Tooling roots:
  - Build: `tools/<os>/build/*`
  - Localization: `tools/<os>/localization/localization.(sh|bat)`
  - Setup: `tools/<os>/config/setup_project.(sh|bat)`

## 7. CI/CD Snapshot
- GitHub: entry workflow delegates to reusable macOS or Linux pipelines based on `ENABLE_LINUX_PIPELINE`.
- GitLab: both macOS and Linux templates exist; top-level include currently points to macOS templates.
- CI bootstrap script: `.gitlab/scripts/bootstrap-secrets.sh` writes runtime files and exports `build/ci/runtime.env`.

## 8. Drift Watch Items
1. Keep module count references at 16 unless `lib/src/*` changes.
2. Keep folder/module spelling as implemented (`achievenment`).
3. Keep use-case helper naming aligned with `runUseCase*` APIs.
4. Keep deployment docs aligned with platform script differences (`--ci` and `SKIP_SYMBOL_UPLOAD` parity gaps on Windows).

## 9. Quick Verification Commands
```bash
# Module count
find lib/src -mindepth 1 -maxdepth 1 -type d | wc -l

# SDK and iOS targets
rg -n "^environment:|sdk:" pubspec.yaml
rg -n "platform :ios|IPHONEOS_DEPLOYMENT_TARGET" ios/Podfile ios/Runner.xcodeproj/project.pbxproj

# Use-case mixin API names
rg -n "runUseCase|executeUseCase" lib/core/base/bloc lib/src -g"*.dart"
```
