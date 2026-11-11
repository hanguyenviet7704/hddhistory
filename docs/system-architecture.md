# System Architecture

**Last Updated:** 2026-06-11
**Pattern:** Feature-based Clean Architecture + BLoC/Cubit  
**Platforms:** Android (project-configured `flutter.minSdkVersion`) and iOS (15.0+)

## 1. Runtime Overview
```text
main_<flavor>.dart -> main.dart -> AppService.init()
                          |
                          v
                 AppProviders + DI
                          |
                          v
                 MaterialApp.router
                          |
                          v
                     Feature routes
```

### Flavor entry points
- `lib/main_dev.dart`
- `lib/main_stg.dart`
- `lib/main_prod.dart`

Each flavor sets `F.appFlavor` before calling shared `main()`.

### App boot services
`AppService._configService()` now awaits notification boot immediately after `Firebase.initializeApp(...)`.

```text
HydrateBlocService.initialize()
  -> Firebase.initializeApp()
  -> NotificationService.initialize(NotificationCoreConfig)
  -> package/tracking/event/remote-config startup
```

## 2. Layered Feature Architecture
```text
lib/src/<feature>/
  presentation/  # pages/widgets/cubits/blocs
  domain/        # entities/repositories/usecases
  data/          # datasources/models/repositories
```

### Data flow
```text
Widget/Page
  -> Cubit/Bloc
  -> UseCase
  -> Repository interface (domain)
  -> Repository implementation (data)
  -> Data source (Retrofit/Dio/GraphQL/cache)
```

### Shared foundations
- `lib/config/`: DI, routing, services, themes, l10n.
- `lib/core/`: base request/response/error/use-case abstractions, helper utilities.

### Notification core boundary
- Notification runtime lives under `lib/config/services/notification/`.
- Notification files are owned by the shared `library + part` architecture rooted at `lib/config/services/services.dart`.
- Internal concerns are grouped by `adapters`, `bootstrap`, `constants`, `models`, `permissions`, `routing`, `runtime`, and `schedulers`.
- App and feature code should still prefer `NotificationService` and `NotificationCoreConfig` as the primary notification seam, even though helper types now live in the same exported services library namespace.
- Firebase Messaging and Awesome Notifications types still stay implementation-only inside the services layer.

## 3. Module Topology (`lib/src`)
Current module count: **22**.

Current modules: `achievenment`, `auth`, `common`, `course`, `daily_warm_up`, `data_collect`, `feedback`, `home`, `home_widget`, `in_app_survey`, `learning_streak`, `lesson`, `monetization`, `onboard`, `onboard_branching`, `onboard_v2`, `output_practice`, `profile`, `progress`, `roleplay`, `setting`, `video_lesson`.

## 4. State and Use Case Execution
### Core state stack
- `flutter_bloc` for reactive state.
- `HydratedCubit` for persisted state where needed.

### Use case execution helpers
Mixins in `lib/core/base/bloc/` provide standardized execution paths:
- `runUseCase<T>`
- `runUseCaseList<T>`
- `runUseCaseVoid()`
- `runUseCasePageBreak<T>()`

These helpers centralize loading/success/failure handling and reduce Cubit/Bloc boilerplate.

## 5. Error and Network Architecture
### Error model
- Unified domain error type: `AppException`.
- Functional return contract: `TaskEither<AppException, T>`.

### Network stack
- REST: Dio + Retrofit API interfaces in feature data sources.
- Optional GraphQL client paths where configured.
- Request handler mixins (`RestfulRequestHandlerMixin`) provide:
  - transform wrappers for `BaseResponse<T>`
  - list wrappers for `BaseResponseList<T>`
  - paginated wrappers for `BaseResponse<BasePageBreak<T>>`

### Failure and unauthorized recovery flow (REST)
1. `AppInterceptor` decorates requests with auth + locale headers.
2. On `401`, it attempts one refresh-token retry through `AuthBloc.refreshAccessToken()`.
3. If refresh succeeds, original request is retried with updated bearer token.
4. If refresh fails and onboarding branching transition is active, register redirect is suppressed and a silent anonymous re-login is attempted.
5. If refresh fails outside onboarding branching transition, app session is reset and user is routed back to auth flow.
6. For non-401 failures, repository/request helpers map transport errors to `AppException` and return `TaskEither` left states.

