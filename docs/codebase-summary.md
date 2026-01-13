# Meup Codebase Summary

**Total LOC:** ~140,000 lines across 785 Dart files
**Architecture:** Clean Architecture with 3-layer separation
**Platform:** Flutter 3.24.0+
**Last Updated:** 2026-01-13

## Directory Structure Overview

```
meup/
├── lib/
│   ├── main_dev.dart, main_stg.dart, main_prod.dart  # Entry points per flavor
│   ├── config/                    # ~14.5K LOC - App-wide configuration
│   │   ├── di/                    # Dependency injection (get_it + injectable)
│   │   ├── routes/                # Type-safe routing (go_router)
│   │   ├── themes/                # Material3 theming
│   │   ├── l10n/                  # Generated localization (slang)
│   │   ├── services/              # 22 app-level services
│   │   └── share/                 # Global state
│   ├── core/                      # ~14.5K LOC - Shared infrastructure
│   │   ├── base/                  # Base classes (UseCase, BLoC mixins, errors)
│   │   ├── constants/             # Generated and manual constants
│   │   ├── helpers/               # Extensions, navigation, logging, popups
│   │   └── utils/                 # UI components and utilities
│   └── src/                       # ~110K LOC - 13 feature modules
│       ├── auth/                  # ~6K LOC - Authentication
│       ├── lesson/                # ~22K LOC - Interactive exercises (largest)
│       ├── course/                # ~10K LOC - Course catalog
│       ├── roleplay/              # ~10K LOC - Conversation roleplay
│       ├── progress/              # ~8K LOC - Progress tracking
│       ├── common/                # ~28K LOC - Shared components
│       ├── monetization/          # ~6K LOC - In-app purchases
│       ├── profile/               # ~5K LOC - User profile
│       ├── onboard/               # ~5K LOC - Onboarding flow
│       ├── data_collect/          # ~4K LOC - User data collection
│       ├── home/                  # ~3K LOC - Home screen
│       ├── achievement/           # ~2K LOC - Gamification
│       └── setting/               # ~1K LOC - App settings
├── tools/                         # 69 shell scripts for builds, distribution, git
├── .info/                         # Centralized config (app.json, firebase.json, etc.)
├── test/                          # Unit and integration tests
└── assets/                        # Images, fonts, i18n YAML files
```

## Feature Modules Summary

### Module Size Distribution
| Module | LOC | Priority | Description |
|--------|-----|----------|-------------|
| Common | 28K | P0 | Shared infrastructure, GraphQL, connectivity, theme |
| Lesson | 22K | P0 | 6 exercise types, voice feedback, document viewer |
| Course | 10K | P0 | Catalog, roadmap, lesson list |
| Roleplay | 10K | P1 | Conversation scenarios with avatars |
| Progress | 8K | P1 | Granular tracking, analytics dashboard |
| Auth | 6K | P0 | Email, SSO (Google, Apple), token management |
| Monetization | 6K | P1 | IAP, subscriptions, verification |
| Profile | 5K | P1 | User management, file upload |
| Onboard | 5K | P1 | Multi-step wizard, motivation selection |
| Data Collect | 4K | P2 | Personalization data gathering |
| Home | 3K | P2 | Navigation hub, skillset browsing |
| Achievement | 2K | P2 | Badges, gamification |
| Setting | 1K | P2 | Language, theme, preferences |

### Clean Architecture Pattern (All Modules)

```
lib/src/<feature>/
├── <feature>.dart              # Barrel file exporting all parts
├── <feature>.freezed.dart      # Generated Freezed code
├── <feature>.g.dart            # Generated JSON serialization
├── domain/
│   ├── entities/               # Business models (@freezed)
│   ├── repositories/           # Repository interfaces (I<Name>Repository)
│   └── usecases/               # Business logic (@lazySingleton)
├── data/
│   ├── datasources/
│   │   ├── apis/              # REST API clients (@RestApi with Retrofit)
│   │   └── local/             # Local storage/cache
│   ├── models/                # DTOs with toEntity() methods
│   └── repositories/          # Repository implementations (@LazySingleton)
└── presentation/
    ├── cubits/ or blocs/      # State management (@lazySingleton)
    ├── pages/                 # Screen widgets
    └── widgets/               # Reusable UI components
```

