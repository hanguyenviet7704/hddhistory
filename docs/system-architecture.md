# Meup System Architecture

**Version:** 1.0
**Last Updated:** 2026-01-13
**Architecture Pattern:** Clean Architecture with Functional Error Handling
**Platform:** Flutter 3.24.0+, iOS 12.0+, Android API 21+

## Architecture Overview

Meup uses Clean Architecture with three distinct layers per feature module, ensuring separation of concerns, testability, and independence from frameworks.

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                   │
│  Pages, Widgets, BLoC/Cubit (UI, State Management)      │
└───────────────────────┬─────────────────────────────────┘
                        │ Dependencies flow inward
                        ↓
┌─────────────────────────────────────────────────────────┐
│                     Domain Layer                         │
│  Entities, Repository Interfaces, Use Cases (Pure)       │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ↓
┌─────────────────────────────────────────────────────────┐
│                      Data Layer                          │
│  Models, API Clients, Repository Implementations         │
└─────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

**Presentation Layer:**
- User interface rendering
- User input handling
- State management (BLoC/Cubit)
- Navigation
- Dependency: Domain layer only

**Domain Layer:**
- Business logic (Use Cases)
- Business entities
- Repository interfaces (contracts)
- No dependencies on external libraries (except freezed)

**Data Layer:**
- API communication (REST, GraphQL)
- Local storage (cache, database)
- Repository implementations
- Data transformation (Model ↔ Entity)
- Dependency: Domain layer only

## Dependency Injection

### Framework: get_it + injectable

**Setup:**
```dart
// lib/config/di/di.dart
final getIt = GetIt.instance;

@InjectableInit(generateForDir: [
  'lib/config/di',
  'lib/config/services',
  'lib/src/**/data/datasources/*',
  'lib/src/**/data/repositories',
  'lib/src/**/domain/repositories',
  'lib/src/**/domain/usecases',
  'lib/src/**/presentation/blocs',
  'lib/src/**/presentation/cubits',
])
void configureDependencies() => getIt.init();
```

### DI Modules

**NetworkModule** (`network_di.dart`):
```dart
@module
abstract class NetworkModule {
  @Named(DIKey.appDio)
  @lazySingleton
  Dio appDio(IRestfulService service) { ... }

  @Named(DIKey.aiDio)
  @lazySingleton
  Dio aiDio(IRestfulService service) { ... }

  @Named(DIKey.appGraphql)
  @lazySingleton
  GraphQLClient graphqlClient(IGraphQLService service) { ... }
}
```

**Named Instances:**
- `DIKey.appDio`: Main API Dio client
- `DIKey.aiDio`: AI service Dio client (streaming support)
- `DIKey.thirdPartyDio`: Third-party integrations
- `DIKey.appGraphql`: GraphQL client

**CacheModule** (`cache_di.dart`):
```dart
@Named(DIKey.imageCacheManager): 500 images, 7-day stale
@Named(DIKey.videoCacheManager): 50 videos, 7-day stale
@Named(DIKey.fileCacheManager): 200 files, 14-day stale
```

**TrackingModule** (`tracking_di.dart`):
```dart
@lazySingleton
BaseTrackingService trackingService() => CompositeTrackingService([
  FirebaseAnalyticsService(),
  SentryTrackingService(),
]);
```

### Registration Patterns

```dart
// Singleton
@lazySingleton
class AuthCubit { ... }

// Interface implementation
@LazySingleton(as: IAuthRepository)
class AuthRepository implements IAuthRepository { ... }

// Factory (new instance per call)
@injectable
class LoginUseCase { ... }

// Named instance
@Named('customName')
@singleton
SomeService customService() { ... }
```

## Routing System

### Framework: go_router + go_router_builder

**Setup:**
```dart
// lib/config/routes/base/app_pages.dart
final routes = GoRouter(
  navigatorKey: AppConfig.instance.rootNaviKey,
  initialLocation: RoutePath.splash,
  routes: $appRoutes,
  debugLogDiagnostics: true,
);
```

### Route Organization (40+ routes)