## 6. Pagination Contract
- Request type: `PageBreakRequest<T extends JsonRequestConvertible>`.
- App-side fields: `page`, `limit`, `orderBy`, `order`, `search`, `filter`.
- Serialized keys: `page`, `take`, `orderBy`, `order`, `search`.
- Response type: `BasePageBreak<T>` with `totalPages`, `currentPage`, `itemsPerPage`, `items`.

## 7. Dependency Injection
- DI framework: `get_it` + `injectable`.
- Primary setup under `lib/config/di/`.
- Feature services, APIs, repositories, and cubits/blocs are resolved through DI configuration.

## 8. Routing Architecture
- Router implementation: `go_router` with generated route data.
- Root configuration under `lib/config/routes/base/`.
- Feature route data under `lib/config/routes/data/`.
- Shell-based navigation and nested home/course/lesson/roleplay/output-practice/video-lesson flows are handled in route config files.

### Splash and auth-entry runtime flow
- `SplashPage` remains the single first-entry gate after force-update and deep-link checks complete.
- In no-token startup, splash only runs the device lookup when `UserCubit.isUserPassOnboarding` is still `true`; ordinary first-time users without a recognized device go to `OnboardV2Route`, while recognized devices continue to the notification gate/register path.
- Authenticated startup still honors `UserCubit.isUserPassOnboarding`: a persisted access token does not bypass unfinished onboarding, and home data initialization waits until onboarding is cleared.
- `OnboardCubit` now keeps onboarding-content load state separate from device-recognition state so intro content and device lookup do not race.
- Recognized devices (`userByDeviceId.id.isNotEmpty`) skip `OnboardV2Route` and keep the legacy `NotificationRequestRoute(showPaywallAfterAuth: true)` before `RegisterRoute(showPaywallAfterAuth: true)` path while onboarding stays enabled.
- Unrecognized devices or safe lookup misses go to `OnboardV2Route` without surfacing a splash auth error.
- Opening `RegisterRoute()` still silently bootstraps an anonymous guest session through `AuthBloc`, preloads `HomeCubit.initializeData(isInit: true)`, and keeps the register UI visible while the user picks Guest, Google, or Apple.
- When onboarding is disabled, first open now routes through `NotificationRequestRoute(courseEntryMode: true)` instead of the legacy register/paywall shortcut. Splash may warm anonymous course-entry auth in the background, but the notification CTA remains the source of truth; CTA success completes the dedicated course-entry notification gate, bootstraps anonymous auth/home-course data, clears onboarding, and opens `CourseRoute(selectedTabIndex: 0)`. Retryable bootstrap failure keeps the user on the notification gate, and only unrecoverable anonymous auth failure falls back to plain `RegisterRoute()`. `CoursePage` remains manual and does not auto-transition to roadmap entry.
- Silent register bootstrap never opens paywall by itself. Guest, Google, and Apple auth success consume any legacy first-time paywall intent, then route to Course or Home; paywall presentation is owned by stable-route auto-open after navigation settles.
- Guest continue now reuses the bootstrapped anonymous session when available and only falls back to a fresh anonymous login if bootstrap failed.
- Google and Apple continue to replace the guest session through the existing auth-success path, and any guest course handoff now routes with `CourseRoute(selectedTabIndex: 0)` while resetting home selection to the first category to avoid stale post-logout state.
- The paywall uses Remote Config `paywall_config` schema v2. The parser keeps legacy lesson-lock keys, pivots locale-major sale copy into multilingual entities, and resolves strategies by priority: active `saleEvent`, then eligible `newUser` impression rule, then `defaultUser`.
- Strategy product loading is fail-closed: config IDs define display order and the exact App Store / Play product IDs to query; missing BE rows, missing store rows, invalid/duplicate IDs, or unavailable stores keep auto-open closed and leave manual paywall entries in retry state.
- Auto-open is evaluated once per cold-start session on Home/Course after force-update and deep-link gates. Eligible authenticated or anonymous non-premium users must have completed onboarding, pass session rollout, and refresh premium status successfully; unknown premium state, premium users, suppressed deep-link/widget launches, invalid config, or product load failure do not open paywall.
- Every paywall entry keeps the top-bar close slot reserved but hides the close affordance for five seconds before revealing it. Automatic and manual entries push `PaywallRoute` over the current stable route, so close and purchase-success dismissal return to the source route while purchase failure or cancel leaves the user on paywall.