## Technology Stack

### State Management
- **flutter_bloc 9.1.1:** BLoC pattern for complex flows
- **bloc 9.2.0:** Cubit pattern for simple state
- **hydrated_bloc 10.1.1:** Persistent state (theme, locale)
- **Mixins:** `CubitUseCaseHandlerMixin`, `BlocUseCaseHandlerMixin` for boilerplate reduction

### Networking
- **dio 5.9.0:** HTTP client with 3 named instances (app, AI service, third-party)
- **retrofit 4.9.2:** Type-safe REST API clients (code-generated)
- **graphql_flutter 5.2.1:** GraphQL queries and mutations
- **Functional Error Handling:** `fpdart` with `TaskEither<AppException, T>` pattern

### Dependency Injection
- **get_it 9.2.0:** Service locator
- **injectable 2.7.1:** Code generation for DI registration
- **Pattern:** `@LazySingleton`, `@factoryMethod`, named instances

### Navigation
- **go_router 17.0.1:** Declarative routing
- **go_router_builder 4.1.3:** Type-safe route generation
- **40+ routes** organized by feature with custom transitions

### Localization
- **slang_flutter 4.11.0:** Type-safe translations
- **3 languages:** English (base), Vietnamese, Chinese
- **Google Sheets integration** for translation workflow
- **13 module namespaces** for organized keys

### Firebase Suite
- **firebase_core 4.3.0:** Base SDK
- **firebase_auth 6.1.3:** Authentication (email, Google, Apple)
- **firebase_messaging 16.1.0:** Push notifications
- **firebase_crashlytics 5.0.6:** Crash reporting
- **firebase_analytics 12.1.0:** User analytics
- **firebase_remote_config 6.1.3:** Feature flags

### Monetization
- **in_app_purchase 3.2.3:** Cross-platform IAP
- **in_app_purchase_storekit 0.4.7:** iOS StoreKit
- **in_app_purchase_android 0.4.0+3:** Android Billing

### Analytics & Tracking
- **sentry_flutter 9.8.0:** Error monitoring
- **facebook_app_events 0.24.0:** Attribution tracking
- **app_tracking_transparency 2.0.6+1:** iOS ATT framework

### Code Generation
- **build_runner 2.10.4:** Build system
- **retrofit_generator 10.2.1:** API client generation
- **json_serializable 6.11.3:** JSON serialization
- **freezed 3.2.4:** Immutable models and states
- **injectable_generator 2.12.0:** DI code generation
- **graphql_codegen 3.0.0:** GraphQL type-safe queries
- **slang 4.11.1:** Localization code generation
- **flutter_gen_runner:** Asset reference generation

## Key Architectural Decisions

### 1. Functional Error Handling
**Decision:** Use `TaskEither<AppException, T>` from fpdart for all repository methods and use cases.

**Rationale:**
- Type-safe error propagation
- Eliminates try-catch boilerplate
- Railway-oriented programming
- Composable error flows

**Implementation:**
```dart
// Repository
TaskEither<AppException, User> login(LoginParams params) {
  return callApi(
    request: () => authApi.login(params),
    fromJson: User.fromJson,
  );
}

// UseCase
class LoginUseCase implements UseCaseWithParams<LoginParams, User> {
  TaskEither<AppException, User> call(LoginParams params) =>
    _repository.login(params);
}

// Cubit
await runUseCase<User>(
  useCase: () => _loginUseCase(params),
  onSuccess: (user) => emit(state.copyWith(user: user)),
);
```

### 2. Clean Architecture with Mixin-Based Network Layer
**Decision:** Separate domain, data, and presentation layers with mixin-based network request handlers.