```
routes/
├── base/
│   ├── app_pages.dart              # GoRouter instance
│   ├── app_routes.dart             # Route constants (RoutePath, RouteNamed)
│   └── app_routes_config.dart      # Base classes, transitions
└── data/
    ├── routes_auth_data.dart       # Auth routes (login, register, etc.)
    ├── routes_onboard_data.dart    # Onboarding flow
    ├── routes_common_data.dart     # Splash, web view, errors
    ├── routes_shell.dart           # Bottom nav shell
    ├── routes_shell_home_data.dart
    ├── routes_shell_course_data.dart
    └── routes_shell_setting_data.dart
```

### Type-Safe Routes

```dart
@TypedGoRoute<LoginRoute>(
  path: RoutePath.login,
  name: RouteNamed.login,
)
class LoginRoute extends BaseTransitionRouteData {
  final bool isRegister;

  const LoginRoute({this.isRegister = false});

  @override
  RouteTransitionConfig get transitionConfig =>
    RouteTransitionConfig.slideFromRight;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) {
    return const LoginPage();
  }
}
```

### Custom Transitions (14+ types)

**Available:**
- Basic: fade, slide (up/down/left/right), scale, rotation
- Material Design: fadeThrough, sharedAxisX/Y/Z
- Advanced: zoom, slideScale, fadeSlide, flip (3D), size

**Presets:**
- `slideFromRight`, `slideFromBottom`, `slideFromTop`
- `flipHorizontal`, `flipVertical`
- `zoomIn`, `fadeIn`

## State Management

### BLoC Pattern Architecture

```
Widget → Event → BLoC/Cubit → UseCase → Repository → API
           ↓                      ↓
         State ← Transform ← TaskEither<Error, Data>
```

### BLoC vs Cubit

**Use BLoC when:**
- Complex event-driven flows (e.g., authentication)
- Multiple events trigger same state
- Event logging/replay needed

**Use Cubit when:**
- Simple state transformations (e.g., course list)
- Direct state mutation sufficient
- No complex event handling

### State Class Pattern

```dart
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(AuthEntity auth) = _Authenticated;
  const factory AuthState.error(AppException error) = _Error;
}
```

### Cubit Implementation with Mixin

```dart
@lazySingleton
class AuthCubit extends Cubit<AuthState>
    with CubitUseCaseHandlerMixin<AuthState> {
  final LoginUseCase _loginUseCase;

  AuthCubit(this._loginUseCase) : super(const AuthState.initial());

  Future<void> login(LoginParams params) async {
    await runUseCase<AuthEntity>(
      useCase: () => _loginUseCase(params),
      onSuccess: (auth) => emit(AuthState.authenticated(auth)),
      // onError handled automatically by mixin
    );
  }
}
```

### HydratedBloc for Persistence

**Used for:**
- Theme preferences (ThemeCubit, ThemeModeCubit)
- Locale selection (LocaleCubit)
- User settings

```dart
class LocaleCubit extends HydratedCubit<Locale> {
  LocaleCubit() : super(const Locale('en'));

  void setLocale(Locale locale) => emit(locale);

  @override
  Locale? fromJson(Map<String, dynamic> json) =>
    Locale(json['languageCode'] as String);

  @override
  Map<String, dynamic>? toJson(Locale state) =>
    {'languageCode': state.languageCode};
}
```

## Networking Architecture

### Dual API Support

**REST API (Dio + Retrofit):**
- Primary for CRUD operations
- 3 Dio instances (app, AI service, third-party)
- Retrofit code generation for type safety

**GraphQL (graphql_flutter):**
- For complex queries (roadmap, nested data)
- Subscriptions support
- Type-safe query generation

### REST Implementation

**API Client (Retrofit):**
```dart
@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String baseUrl}) = _AuthApi;

  @POST('/api/v1/users/login')
  Future<BaseResponse<AuthModel>> login(@Body() Map<String, dynamic> body);

  @POST('/api/v1/users/register')
  Future<BaseResponse<AuthModel>> register(@Body() Map<String, dynamic> body);
}
```

**Repository with Mixin:**
```dart
@LazySingleton(as: IAuthRepository)
class AuthRepository with RestfulRequestHandlerMixin
    implements IAuthRepository {
  final AuthApi _authApi;

  AuthRepository(this._authApi);

  @override
  TaskEither<AppException, AuthEntity> login(Map<String, dynamic> body) {
    return callApiWithTransform(
      apiCall: () => _authApi.login(body),
      transform: (response) => response.data?.toEntity() ?? AuthEntity(),
    );
  }
}
```

### Mixin Methods