### Onboarding V2 runtime flow
- `OnboardV2Route` is the default first-time path and is typed at `/onboard-v2`; it builds `OnboardV2Cubit.initialize()` alongside `UserCubit` and `NotificationCubit`.
- `OnboardV2Page` is an eight-step shell: intro, name, age, notification, path selection, path map, symptom selection, and course picker.
- `OnboardV2Cubit` owns the flow state machine. It loads onboarding content, starts anonymous login in background, submits the P3 profile update asynchronously, derives symptoms from selected paths, and loads P8 courses with repeated `onboardingSymptoms` filters. This flow does not add a broad cache fallback.
- P4 uses the shared notification boundary: the page refreshes permission state, either requests permission or records "maybe later", persists `UserCubit.hasCompletedFirstTimeNotificationGate`, and blocks runtime back navigation.
- P8 shows up to three valid randomized courses, fetches the current visible course detail, then hands off through `CourseHandoffHelper` to either `CourseRoadmapRoute` or `CourseRoute(selectedTabIndex: 0)` before clearing `isUserPassOnboarding`.
- Tracking is centralized in `TrackingKey.onboardV2*` and `OnboardV2Tracking`; onboarding copy lives in `assets/i18n/<locale>/onboarding.yaml` and generated `lib/config/l10n/*` keys.

### Notification preference runtime flow
- `NotificationRequestRoute` is a dedicated onboarding-only pre-register gate. It mirrors `RegisterRoute` query intent flags but keeps non-onboarding `RegisterRoute()` callers unchanged.
- `NotificationRequestPage` persists one-time completion in `UserCubit.hasCompletedFirstTimeNotificationGate`.
- Gate auto-skip happens when the one-time flag is already set or when notification capability is unavailable. Authorized/provisional runtime state now still shows the gate once so onboarding/bypass entry always lands on the explainer screen before auth.
- `NotificationCubit` is now a hydrated shared boundary for both onboarding and settings. It persists only the app-level preference (`notificationsEnabled` + initialization flag), mirrors that preference into a shared store for service/background access, and always refreshes runtime permission state from `NotificationService`.
- Settings now expose an inline notification toggle on `SettingPage`. Effective ON requires both app-level preference and runtime capability; app resume refreshes the runtime state to reflect OS settings changes. On iOS, enabling from settings still requests permission in-app while the OS permission is requestable, then falls back to the app's system settings screen only when the OS must own the change. A resume sync back from the live OS permission state only happens after an intentional settings roundtrip.
- `NotificationService`, foreground local rendering, and background data-only push rendering now read the shared app-level preference before showing or scheduling local notifications, so app-level OFF suppresses client-side notification rendering even when OS permission is still granted.

### Lesson runtime flow
- `CourseRoadmapRoute` composes roadmap + lesson + progress + feedback state providers.
- `RoadmapDetailPopup` resolves usable keypoint audio before rendering its CTA contract and routes through the same lesson path with `LessonRoute(initialMode: read|audio)`.
- `LessonRoute` composes lesson execution providers (`LessonCubit`, `LessonAudioCubit`, exercise/theory/speaking variants, `ProgressCubit`, `FeedbackCubit`, `PageCubit`).
- `LessonPage` now acts as the lesson shell/orchestrator: every lesson route renders the Figma-style lesson shell, no-audio keypoints show close-only read mode, and audio-enabled keypoints add the read/listen mode toggle.
- `LessonAudioCubit` owns route-session audio playback state, speed, seek bounds, inline failure recovery, and audio-complete handoff into the shared keypoint completion seam; the speed selector is exposed through the audio-mode shell header.
- Completion routes (`KeypointCompleteRoute`, `BadgeProgressRoute`) merge lesson progress back into roadmap/home state.