**Rationale:**
- Testable business logic (pure domain entities)
- Mockable interfaces for unit testing
- Code reusability via mixins (`RestfulRequestHandlerMixin`, `GraphQLRequestHandlerMixin`)
- Framework independence

**Pattern:**
```dart
@LazySingleton(as: IAuthRepository)
class AuthRepository with RestfulRequestHandlerMixin {
  final AuthApi _authApi;

  TaskEither<AppException, AuthEntity> login(Map<String, dynamic> body) {
    return callApiWithTransform(
      apiCall: () => _authApi.login(body),
      transform: (response) => response.toEntity(),
    );
  }
}
```

### 3. Barrel File Export Pattern
**Decision:** Each feature module exports through a single barrel file using `part of`.

**Rationale:**
- Encapsulation (internal files not directly importable)
- Simplified imports for consumers
- Cohesive module structure
- Prevents circular dependencies

**Structure:**
```dart
// lib/src/auth/auth.dart
library auth;

part 'domain/entities/auth_entity.dart';
part 'domain/repositories/i_auth_repository.dart';
part 'data/repositories/auth_repository.dart';
// ... all module files

// External usage
import 'package:meup/src/auth/auth.dart';
```

### 4. Dual API Support (REST + GraphQL)
**Decision:** Support both REST and GraphQL simultaneously with abstracted network layer.

**Rationale:**
- Backend flexibility (gradual GraphQL migration)
- Feature-specific optimization (GraphQL for complex queries, REST for simple CRUD)
- Unified error handling
- Protocol-agnostic business logic

**Implementation:**
- REST via Dio + Retrofit with `RestfulRequestHandlerMixin`
- GraphQL via graphql_flutter with `GraphQLRequestHandlerMixin`
- Both return `TaskEither<AppException, T>` for consistency

### 5. Multi-Flavor Architecture
**Decision:** 3 build flavors (dev, stg, prod) with separate entry points and environment configs.

**Rationale:**
- Environment isolation (different APIs, Firebase projects)
- Safe testing without affecting production
- Feature flag testing in staging
- Simplified deployment pipeline

**Setup:**
- Entry points: `main_dev.dart`, `main_stg.dart`, `main_prod.dart`
- Env files: `.env/.env.{flavor}`
- Build command: `--dart-define-from-file=.env/.env.{flavor}`

### 6. UseCase Handler Mixins
**Decision:** Provide mixins (`CubitUseCaseHandlerMixin`, `BlocUseCaseHandlerMixin`) for executing use cases with automatic loading/error handling.

**Rationale:**
- Reduce boilerplate (80% less code in Cubits)
- Consistent loading state emission
- Automatic error handling with toast messages
- Standardized success/failure callbacks

**Migration:** Legacy methods (`executeUseCase`) → New methods (`runUseCase`)

## Config Directory (`lib/config/`)

### Dependency Injection (`di/`)
- **Framework:** get_it + injectable with code generation
- **Entry Point:** `AppDI.initializeDependencies()`
- **Modules:**
  - `NetworkModule`: 3 Dio instances (app, AI, third-party), GraphQL client
  - `CacheModule`: 4 cache managers (default, image, video, file)
  - `TrackingModule`: Composite tracking service (Firebase + Sentry)
  - `SupabaseModule`: Supabase client

### Routing (`routes/`)
- **40+ routes** organized by feature
- **Type-safe parameters** via go_router_builder
- **Custom transitions:** 14+ types (fade, slide, scale, flip, zoom, etc.)
- **Base Classes:** `BaseRouteData`, `BaseTransitionRouteData`
- **Shell Navigation:** Bottom nav with 3 tabs (home, course, profile)

### Themes (`themes/`)
- **Material3:** Light and dark themes
- **Color System:**
  - 67 M3 color tokens per theme
  - Custom brand colors (gradients, semantic colors)
  - Figma design system integration
