# Meup Codebase Structure & Organization

**Last Updated:** Jan 22, 2026
**Total LOC:** ~86,000+ | **Dart Files:** 782 | **Architecture:** Clean Architecture

---

## 1. Project Root Structure

```
meup/
├── lib/
│   ├── main_dev.dart           # Entry point (dev flavor)
│   ├── main_stg.dart           # Entry point (stg flavor)
│   ├── main_prod.dart          # Entry point (prod flavor)
│   ├── main.dart               # Shared initialization
│   ├── config/                 # App configuration (15K LOC)
│   │   ├── di/                 # Dependency injection
│   │   ├── services/           # Service implementations (51 files)
│   │   ├── routes/             # Navigation routing
│   │   ├── themes/             # UI themes & styling
│   │   └── l10n/               # Localization (generated)
│   ├── core/                   # Shared utilities & base classes (17K LOC)
│   │   ├── base/               # Error, response models, use cases, BLoC mixins
│   │   ├── constants/          # App-wide constants (manual, no generation)
│   │   ├── helpers/            # Helpers & mixins
│   │   └── utils/              # UI components & utilities
│   └── src/                    # Feature modules (54K+ LOC, 13 modules)
│       ├── auth/               # Authentication (40 files, 3.2K LOC)
│       ├── course/             # Course management (67 files, 6.8K LOC)
│       ├── lesson/             # Interactive exercises (122 files, 10.5K LOC)
│       ├── roleplay/           # AI roleplay (67 files, 3.6K LOC)
│       ├── monetization/       # In-app purchases (38 files, 5.6K LOC)
│       ├── progress/           # Progress tracking (34 files, 8.2K LOC)
│       ├── profile/            # User profile (35 files, 4.9K LOC)
│       ├── onboard/            # Onboarding flow (37 files, 5.5K LOC)
│       ├── data_collect/       # User survey (45 files, 4.1K LOC)
│       ├── home/               # Dashboard (18 files, 2.0K LOC)
│       ├── achievement/        # Badges system (15 files, 2.3K LOC)
│       ├── setting/            # App settings (14 files, 1.5K LOC)
│       └── common/             # Global state (20 files, 2.4K LOC)
├── test/
│   └── unit/                   # Feature-based unit tests
├── assets/                     # Static resources
│   ├── fonts/                  # Mulish font family
│   ├── icons/                  # App & common icons
│   ├── images/                 # Feature & common images
│   ├── lottie/                 # Animation JSON files
│   ├── texts/                  # Static text files
│   └── i18n/                   # Localization YAML (en, vi, zh)
├── .info/                      # Centralized configuration (git-ignored)
│   ├── app/                    # App config: app.json, build.json, firebase.json
│   ├── key/                    # Signing keys & service account JSON
│   ├── distribution/           # Release notes, tester lists
│   └── deeplink/               # Apple/Android universal links
├── tools/                      # Cross-platform build scripts
│   ├── macos/build/            # macOS build scripts
│   ├── linux/build/            # Linux build scripts
│   └── windows/build/          # Windows build scripts
├── .github/workflows/          # CI/CD GitHub Actions
├── .env/                       # Environment configs (git-ignored)
│   ├── .env.dev
│   ├── .env.stg
│   └── .env.prod
├── pubspec.yaml                # Flutter dependencies
├── analysis_options.yaml       # Dart linter configuration
├── CLAUDE.md                   # Development guidelines
└── README.md                   # Project documentation
```

---

## 2. lib/config/ - Application Configuration (15K LOC)

### 2.1 Dependency Injection (di/)
**Files:** 7 | **LOC:** 1,050

| File | Purpose |
|------|---------|
| `app_di_config.dart` | @InjectableInit root, generates di.config.dart |
| `di.dart` | AppDI mixin exposing injector interface |
| `cache_di.dart` | Cache service registration (HydratedBloc) |
| `network_di.dart` | Dio, Retrofit, GraphQL service setup |
| `route_observer_di.dart` | Route observers for navigation tracking |
| `supabase_di.dart` | Optional Supabase backend |
| `tracking_di.dart` | Analytics service aggregators |

**Usage Pattern:**
```dart
// Initialization
await AppDI.initializeDependencies();

// Resolution
getIt<CourseCubit>();
AppDI.injector.get<AuthService>();
```

### 2.2 Services (services/)
**Files:** 51 | **LOC:** 7,697

Organized by subdirectory:

| Service Category | Purpose |
|-----------------|---------|
| **Network** | `restful_service.dart` (Dio HTTP), `graphql_service.dart` (GraphQL client) |
| **Auth** | `auth_service.dart` (Firebase/Supabase wrapper) |
| **Analytics** | `app_tracking_service.dart` (170+ events: Firebase, Sentry, custom), `app_event_service.dart` (Facebook, TikTok) |
| **Remote Config** | `firebase_remote_config_service.dart` (AppVersionConfig, CourseConfig, PaywallConfig entities) |
| **Notifications** | `notification_service.dart` (AwesomeNotifications) |
| **Storage** | `cache_service.dart`, `local_store_service.dart` (SharedPrefs), `hydrated_service.dart` |
| **Device** | `device_info_service.dart`, `package_info_service.dart` |
| **Media** | `media_service.dart`, `file_service.dart` (file uploads) |
| **Monetization** | `iap_service.dart` (StoreKit) |
| **Deep Linking** | `deep_link_service.dart` (app_links integration) |

**Key Pattern: Interceptors**
- REST: BaseInterceptor → CustomInterceptor (auth token injection, error mapping)
- GraphQL: GraphQL link pattern with performance tracking

### 2.3 Routing (routes/)
**Files:** 14 | **LOC:** 2,518

Type-safe routing via `go_router` + `go_router_builder`:

| File | Purpose |
|------|---------|
| `app_routes_config.dart` | GoRouter instance + shell routes |
| `app_routes.dart` | Route path constants |
| `app_pages.dart` | Page builders with transitions |
| `routes_*_data.dart` (10 files) | Feature-specific route data classes (generated) |

**Navigation Layers:**
```
ShellRoute (bottom nav) → Pages (Auth, Home, Course, Setting)
    ↓
Feature Routes (Course → Lesson → Roleplay)
    ↓
Common Routes (WebView, Image Viewer)
```

### 2.4 Themes (themes/)
**Files:** 6 | **LOC:** 2,298

| File | Purpose |
|------|---------|
| `colors.dart` | Color palette (primary, secondary, success, warning, error, neutral) |
| `text_theme.dart` | Typography system (headings, body, captions) |
| `material_theme.dart` | ThemeData builders (light/dark variants) |
| `theme_collection.dart` | Theme switching logic |
| `util_theme.dart` | Theme utilities & extensions |

**Responsive Design:** flutter_screenutil integration for adaptive sizing

### 2.5 Localization (l10n/)
**Files:** 5 | **LOC:** 2,543

Generated by `slang_flutter` from YAML sources:

| File | Purpose |
|------|---------|
| `l10n.dart` | Library export |
| `l10n.g.dart` | Base generated class |
| `l10n_en.g.dart` | English translations |
| `l10n_vi.g.dart` | Vietnamese translations |
| `l10n_zh.g.dart` | Chinese translations |

**Supported Languages:** English, Vietnamese, Chinese

---

## 3. lib/core/ - Shared Utilities (17K LOC)

### 3.1 Base Classes (base/)
**Files:** 17 | **LOC:** 5,191

#### Error Handling (error/app_exception.dart)
```dart
sealed class AppException {
  .generic, .server, .connection, .database, .cache,
  .notFound, .unauthorized, .invalidInput,
  .unexpected, .forbidden, .pending
}
```
Extensions: `message`, `displayMessage` (user-friendly fallback)

#### Network Models (request/, responses/)
- `RestfulRequest`, `GraphQLRequest` - base request types
- `BaseResponse<T>`, `BaseResponseList<T>` - response wrappers
- `BasePageBreak<T>` - pagination (items, currentPage, totalPages)
- `BaseMultiLanguage` - multi-language field support

#### Use Case Pattern (use_case/use_case.dart)
```dart
abstract class UseCase<Type, Params> {
  TaskEither<AppException, Type> call(Params params);
}
```
Returns `TaskEither` for functional error handling (fpdart)

#### BLoC Mixins (Boilerplate Reduction)
- **CubitUseCaseHandlerMixin** - Simplifies use case execution in Cubits
- **BlocUseCaseHandlerMixin** - Simplifies use case execution in BLoCs
- **CubitActionHandlerMixin** - Event/action dispatching without use cases
- Methods: `runUseCase<T>()`, `runUseCaseList<T>()`, `runUseCasePageBreak<T>()`

### 3.2 Constants (constants/manual/)
**Files:** 20 | **LOC:** 1,300

All manually maintained (no auto-generation):