### Output practice runtime flow
- `RoadmapNodeActionHelper` resolves an output lesson to a course-shell `sectionId`, opens `OutputPracticeIntroSheet`, and tracks popup view/close/start events through `AppTrackingService`.
- `OutputPracticeRoute` is typed as `output-practice/:sectionId`; it injects `OutputPracticeCubit`, `OutputPracticeSocketCubit`, `HomeCubit`, and `CourseRoadmapCubit` before building `OutputPracticePage`.
- `OutputPracticeCubit.initialize(sectionId)` fetches an existing conversation first, creates one when the backend returns `NotFoundException` or an empty response, and then loads page 1 of scoped history for that conversation id.
- History pagination stays scoped to the current conversation id, older pages are prepended, and the page exposes retry actions for history fetch failures, room-join failures, and failed message resend.
- `OutputPracticeSocketCubit` connects to the socket server, joins the room, retries one initial join after timeout, and exposes `reconnect()` plus `disconnect()` for page lifecycle cleanup.
- Message sending uses optimistic pending timeline rows, reconciles canonical messages after REST send succeeds, and preserves a retryable failure state when send or socket delivery fails.
- Dedicated tracking events cover popup view/close/start, screen view, option click, send click, and exit click.

### Course roadmap completed-level request flow
- `CourseRoadmapPage` now loads course-grade progress for the active roadmap course on entry and course switches.
- `ProgressCubit.loadAllUserProgresss()` keeps course-grade requests scoped to the explicit course filter, does not leak the selected lesson id into `grade: course` fetches, and ignores stale out-of-order completions.
- `RoadmapEntity.additionalContentRequestStateFor(...)` combines current roadmap completion with matching `UserProgressEntity.completedLevels`, so the request footer only appears for the latest completed current level and stays hidden until the matching course progress is loaded.
- `CompletedLevelAdditionalContentRequestCard` and `CompletedLevelAdditionalContentRequestPopup` render the Figma-driven footer and popup states, while `ProgressCubit.submitCompletedLevelAdditionalContentRequest(...)` persists `No`, `Later`, and `Send request` through `PUT /api/v1/courses-user-progress/completed-level/additional-content-request`.

### Video lesson runtime flow
- `RoadmapNodeActionHelper` resolves roadmap `openingVideo` / `closingVideo` lessons to a unique owner `nodeId`, opens `VideoLessonIntroSheet`, and keeps ambiguous/missing matches on the roadmap with a non-blocking message.
- `VideoLessonRoute` is typed as `video-lesson/:courseId/:nodeId/:lessonId`; it injects `VideoLessonCubit`, `HomeCubit`, and `CourseRoadmapCubit` before building `VideoLessonPage`.
- `VideoLessonCubit.initialize(courseId, nodeId, lessonId)` loads the lesson and video learning item, while `VideoLessonPage` owns the mounted `VideoPlayerController` shell and routes controller ticks back into playback/completion state.
- The runtime keeps one mounted player shell across play/pause, seek, notes, summary, question, result, and end states; notes use scoped cache keys (`courseId + nodeId + lessonId`) with session-local draft persistence and CRUD refresh.
- Timed questions use crossed-time detection, zero-second first-play gating, forward-seek queue drain, backward re-arm, local choice-family result state, unsupported fallback handling, and end-after-queue progression.
- Completion success first persists progress, then runs the shared learning streak gate before auto-exit; the gate fails open for timeout/failure/non-positive streak outcomes and waits for a current route before exiting when another modal is on top.
- Tracking now covers popup, screen, play, pause, seek, notes, summary, share, quiz, result, exit, complete view, and mark-complete actions.

### Roleplay runtime flow
- `RoleplayIntroRoute` and `RoleplayRoute` provide roleplay orchestration via `RoleplayCubit` (+ feedback where needed).
- `RoleplayFeedbackRoute` merges `RoleplayCubit`, `RoleplayPointCubit`, `HomeCubit`, and `FeedbackCubit` for post-session analytics and UI.
- Route-level provider composition keeps runtime concerns scoped to each flow stage.

### Learning streak runtime flow
- `HomeRoute` composes `LearningStreakCubit`, and nested `HomeLearningStreakRoute` maps to `LearningStreakPage`.
- `HomePage` prefetches streak data with a short timeout and safe-default fallback before/while rendering the header streak chip.
- `LearningStreakPage` is used as a bottom-sheet style popup flow and emits home streak popup view/close tracking events.
- `KeypointCompletePage`, `RoleplayFeedbackPage`, and video lesson completion success run a streak gate: load streak, show success overlay only on remote positive streak, then persist commit day via `LearningStreakCubit.lastStreakCountedDate` (UTC-day guard).