- **Font:** Mulish
- **Dynamic Access:** `AppTheme` mixin (reactive via ThemeCubit)

### Services (`services/`)
22 app-level services organized by category:

**Networking:**
- `RestfulService`: 3 Dio clients with interceptors
- `GraphQLService`: Custom link chain with auth/error handling

**Analytics:**
- `CompositeTrackingService`: Multi-provider (Firebase + Sentry)
- `FirebaseAnalyticsService`, `SentryTrackingService`
- `AppTrackingService` (iOS ATT)

**Authentication:**
- `AuthService`: Firebase Auth + social login (Google, Apple)

**In-App Purchases:**
- `IapService`: Platform IAP with server-side verification

**Storage:**
- `CacheService`: Cache management
- `LocalStoreService`: Secure storage wrapper
- `HydratedService`: HydratedBloc persistence

**Device:**
- `DeviceInfoService`, `PackageInfoService`
- `MediaService`, `CameraService`

**Notifications:**
- `NotificationService`: FCM + AwesomeNotifications

**Miscellaneous:**
- `ConnectivityService`, `DeepLinkService`, `FileService`
- `FirebaseRemoteConfigService`, `RouteObserverService`

## Core Directory (`lib/core/`)

### Base Classes (`base/`)

**UseCase Interfaces:**
- `UseCaseWithParams<Params, Result>`: Returns `TaskEither<AppException, Result>`
- `UseCaseWithoutParams<Result>`: No parameters
- `BasePageBreakUseCase<Params, Result>`: Paginated use cases

**Error Handling:**
- `AppException`: Sealed class with 13 error types
  - Generic, Server, Connection, Database, Cache
  - NotFound, Unauthorized, InvalidInput, Unexpected
  - Forbidden, Pending, FromDioException, FromGraphQLError
- Automatic conversion from Dio/GraphQL errors

**BLoC/Cubit Mixins:**
- `CubitUseCaseHandlerMixin`: Execute use cases with loading/success/error states
  - New methods: `runUseCase`, `runUseCaseList`, `runUseCaseVoid`, `runUseCasePageBreak`
  - Legacy methods: `executeUseCase`, `executeListUseCase`, `executePageBreakUseCase`
- `BlocUseCaseHandlerMixin`: Event-driven variant

**Network Request Handlers:**
- `RestfulRequestHandlerMixin`: REST API calls with error handling, caching, retry
  - Methods: `callApi`, `callApiList`, `callApiPageBreak`, `callApiWithTransform`
- `GraphQLRequestHandlerMixin`: GraphQL queries/mutations with error handling
  - Methods: `callGraphQL`, `callGraphQLList`, `callGraphQLMutation`, `callGraphQLSubscription`

**Response Models:**
- `BaseResponse<T>`: Generic API response wrapper
- `BaseResponseList<T>`: List response wrapper
- `BasePageBreak<T>`: Pagination model with extensions (`isLastPage`, `nextPage`, `hasItems`)

**Request Models:**
- `PageBreakRequest<T>`: Pagination request (page, limit, orderBy, order, search, filter)

### Constants (`constants/`)

**Generated (`gen/`):**
- `assets.gen.dart`: Asset references (flutter_gen_runner)
- `fonts.gen.dart`: Font family constants

**Manual (`manual/`):**
- `endpoint.dart`: 50+ API endpoint constants
- `base_url.dart`: Environment URLs (dev, stg, prod)
- `cache_key.dart`, `local_store_key.dart`: Storage keys
- `tracking_key.dart`, `tracking_params.dart`: Analytics constants
- `in_app_key.dart`, `notification_key.dart`, etc.

### Helpers (`helpers/`)

**Extensions (`extension/`):**
- **String:** Validation (email, phone, URL, password), parsing, formatting, HTML handling
- **DateTime:** Formatting, relative time, comparison, manipulation
- **Number:** Currency, time, percentage, file size formatting
- **Object:** Null-safety helpers (`let`, `also`, `takeIf`)