**RestfulRequestHandlerMixin:** `callApi<T>()`, `callApiList<T>()`, `callApiPageBreak<T>()`, `callApiWithTransform<T, R>()`

**GraphQLRequestHandlerMixin:** `callGraphQL<T>()`, `callGraphQLList<T>()`, `callGraphQLMutation<T>()`, `callGraphQLSubscription<T>()`

### Interceptor Chain

**REST Interceptors:**
1. `AppInterceptor`: Auth token injection, retry logic
2. `CustomInterceptor`: Request/response transformation
3. Logging interceptor (debug mode)

**GraphQL Interceptors:**
1. `AppGraphQLInterceptor`: Auth, error handling
2. `CustomHeaderInterceptor`: Dynamic headers
3. `PerformanceInterceptor`: Operation timing

### Error Handling

```dart
// All repository methods return TaskEither
TaskEither<AppException, User> getUser(String id) {
  return callApi(
    request: () => userApi.getUser(id),
    fromJson: User.fromJson,
  );
  // Automatically converts Dio errors to AppException
}

// Cubit handles success/error
await runUseCase<User>(
  useCase: () => getUserUseCase(userId),
  onSuccess: (user) => emit(state.copyWith(user: user)),
  // Error toast shown automatically
);
```

## Services Architecture

### 22 App-Level Services

**Categories:**

**1. Networking (2):**
- `RestfulService`: Dio client factory (3 instances)
- `GraphQLService`: GraphQL client factory

**2. Analytics & Tracking (5):**
- `CompositeTrackingService`: Multi-provider aggregator
- `FirebaseAnalyticsService`: Firebase Analytics
- `SentryTrackingService`: Sentry error tracking
- `AppTrackingService`: iOS ATT wrapper
- `NoOpTrackingService`: Disabled state

**3. Authentication (1):**
- `AuthService`: Firebase Auth + social login

**4. In-App Purchases (1):**
- `IapService`: Platform IAP with server verification

**5. Storage (3):**
- `CacheService`: Cache management
- `LocalStoreService`: Secure storage wrapper
- `HydratedService`: HydratedBloc persistence

**6. Device (4):**
- `DeviceInfoService`: Platform/device info
- `PackageInfoService`: App version info
- `MediaService`: Gallery/camera access
- `CameraService`: Camera functionality

**7. Notifications (1):**
- `NotificationService`: FCM + AwesomeNotifications

**8. Miscellaneous (5):**
- `ConnectivityService`: Network status
- `DeepLinkService`: AppLinks deep linking
- `FileService`: File picker/management
- `FirebaseRemoteConfigService`: Feature flags
- `RouteObserverService`: Route lifecycle tracking

### Service Pattern: Composite

```dart
abstract interface class ITrackingService {
  Future<void> trackEvent(String name, Map<String, dynamic> params);
  Future<void> trackScreenView(String name);
  Future<void> setUserId(String id);
}

@lazySingleton
class CompositeTrackingService implements ITrackingService {
  final List<ITrackingService> _services;

  CompositeTrackingService(this._services);

  @override
  Future<void> trackEvent(String name, Map<String, dynamic> params) async {
    for (final service in _services) {
      await service.trackEvent(name, params);
    }
  }
}
```

## Theme System

### Material 3 Implementation

**Color System:**
- 67 M3 color tokens per theme (light/dark)
- Custom brand colors (gradients, semantic colors)
- Figma design system integration

**Themes:**
```dart
// lib/config/themes/material_theme.dart
class AppThemeMaterial {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: AppFont.mulish,
    colorScheme: ColorScheme.light(
      primary: Color(0xFFF7704B),
      // ... 66 more color tokens
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFFFFB5A1),
      // ... 66 more color tokens
    ),
  );
}
```

**Dynamic Access:**
```dart
mixin AppTheme {
  static final _theme = AppConfig.instance.context!
    .watch<ThemeCubit>().state.themeMaterial;

  static Color get primaryColor => _theme.colorScheme.primary;
  static TextTheme get textTheme => _theme.textTheme;
}
```

## Localization

### Framework: slang

**Workflow:**
1. Translations in Google Sheets (13 module tabs)
2. Pull to YAML: `tools/macos/localization/localization.sh pull`
3. Generate Dart: `dart run slang`
4. Output: `lib/config/l10n/l10n.g.dart`