| File | Purpose |
|------|---------|
| `app_path.dart` | App-level paths |
| `base_url.dart` | API base URLs (dev/stg/prod) |
| `cache_key.dart` | SharedPreferences keys |
| `endpoint.dart` | API endpoint paths |
| `env.dart` | Environment configuration |
| `in_app_key.dart` | StoreKit product IDs |
| `tracking_key.dart` | 170+ analytics event names (onboarding, course, lesson, roleplay, progress, payment events) |
| `remote_config_key.dart` | Firebase Remote Config keys (appVersionConfig, courseConfig, paywallConfig) |
| `notification_key.dart` | Notification channel IDs |

### 3.3 Helpers (helpers/)
**Files:** 10 | **LOC:** 1,649

| Helper | Purpose |
|--------|---------|
| **DNavigator** | Route context methods (push, pop, replace) |
| **DDialog** | Material dialogs (AlertDialog, ConfirmDialog) |
| **DMessage** | Snackbars & toast messages |
| **LogDev** | Development logging with prefix |
| **Extension utilities** | DateTime, String, List, Map extensions |

### 3.4 UI Utils (utils/)
**Files:** 59 | **LOC:** 6,394

Reusable Flutter widgets organized by category:

| Category | Files | Purpose |
|----------|-------|---------|
| **Button** | 4 | Material, gradient, CTA buttons |
| **Text** | 8 | Styled text, gradients, highlights, expandable |
| **Image** | 6 | Cached images, avatars, containers, Lottie |
| **Input** | 4 | TextField, Dropdown, Range slider, Search |
| **Selection** | 2 | Checkbox, Radio button |
| **Layout** | 4 | Landing, Scaffold, Error, SafeArea |
| **Overlay** | 8 | Dialogs, Bottom sheets, Notifications |
| **Navigation** | 3 | Bottom nav, nav items |
| **Sliver** | 3 | SliverAppBar, child builders |
| **Animation** | 4 | FadeUp, Expand, Transitions, Slide |
| **Wrapper** | 5 | Loading overlay, Gradient borders |
| **Specialty** | 5 | Video, WebView, SVG, Timer, Countdown |

---

## 4. lib/src/ - Feature Modules (54K+ LOC)

Each feature follows Clean Architecture: **Data → Domain → Presentation**

### 4.1 Auth Module (40 files, 3.2K LOC)
**Purpose:** Authentication & session management

| Layer | Count | Files |
|-------|-------|-------|
| Data | 4 files | REST API, local storage, models |
| Domain | 15 files | Entities, repository interface, 14 use cases |
| Presentation | 20 files | AuthBloc (event-driven), UserCubit (persistent), pages, widgets |

**Key Use Cases:** LoginUseCase, RegisterUseCase, LoginSSOGoogleUseCase, LoginSSOAppleUseCase, ForgotPasswordUseCase, VerifyOTPUseCase, RefreshTokenUseCase, LogoutUseCase, DeleteAccountUseCase

### 4.2 Course Module (67 files, 6.8K LOC)
**Purpose:** Course catalog & learning paths

| Layer | Count | Files |
|-------|-------|-------|
| Data | 6 files | 2 REST APIs, 2 local datasources, models |
| Domain | 6 files | Entities, repository, 5 use cases |
| Presentation | 40 files | 3 Cubits, 3 pages, 25+ widgets |

**Key Entities:** CourseEntity, RoadmapEntity, RoadmapLevelEntity, RoadmapNodeEntity, KeypointEntity, LearningItemEntity

**UI Highlights:** Course roadmap timeline, keypoint cards, course progress indicators

### 4.3 Lesson Module (122 files, 10.5K LOC)
**Purpose:** Interactive learning exercises (LARGEST MODULE)

| Layer | Count | Files |
|-------|-------|-------|
| Data | 3 files | REST API, local storage, 8+ models |
| Domain | 9 files | Entities, repository, 4 use cases |
| Presentation | 106 files | 9 Cubits (per exercise type), 3 pages, 80+ widgets |

**9 Exercise-Type Cubits:**
1. TheoryCubit - Document display
2. ChoiceCubit - Single/multiple choice
3. DragAndDropCubit - Sentence building
4. CuesPlacementCubit - Pronunciation cues
5. MarkStressWordCubit - Word stress marking
6. SpeakingCubit - Voice recording
7. ArrangeTheSequenceCubit - Reorder items
8. ExerciseCubit - Master flow state
9. LessonCubit - Overall progress

**Key Widgets:** DocumentWidget, AudioPlayerWidget, ChoiceAnswerCard, SentenceBuilder, RecordingControlsArea, WaveformVisualizer