### Home in-app survey runtime flow
- `HomeRoute` now composes `InAppSurveyCubit`; `HomePage` loads survey config once per usable session and renders the P1 floating entry pill above the bottom navigation area.
- The P1 pill opens a non-dismissible `showGeneralDialog` that reuses the route-level Cubit for P2 rating, P3 closed-question options, and P4 optional feedback.
- `InAppSurveyCubit` owns transient draft state only: selected branch index, selected option ids, feedback, and submit loading. Closing resets the draft without submitting; submit failure preserves the draft; submit success resets the draft and returns to P1.
- `InAppSurveyRepository` posts only `branchId`, `selectedOptionIds`, and trimmed `feedback` to `/api/v1/courses-in-app-survey/responses`.
- Survey analytics use `TrackingKey.inAppSurvey*` via semantic `ITrackingService` helpers. Raw feedback text and raw API error bodies are not tracked; tracking failures are swallowed.

### Daily warm-up runtime flow
- `HomeRoute` composes `DailyWarmUpCubit`; authenticated Home checks a per-user local date gate after streak prefetch and before in-app survey display.
- `DailyWarmUpRepository` calls `/api/v1/courses-user-progress/daily-warm-up` through the authenticated REST client and skips Home entry silently on API or payload validation failure. Stale cached warm-up data is not displayed after failure.
- `DailyWarmUpPage` renders P1 entry, P2 local-only non-speaking questions, and P3 completion in a full-screen Home child route. P2 answer checks do not call lesson progress, completion, or score APIs.
- P3 loads the suggested course with `GetCourseUseCase` and routes to `CourseRoadmapRoute` only when `CourseHandoffHelper.prepareRecommendedCourse` returns the roadmap intent; course or roadmap preparation failure closes back to Home.
- Daily warm-up analytics use `TrackingKey.dailyWarmUp*` via semantic `ITrackingService` helpers. Raw question text, option text, answer text, and raw API error bodies are not tracked.

### Home widget runtime flow
- `AuthBloc` starts a best-effort `SyncHomeWidgetsUseCase` after auth success and clears stored widget payloads during session reset.
- `HomeWidgetRepository` calls the in-progress, suggested-course, and streak APIs, builds display-only JSON payloads, saves course images best-effort through `home_widget`, and preserves previous payloads on API failures.
- Suggested-course payloads are reused for the same local day to avoid random backend churn on repeated syncs, but course progress on the cached suggestion bypasses the cache so the widget can rotate to the next suggestion.
- iOS WidgetKit and Android Glance read shared JSON/image data using the same storage keys. Bundled native assets cover book, certificate, and flame fallbacks when shared image paths are missing.
- Widget taps emit sanitized `hddhistory://` / `https://meup.training` URLs. `DeeplinkCubit` validates `source=home_widget`, routes empty/exhausted states to Home, routes valid course/streak states to Course Roadmap, and tracks tap/result events without raw URLs.

### Onboarding branching runtime flow
- Flow switch is driven by remote config key `onboarding_config` (`normal`/`branching`) with fail-safe fallback to `normal`.
- Name step (`data_collect`) uses replace-style route handoff to `OnboardBranchingRoute`.
- Branching runtime uses scene/content pointers (`currentSceneId`, `currentContentIndex`) with deterministic transitions.
- Mandatory fallback path routes safely back to `DataCollectRoute` and preserves duplicate-anonymous-login guard.

## 9. Localization and Theming
### Localization
- Source YAML: `assets/i18n/<locale>/<module>.yaml`.
- Generated output: `lib/config/l10n/`.
- Supported locales in repo: EN, VI, ZH.

### Theme
- Core theme files: `lib/config/themes/`.
- Active font family in theme config: `Mulish`.
- Color contracts are defined in `AppCustomColor`, `AppColorLight`, and `AppColorDark`.

## 10. Operational Constraints
- Dart SDK: `>=3.11.0 <4.0.0`.
- iOS minimum target: `15.0`.
- Flavor env files: `.env/.env.dev`, `.env/.env.stg`, `.env/.env.prod`.

## 11. Architecture Change Checklist
Update architecture docs when any of these change:
1. Feature module set under `lib/src`.
2. Use case helper APIs/mixin contracts.
3. Request/response base contracts.
4. DI boot path or route boot path.
5. Runtime constraints (SDK/platform minimums).