**Popups (`popup/`):**
- `DMessage`: Toast/snackbar (success, error, warning, info)
- `DDialog`: Material dialogs (show, confirm, custom)
- `DOverlay`: Loading overlays with progress

**Navigation (`navigation/`):**
- `DNavigator` mixin: GoRouter helpers
- BuildContext extensions: `pop`, `push`, `pushNamed`, `goBack`

**Logging (`log/`):**
- `AppLogger`: Color-coded console logging (info, data, warning, error, fatal, trace)

### Utils (`utils/`)
UI components organized by category:
- `text/`: `AppText` (HTML support), `DText` (deprecated)
- `button/`: Custom button widgets
- `input/`: Form inputs, text fields
- `images/`: Image loading, caching
- `layouts/`: Layout helpers, responsive utilities
- `animation/`: Animation components
- `decoration/`, `navbar/`, `overlay/`, `select/`, `sliver/`, `svg/`, `timer/`, `video/`, `webview/`, `wrap/`

## Build System & Tooling

### Multi-Flavor Build Process
```
1. Select flavor (dev/stg/prod)
2. Load config from .info/app/*.json
3. Read env vars from .env/.env.<flavor>
4. Execute Flutter build:
   - --release
   - --flavor <flavor>
   - --dart-define-from-file=.env/.env.<flavor>
   - -t lib/main_<flavor>.dart
   - --obfuscate
   - --split-debug-info=.obfuscation
5. Auto-upload debug symbols to Firebase Crashlytics
6. (Optional) Distribute to Firebase App Distribution
```

### Build Commands
```bash
# Android
./tools/macos/build/build_apk.sh <flavor>           # APK
./tools/macos/build/build_appbundle.sh <flavor>     # App Bundle

# iOS (macOS only)
./tools/macos/build/build_ios.sh <flavor>           # App
./tools/macos/build/build_ipa.sh <flavor>           # IPA
```

### Code Generation
```bash
dart run build_runner build --delete-conflicting-outputs  # Generate all
dart run build_runner watch --delete-conflicting-outputs  # Watch mode
dart run build_runner clean                               # Clean
```

### Localization Workflow
```bash
tools/macos/localization/localization.sh pull  # Pull from Google Sheets
dart run slang                                 # Regenerate translations
```

### Tools Directory
69 shell scripts across macOS/Linux/Windows:
- `build/`: APK, App Bundle, iOS, IPA builds
- `config/`: Project setup, Firebase config, icon generation
- `distribution/`: Firebase/Play Store distribution, tester management
- `git/`: Branch creation, commit helpers, hooks
- `localization/`: Google Sheets integration
- `key/`: Keystore, PEM, SSH key generation

### CI/CD Pipeline (GitLab CI)
**Stages:** test → build → deploy