**Structure:**
```
assets/i18n/
├── en/
│   ├── auth.yaml
│   ├── course.yaml
│   ├── lesson.yaml
│   └── ... (13 modules)
├── vi/
└── zh/
```

**Usage:**
```dart
import 'package:meup/config/l10n/l10n.dart';

Text(t.auth.loginButton);        // English: "Sign In"
Text(t.course.allCourses);       // Vietnamese: "Tất cả khóa học"
Text(t.lesson.complete);         // Chinese: "完成"
```

**Features:**
- Module-based namespaces
- Lazy loading for non-base locales
- camelCase keys
- Dart string interpolation
- Pluralization support

## Build System

### Multi-Flavor Architecture

**3 Flavors:**
- `dev`: Development (Firebase dev project)
- `stg`: Staging (Firebase stg project)
- `prod`: Production (Firebase prod project)

**Entry Points:**
```
lib/main_dev.dart   → .env/.env.dev   → Firebase dev config
lib/main_stg.dart   → .env/.env.stg   → Firebase stg config
lib/main_prod.dart  → .env/.env.prod  → Firebase prod config
```

### Build Process

```bash
# Android APK
flutter build apk \
  --release \
  --flavor dev \
  --dart-define-from-file=.env/.env.dev \
  -t lib/main_dev.dart \
  --obfuscate \
  --split-debug-info=.obfuscation

# iOS IPA
flutter build ipa \
  --release \
  --flavor prod \
  --dart-define-from-file=.env/.env.prod \
  -t lib/main_prod.dart \
  --obfuscate \
  --split-debug-info=.obfuscation
```

### Configuration System (.info/)

**Centralized Config:**
```
.info/
├── app/
│   ├── app.json              # App metadata, versions, package names
│   ├── firebase.json         # Firebase projects/apps per flavor
│   ├── build.json            # Build settings, optimizations
│   ├── localization.json     # Google Sheets config
│   └── paths.json            # Project paths
├── distribution/
│   ├── tester_list.txt       # Beta testers
│   ├── tester_group.txt      # Distribution groups
│   └── release_note.txt      # Release notes template
└── key/
    ├── AuthKey_*.p8          # App Store Connect API key
    └── multilang_key.json    # Google Sheets service account
```

### Code Generation

**Generators:**
- `retrofit_generator`: API clients
- `json_serializable`: JSON serialization
- `freezed`: Immutable classes
- `injectable_generator`: DI registration
- `go_router_builder`: Type-safe routes
- `graphql_codegen`: GraphQL queries
- `flutter_gen_runner`: Asset references
- `slang_build_runner`: Localization

**Command:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

## CI/CD Pipeline

### GitLab CI Stages

**1. Test:**
- `flutter analyze`
- `flutter test`

