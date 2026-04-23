# Codebase Summary

**Last Updated:** 2026-04-23
**Source Inputs:** `repomix-output.xml` (refreshed 2026-04-08) + direct repository verification

## 1. Snapshot Metrics
### Repomix package metrics
- Total packed files: **1,291**
- Total tokens: **1,086,342**
- Total chars: **4,691,465**
- Security-sensitive files excluded from output: **3 suspicious** and **3 binary**

### Dart metrics (live repository)
- Dart files in `lib/`: **978**
- Dart LOC in `lib/`: **158,925**
- Dart files in `test/`: **66**
- Dart LOC in `test/`: **8,972**

### Major app layers
| Path | Dart files | Dart LOC |
| --- | ---: | ---: |
| `lib/config` | 100 | 19,831 |
| `lib/core` | 104 | 13,333 |
| `lib/src` | 768 | 125,619 |

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
`lib/src` currently has **18** modules:

| Module | Dart files | Dart LOC | Notes |
| --- | ---: | ---: | --- |
| `achievenment` | 15 | 2,268 | Spelling matches codebase path |
| `auth` | 48 | 6,158 | Auth/session lifecycle |
| `common` | 21 | 2,576 | Shared state/pages/widgets |
| `course` | 76 | 11,583 | Course, roadmap, course lessons, and completed-level additional-content request UI |
| `data_collect` | 45 | 4,393 | Intake/onboarding data collection |
| `feedback` | 29 | 4,684 | User feedback flow |
| `home` | 18 | 2,098 | Dashboard/skillset entry + streak chip trigger |
| `learning_streak` | 21 | 2,581 | Home streak popup + shared completion streak success gate |
| `lesson` | 149 | 28,867 | Largest module: learning/exercise runtime |
| `monetization` | 38 | 5,989 | Products, purchase, verification |
| `onboard` | 38 | 5,779 | Intro/onboarding flow |
| `onboard_branching` | 44 | 9,836 | Remote-config controlled branching onboarding flow with fallback engine and course handoff |
| `output_practice` | 45 | 8,055 | Course-shell output practice conversation flow, intro sheet, socket room, and retryable chat history |
| `profile` | 35 | 4,880 | User profile and upload |
| `progress` | 34 | 8,261 | Progress, achievement progress, and completed-level additional-content request persistence |
| `roleplay` | 70 | 11,357 | Roleplay + AI feedback |
| `setting` | 17 | 2,202 | Theme/language/settings |
| `video_lesson` | 57 | 9,555 | Course-shell video lesson intro sheet, mounted player shell, notes/summary/share overlays, timed-question flow, completion streak gate, and tracking |

## 4. Architecture and Runtime Contracts
- Architecture style: feature-based Clean Architecture (`presentation`, `domain`, `data`).
- State management: `flutter_bloc` + HydratedCubit where persistence is needed.
- Use-case execution helpers: `runUseCase`, `runUseCaseList`, `runUseCaseVoid`, `runUseCasePageBreak`.
- Error/result flow: `TaskEither<AppException, T>`.
- REST integration: Retrofit + Dio, unified request helpers in the restful request handler mixin.
- Notification boot now runs as a dedicated config-level core in `lib/config/services/notification/`, with app startup awaiting `NotificationService.initialize(NotificationCoreConfig)` after Firebase.
- Notification folder modularization stays grouped under `adapters`, `bootstrap`, `constants`, `models`, `permissions`, `routing`, `runtime`, and `schedulers`, but the files are now owned by the shared `library + part` architecture in `lib/config/services/services.dart`.
- This reintroduces notification helper types into the exported services namespace as an intentional tradeoff, while Firebase/Awesome transport-specific package types still remain implementation-only.
- Course output practice now lives under `lib/src/output_practice/` and is launched from course roadmap output lessons through a typed `output-practice/:sectionId` route, with intro sheet handoff, conversation fetch/create fallback, scoped history pagination, socket join/reconnect handling, optimistic send/reconcile, retry affordances, and dedicated analytics events.
- Course roadmap now includes a completed-level additional-content request flow. Eligibility is derived from current roadmap completion plus matching `userCourseProgress.completedLevels`, and `ProgressCubit.loadAllUserProgresss()` now scopes course-grade refreshes so stale or lesson-filtered responses do not suppress the footer for the wrong course.
- Lesson runtime now keeps one typed `lesson` route for both read and listen entry. `RoadmapDetailPopup` branches between read-only and read/listen CTA states before navigation, `LessonPage` swaps between the preserved read surface and the new audio surface, and `LessonAudioCubit` owns route-session playback, speed, seek, inline failure recovery, and audio-complete handoff without folding that state into `LessonCubit`.
- Video lesson now lives under `lib/src/video_lesson/` and is launched from roadmap `openingVideo` / `closingVideo` lessons through a typed `video-lesson/:courseId/:nodeId/:lessonId` route. `RoadmapNodeActionHelper` resolves a unique roadmap node id, opens a tracked intro sheet, keeps a mounted player shell around `VideoPlayerController`, scopes notes cache by `courseId + nodeId + lessonId`, supports summary/share overlays plus timed-question/result overlays, pushes completion back into roadmap state after the progress update, and runs the shared streak gate before auto-exit.

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
1. Keep module count references at 18 unless `lib/src/*` changes.
2. Keep folder/module spelling as implemented (`achievenment`).
3. Keep use-case helper naming aligned with `runUseCase*` APIs.
4. Keep deployment docs aligned with platform script differences (`--ci` and `SKIP_SYMBOL_UPLOAD` parity gaps on Windows).
5. Keep output practice route, intro sheet, and tracking event names aligned with the implementation and route config.
6. Keep lesson route `initial-mode`, popup branching, and dual-mode runtime responsibilities aligned with the implementation and route config.
7. Keep video lesson route, overlays, timed-question contracts, and tracking event names aligned with the implementation and route config.

## 9. Quick Verification Commands
```bash
# Module count
find lib/src -mindepth 1 -maxdepth 1 -type d | wc -l

# SDK and iOS targets
rg -n "^environment:|sdk:" pubspec.yaml
rg -n "platform :ios|IPHONEOS_DEPLOYMENT_TARGET" ios/Podfile ios/Runner.xcodeproj/project.pbxproj

# Use-case mixin API names
rg -n "runUseCase|executeUseCase" lib/core/base/bloc lib/src -g"*.dart"

# Video lesson route and node resolution
rg -n "videoLesson|resolveVideoLessonNodeId" lib test -g"*.dart"
```