**Build Jobs:**
- `build:android:dev:apk` (develop branch)
- `build:android:stg:apk` (main, release/*)
- `build:android:prod:appbundle` (tags, prod/*)

**Deploy Jobs:**
- `deploy:firebase:dev` (Firebase App Distribution)
- `deploy:firebase:stg` (Firebase App Distribution)
- `deploy:playstore:prod` (Google Play Internal Track)

**Docker Image:** `cirrusci/flutter:3.24.0` with Android SDK 34

## Code Quality & Standards

### Linting
- Base: `package:flutter_lints/flutter.yaml`
- Line length: 180 characters
- Excludes: `*.g.dart`, `*.freezed.dart`, `*.graphql.dart`

### Testing
- Unit tests: `test/unit/` (mirrors feature structure)
- Integration tests: `test/integration/`
- Coverage target: 80% for business logic
- Pre-push hook runs tests

### Commit Message Format
```
<type>-<TICKET-ID>: <subject>

Types: feature, fix, refactor, style, docs, test, chore, perf
Example: feature-MEUP-123: Add social login functionality
```

### Branch Naming
```
<type>/<TICKET-ID>-<description>

Example: feature/MEUP-123-add-login
```

## Performance Characteristics

### Metrics (Mid-Range Devices)
- **Cold Start:** \<3s
- **API Response P95:** \<500ms
- **Voice Feedback:** \<3s
- **Frame Rate:** 60fps sustained
- **Memory:** \<200MB baseline, \<400MB peak

### Optimizations
- Code obfuscation in release builds
- Tree shaking icons (`--no-tree-shake-icons` opt-out)
- Image/video/file caching with TTL
- Lazy loading for non-base locales
- HydratedBloc for persistent state (reduces API calls)

## Security

### Authentication
- OAuth 2.0 + JWT
- 15-min access token TTL
- Auto token refresh
- Secure storage for tokens (flutter_secure_storage)

### Data Protection
- HTTPS-only communication
- Server-side IAP receipt validation
- Firebase Auth for identity management
- GDPR/CCPA compliance

### Build Security
- Code obfuscation in release
- Debug symbols upload to Crashlytics
- Keystore/provisioning not committed to Git
- Environment variables in CI/CD

## Key Statistics

| Metric | Count |
|--------|-------|
| Total LOC | ~140K |
| Dart Files | 785 |
| Feature Modules | 13 |
| Domain Entities | 60+ |
| Repository Interfaces | 15 |
| Use Cases | 60+ |
| API Clients | 20 |
| Cubits/Blocs | 33 |
| Pages/Screens | 40+ |
| Shell Scripts | 69 |
| Routes | 40+ |
| Supported Languages | 3 |
| Platforms | iOS + Android |

## Dependencies Summary

### Core Dependencies (20+)
- **State:** flutter_bloc, bloc, hydrated_bloc
- **Network:** dio, retrofit, graphql_flutter
- **Navigation:** go_router
- **DI:** get_it, injectable
- **Localization:** slang_flutter, intl
- **Firebase:** core, auth, messaging, crashlytics, analytics, remote_config
- **Monetization:** in_app_purchase (iOS + Android)
- **Tracking:** sentry_flutter, facebook_app_events

### Dev Dependencies (10+)
- **Code Gen:** build_runner, retrofit_generator, json_serializable, freezed, injectable_generator, go_router_builder, graphql_codegen, slang, flutter_gen_runner
- **Testing:** mockito, flutter_test
- **Flavors:** flutter_flavorizr

## Unresolved Technical Debt

1. **UseCase Handler Migration:** Complete transition from `executeUseCase` → `runUseCase`
2. **Widget Consolidation:** Migrate `DText` → `AppText` across all modules
3. **Large File Optimization:** Split lesson module files \>200 LOC
4. **Common Module Size:** Consider splitting 28K LOC into domain/infrastructure/ui
5. **GraphQL Schema Documentation:** Document handfeeling and other custom schemas
6. **Setting Module Data Layer:** Evaluate if remote settings management needed

## Next Steps for Developers

### Onboarding
1. Read `docs/project-overview-pdr.md` for product context
2. Read `docs/system-architecture.md` for technical architecture
3. Read `docs/code-standards.md` for development guidelines
4. Run `tools/macos/config/setup_project.sh` to bootstrap environment

### Adding a New Feature
1. Create feature branch: `./tools/macos/git/feature.sh MEUP-XXX "description"`
2. Create module in `lib/src/<feature>/` following Clean Architecture
3. Implement domain → data → presentation layers
4. Register in DI (`@LazySingleton`, `@injectable`)
5. Add routes in `lib/config/routes/data/`
6. Generate code: `dart run build_runner build --delete-conflicting-outputs`
7. Write tests in `test/unit/<feature>/`
8. Commit: `feature-MEUP-XXX: Add feature description`

### Running the App
```bash
# Generate code
dart run build_runner build --delete-conflicting-outputs

# Pull translations
tools/macos/localization/localization.sh pull
dart run slang

# Run flavor
flutter run --flavor dev -t lib/main_dev.dart
```