**2. Build:**
- `build:android:dev:apk` (develop branch)
- `build:android:stg:apk` (main, release/*)
- `build:android:prod:appbundle` (tags, prod/*)

**3. Deploy:**
- `deploy:firebase:dev` (Firebase App Distribution)
- `deploy:firebase:stg` (Firebase App Distribution)
- `deploy:playstore:prod` (Google Play Internal Track)

### Docker Image

```dockerfile
FROM cirrusci/flutter:3.24.0
RUN apt-get update && apt-get install -y openjdk-17-jdk
ENV ANDROID_SDK_VERSION=34
ENV ANDROID_BUILD_TOOLS_VERSION=30.0.3
```

### Environment Variables

```
FIREBASE_TOKEN
FIREBASE_ANDROID_APP_ID_DEV/STG/PROD
ANDROID_KEYSTORE_BASE64
ANDROID_KEY_ALIAS
ANDROID_STORE_PASSWORD
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
```

## Security Architecture

### Authentication Flow

```
User → Firebase Auth → JWT Token → Secure Storage
  ↓
API Request → Interceptor (inject token) → Backend
  ↓
401 Response → Refresh Token → New JWT → Retry Request
```

**Token Management:**
- Access token: 15-min TTL
- Refresh token: 30-day TTL
- Stored in `flutter_secure_storage`
- Auto-refresh on 401

### Data Protection

**At Rest:**
- Sensitive data in `flutter_secure_storage` (iOS Keychain, Android KeyStore)
- HydratedBloc for non-sensitive persistent state
- Cache with TTL and size limits

**In Transit:**
- HTTPS-only (no HTTP fallback)
- Certificate pinning (future enhancement)
- Request signing for critical operations

### IAP Security

```
Platform IAP → Purchase → App → Backend Verification → Grant Access
                 ↓
          Transaction ID Cache (prevent duplicates)
```

## Performance Optimizations

**Build:** Obfuscation, tree shaking icons, minify, shrink resources

**Widget:** `const` constructors, `ListView.builder`, `CachedNetworkImage`

**Network:** Caching (7-14 day TTL), pagination (20 items/page), retry with exponential backoff

**Memory:** Image cache (500/100MB), video cache (50/500MB), file cache (200/200MB), controller disposal

## Monitoring & Analytics

### Error Tracking

**Sentry:**
- Automatic crash reporting
- Breadcrumbs for user actions
- Environment tags (dev/stg/prod)
- Release versioning

**Firebase Crashlytics:**
- Fatal crashes
- Non-fatal errors
- Custom keys (userId, courseId)
- Debug symbol upload

### Analytics Events

**Firebase Analytics:**
- Screen views (automatic)
- User actions (button clicks, course enrollment)
- Conversion funnels (onboarding, subscription)
- User properties (subscription tier, language)

**Tracking Pattern:**
```dart
final tracking = getIt<BaseTrackingService>();
tracking.trackEvent('course_enrolled', {
  'course_id': courseId,
  'course_name': courseName,
  'source': 'home_screen',
});
```

## Scalability Considerations

**Modular Architecture:** 13 independent feature modules, can extract to packages, files \<200 LOC

**Backend:** Pagination for all lists, caching with ETags, rate limiting, GraphQL for complex queries

**Local Storage:** Cache with LRU eviction, HydratedBloc for small state, future: Isar/Drift for large datasets

## Deployment Architecture

### Release Flow

```
feature/MEUP-123 → develop → staging → main → production
                      ↓         ↓        ↓
                    Firebase  Firebase  Play Store
                    (dev)     (stg)     App Store
```

### Distribution Channels

**Firebase App Distribution:**
- Dev builds: Internal testers
- Staging builds: QA team + stakeholders
- Manual distribution via shell scripts

**Google Play:**
- Internal track: Pre-release testing
- Beta track: Public beta (opt-in)
- Production track: General availability

**App Store:**
- TestFlight: Beta testing
- Production: General availability

## Architecture Decision Records

### ADR-001: TaskEither for Error Handling
**Decision:** Use fpdart's `TaskEither<AppException, T>` for all repository methods and use cases.
**Rationale:** Type-safe error propagation, composable flows, eliminates try-catch boilerplate.
**Status:** Accepted, actively enforced.

### ADR-002: Barrel File Exports
**Decision:** Each feature module exports through single library file using `part of`.
**Rationale:** Encapsulation, simplified imports, prevents circular dependencies.
**Status:** Accepted, implemented across all modules.

### ADR-003: Dual REST + GraphQL Support
**Decision:** Support both REST (Dio/Retrofit) and GraphQL simultaneously.
**Rationale:** Backend flexibility, feature-specific optimization, gradual migration.
**Status:** Accepted, both protocols in production.

### ADR-004: UseCase Handler Mixins
**Decision:** Provide mixins for executing use cases with automatic loading/error handling.
**Rationale:** Reduce boilerplate (80% less code), consistent UX, standardized error handling.
**Status:** Accepted, migration from legacy methods in progress.

## Unresolved Architecture Questions

1. **Database Layer:** Evaluate Isar vs Drift for local relational storage (currently using HydratedBloc + cache).
2. **Offline-First:** Consider implementing offline-first architecture with sync queue.
3. **Feature Flags:** Evaluate dedicated feature flag service vs Firebase Remote Config.
4. **Common Module Split:** Consider splitting 28K LOC into domain/infrastructure/ui submodules.
5. **Certificate Pinning:** Evaluate necessity and impact on maintenance.

## Summary

Meup's architecture prioritizes:
- **Testability:** Clean separation enables comprehensive unit/integration tests
- **Maintainability:** Consistent patterns reduce cognitive load
- **Scalability:** Modular design supports feature growth
- **Quality:** Automated checks and functional error handling catch issues early
- **Developer Productivity:** Code generation and mixins reduce boilerplate