**Entity Extensions:** QuestionEntity with `explanationText`, `hasExplanation` properties for answer explanation display

### 4.4 Roleplay Module (67 files, 3.6K LOC)
**Purpose:** AI-driven conversational practice

| Layer | Count | Files |
|-------|-------|-------|
| Data | 4 files | 2 REST APIs, local storage, 8 models |
| Domain | 8 files | Entities, repository, 2 use cases |
| Presentation | 55 files | 2 Cubits, 4 pages, 40+ widgets |

**UI Components:** RoleplayBubbleWidget (dialogue), RoleplayTransitionWidget, RoleplayFeedbackChart, RoleplayContent (flow manager)

**Feedback:** ML-scored breakdown (grammar, pronunciation, vocabulary)

### 4.5 Monetization Module (38 files, 5.6K LOC)
**Purpose:** In-app purchases & subscriptions

| Layer | Count | Files |
|-------|-------|-------|
| Data | 2 REST APIs | UserSubscriptionApi, MonetizationApi |
| Domain | 5 use cases | GetPackagesUsecase, PurchaseUsecase, VerifyUsecase, RestoreUsecase |
| Presentation | 1 Cubit | IapCubit |

**Key UI:** PaywallPage (carousel, plan options), PaywallSuccessPurchasePopup, UserSubscriptionPage

### 4.6 Progress Module (34 files, 8.2K LOC)
**Purpose:** Track user progress across courses, lessons, keypoints

| Layer | Count | Files |
|-------|-------|-------|
| Data | 2 REST APIs | UserProgressApi, AchievenmentProgressApi |
| Domain | 8+ use cases | GetUserProgressMyCoursesUsecase, UpdateUserProgressLessonUsecase, GetCourseLevelProgressUsecase |
| Presentation | 2 Cubits | ProgressCubit, AchievenmentProgressCubit |

**Cross-Module Coupling:** Depends on HomeCubit, CourseLessonCubit, CourseRoadmapCubit, UserCubit, RoleplayCubit

### 4.7 Profile Module (35 files, 4.9K LOC)
**Purpose:** User profile management & avatar upload

| Layer | Count | Files |
|-------|-------|-------|
| Data | 2 REST APIs | ProfileApi, UploadApi |
| Domain | 3 use cases | GetUserUsecase, UpdateUserUsecase, UploadFileUsecase |
| Presentation | 2 Cubits | ProfileCubit (HydratedCubit), UploadCubit |

**Features:** Multipart file upload, profile editing, achievement display

### 4.8 Onboard Module (37 files, 5.5K LOC)
**Purpose:** Welcome flow, intro screens, motivation questionnaire

| Layer | Count | Files |
|-------|-------|-------|
| Data | 1 REST API | OnboardApi |
| Domain | 1 use case | GetAllOnboardsUsecase |
| Presentation | 2 Cubits | OnboardCubit, IntroCubit |

**UI:** SplashPage, OnboardPage (character dialogue), OnboardIntroducePage (carousel), IntroStepContent

### 4.9 Data Collect Module (45 files, 4.1K LOC)
**Purpose:** Comprehensive onboarding questionnaire (9-step stepper)

| Layer | Count | Files |
|-------|-------|-------|
| Domain | 5 use cases | Create, Get, Update, Delete, GetAll for UserCollectDataEntity |
| Presentation | 1 Cubit | DataCollectCubit |

**Steps:** Name → Age → Gender → Learning Goal → Skills → Struggles → Learning Method → Daily Goal → Learning Time

### 4.10 Home Module (18 files, 2.0K LOC)
**Purpose:** Dashboard displaying skillsets & enrolled courses

| Layer | Count | Files |
|-------|-------|-------|
| Domain | 2 use cases | GetAllSkillsetsUsecase, GetSkillsetUsecase |
| Presentation | 1 Cubit | HomeCubit |

**Features:** SkillsetCard, CourseCard with progress, HomeHeader

### 4.11 Achievement Module (15 files, 2.3K LOC)
**Purpose:** Display achievement badges

| Layer | Count | Files |
|-------|-------|-------|
| Domain | 1 use case | GetAchievenmentResponseUsecase |
| Presentation | 1 Cubit | AchievenmentCubit |

### 4.12 Setting Module (14 files, 1.5K LOC)
**Purpose:** App settings, language, theme configuration

| Layer | Count | Files |
|-------|-------|-------|
| Presentation | 3 Cubits | SettingCubit, ThemeCubit (HydratedCubit), LocaleCubit (HydratedCubit) |

**Features:** Language picker, theme switcher, premium info

### 4.13 Common Module (20 files, 2.4K LOC)
**Purpose:** Global state, shared entities, error pages

| Cubits | Purpose |
|--------|---------|
| ThemeCubit | Dark mode persistence |
| LocaleCubit | Language persistence |
| ConnectivityCubit | Internet connection monitor |
| DeeplinkCubit | Deep link navigation |
| PageCubit | Current page state |

**Error Pages:** ComingSoonPage, CommonErrorPage, NoInternetConnectionPage, ServerErrorPage

---

## 5. Module Dependency Graph

```
common (global state)
    ↓
auth (authentication)
    ↓
profile (user info)
    ↓
course → lesson → roleplay
    ↓
progress → achievement
    ↓
monetization (subscriptions)
    ↓
setting (theme, language)
    ↓
onboard → data_collect (onboarding)
    ↓
home (dashboard hub)
```

**Cross-Module Integration Points:**
- **ProgressCubit** extensively depends on: HomeCubit, CourseLessonCubit, CourseRoadmapCubit, UserCubit, RoleplayCubit
- **HomeCubit** orchestrates: ProgressCubit, ProfileCubit initialization
- **ProfileCubit** integrates: IapSubscriptionEntity (monetization)
- **OnboardCubit** populates: DataCollectCubit, IntroCubit (via AppDI.injector)

---

## 6. Code Generation Artifacts

All generated files follow naming pattern `*.g.dart`, `*.freezed.dart`, `*.graphql.dart`:

| Generator | Output | Files |
|-----------|--------|-------|
| freezed | `.freezed.dart`, `.g.dart` | All entities, states, models |
| retrofit | `*.g.dart` | API client methods |
| json_serializable | `.g.dart` | JSON serialization |
| injectable | `di.config.dart` | DI container |
| go_router_builder | `routes.g.dart` | Type-safe routes |
| graphql_codegen | `.graphql.dart` | GraphQL clients |
| flutter_gen | `assets.gen.dart` | Asset constants |
| slang | `l10n_*.g.dart` | Translations |

**Command to regenerate:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 7. Testing Structure

```
test/
├── unit/
│   ├── auth/
│   ├── course/
│   ├── lesson/
│   ├── roleplay/
│   ├── monetization/
│   ├── progress/
│   ├── profile/
│   ├── onboard/
│   ├── data_collect/
│   ├── home/
│   ├── achievement/
│   ├── setting/
│   └── common/
```

**Pattern:** `{target}_test.dart` mirrors feature structure
**Mock Strategy:** Inject mocked services and repositories

---

## 8. File Naming Conventions

| Item | Convention | Example |
|------|-----------|---------|
| Files | snake_case | `auth_service.dart` |
| Classes | PascalCase | `AuthService`, `LoginUseCase` |
| Cubits | `{Name}Cubit` | `CourseCubit`, `UserCubit` |
| BLoCs | `{Name}Bloc` | `AuthBloc` |
| Pages | `{Name}Page` | `LoginPage`, `CoursePage` |
| Widgets | `{Name}Widget` | `CourseCard`, `LessonCard` |
| Constants | SCREAMING_SNAKE_CASE | `API_BASE_URL`, `CACHE_KEY_USER` |

---

## 9. Key Metrics Summary

| Aspect | Count |
|--------|-------|
| **Total LOC** | ~86,000+ |
| **Dart Files** | 782 |
| **Feature Modules** | 13 |
| **Entities** | 50+ |
| **Use Cases** | 60+ |
| **Pages** | 40+ |
| **Cubits/BLoCs** | 35+ |
| **Widgets** | 200+ |
| **Services** | 15+ |

---

## 10. Quick File Location Reference

| Item | Path |
|------|------|
| DI Container | `lib/config/di/` |
| Services | `lib/config/services/` |
| Routes | `lib/config/routes/` |
| Theme | `lib/config/themes/` |
| Error Handling | `lib/core/base/error/` |
| Use Case Base | `lib/core/base/use_case/` |
| UI Components | `lib/core/utils/` |
| Feature Modules | `lib/src/{feature}/` |
| Localization | `lib/config/l10n/` or `assets/i18n/` |
| Constants | `lib/core/constants/manual/` |
| Tests | `test/unit/{feature}/` |
| Build Config | `.info/app/` |
| Environment Vars | `.env/.env.{flavor}` |

---

**Document Maintained By:** Architecture Team
**Next Review Date:** Mar 22, 2026
