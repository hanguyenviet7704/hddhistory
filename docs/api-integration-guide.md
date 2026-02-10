# API Integration Guide

**Last Updated:** Feb 10, 2026
**Related:** [System Architecture](./system-architecture.md)

---

## 1. REST API: Retrofit + Dio Pattern

```dart
// 1. Define API interface (Retrofit)
@RestApi(baseUrl: 'https://api.meup.com')
abstract class CourseApi {
  factory CourseApi(Dio dio) = _CourseApi;

  @GET('/courses')
  Future<BaseResponseList<CourseModel>> getCourses(
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @GET('/courses/{id}')
  Future<BaseResponse<CourseModel>> getCourse(@Path('id') String id);

  @POST('/courses')
  Future<BaseResponse<CourseModel>> createCourse(@Body() CourseModel course);
}

// 2. Response wrapper (core/base/responses/)
@freezed
class BaseResponse<T> with _$BaseResponse<T> {
  const factory BaseResponse({
    required bool success,
    required String message,
    required T data,
  }) = _BaseResponse;

  factory BaseResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) => _$BaseResponseFromJson(json, fromJsonT);
}

// 3. DI Setup (config/di/network_di.dart)
@LazySingleton()
CourseApi provideCourseApi(Dio dio) => CourseApi(dio);

// 4. Remote Data Source
class CourseRemoteDataSource {
  final CourseApi _api;
  CourseRemoteDataSource(this._api);

  Future<List<CourseModel>> getCourses(PageBreakRequest request) async {
    final response = await _api.getCourses(request.currentPage, request.itemsPerPage);
    return response.data;
  }
}

// 5. Repository Implementation
class CourseRepositoryImpl implements CourseRepository {
  final CourseRemoteDataSource _remoteDataSource;

  @override
  TaskEither<AppException, List<CourseEntity>> getCourses(PageBreakRequest request) {
    return TaskEither.tryCatch(
      () async {
        final models = await _remoteDataSource.getCourses(request);
        return models.map((m) => m.toEntity()).toList();
      },
      (error, stackTrace) => AppException.fromDioException(error),
    );
  }
}
```

### Network Interceptors

```dart
class CustomInterceptor extends BaseInterceptor {
  final AuthService _authService;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _authService.getToken();
    options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _authService.refreshToken().then((_) {
        // Retry request with new token
      });
    }
    handler.next(err);
  }
}
```

---

## 2. Database & Local Storage Strategy

### Hierarchical Persistence

```
CACHE HIERARCHY (by TTL and update frequency)
├─ HydratedBloc (Real-time): Theme, Locale, Auth token
│  └─ File-based persistence, immediate updates
├─ SharedPreferences (Session): User preferences, last action
│  └─ Key-value store, app lifetime
├─ REST API Cache (Network): Courses, lessons, progress
│  └─ Manual cache invalidation or TTL
└─ Database (Planned): User data, offline-first content
   └─ SQLite / Hive when offline-first needed
```

### HydratedBloc Example

```dart
class UserCubit extends HydratedCubit<UserEntity?> {
  UserCubit() : super(null);

  @override
  UserEntity? fromJson(Map<String, dynamic> json) => UserEntity.fromJson(json);

  @override
  Map<String, dynamic>? toJson(UserEntity? state) => state?.toJson();
}

// Usage
await AppDI.initializeDependencies();  // Loads persisted user
final user = getIt<UserCubit>().state;  // Restored from cache
```

### Cache Invalidation Strategy

```dart
// 1. Event-driven: Invalidate on success
void _onCourseUpdated(CourseUpdatedEvent event) {
  _cacheService.remove(CacheKey.courses);
  add(LoadCoursesEvent());
}

// 2. TTL-based: Check cache age
Future<List<CourseEntity>> getCourses() async {
  final cached = _cacheService.get<List<CourseEntity>>(key);
  if (cached != null && !_isCacheExpired(key)) return cached;
  return _remoteDataSource.getCourses();
}

// 3. Forced refresh: User-triggered
void refreshCourses() {
  _cacheService.remove(CacheKey.courses);
  loadCourses();
}
```

---

## 3. Authentication & Authorization Flow

### Multi-Step Auth Architecture

```
1. SIGNUP/LOGIN
   ├─ User enters credentials
   ├─ API endpoint validates
   ├─ Response: {accessToken, refreshToken, user}
   └─ Tokens stored in HydratedBloc

2. TOKEN STORAGE (HydratedCubit)
   ├─ UserCubit persists user entity
   ├─ AuthTokenCubit persists tokens
   └─ Automatically restored on app restart

3. AUTHENTICATED REQUESTS
   ├─ CustomInterceptor injects Authorization header
   ├─ All API requests include Bearer token
   └─ 401 responses trigger token refresh

4. TOKEN REFRESH (Automatic)
   ├─ API returns 401 (token expired)
   ├─ CustomInterceptor catches 401
   ├─ Calls RefreshTokenUseCase
   ├─ Obtains new accessToken
   ├─ Retries original request
   └─ Updates persisted token

5. LOGOUT
   ├─ LogoutUseCase called
   ├─ Clear user state + auth tokens
   ├─ Navigate to LoginPage
   └─ All cubits reset
```

### OAuth Flow (Google/Apple)

```
1. USER TAPS "Sign in with Google"
   ├─ Native Google Sign-In SDK opens
   └─ User grants consent

2. RECEIVE ID TOKEN
   ├─ Google returns idToken
   └─ Passed to backend

3. BACKEND VALIDATION
   ├─ Backend verifies Google idToken
   ├─ Creates/fetches user record
   └─ Returns accessToken + user

4. APP STATE UPDATE
   ├─ UserCubit.setState(user)
   ├─ Navigate to home
   └─ All requests now authenticated
```

---

## 4. Feature Module Dependency Injection

### DI Registration Pattern

```dart
// config/di/app_di_config.dart
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: false,
)
void configureDependencies() {
  // Scans all @injectable-decorated classes
}

// Usage
await AppDI.initializeDependencies();
final useCase = getIt<GetCoursesUseCase>();
```

### Scopes

| Scope | Lifetime | Example |
|-------|----------|---------|
| **@LazySingleton** | App lifetime (created once, on first use) | Repositories, Services |
| **@Singleton** | App lifetime (created immediately) | DI bootstrap services |
| **@factoryMethod** | New instance each call | Temp objects, per-request |
| **@env** (conditional) | Environment-dependent registration | Mock vs Real service |

### Example Registration

```dart
// Repository
@LazySingleton()
class CourseRepositoryImpl implements CourseRepository {
  final CourseRemoteDataSource _remoteDataSource;
  CourseRepositoryImpl(this._remoteDataSource);
}

// Use Case
@LazySingleton()
class GetCoursesUseCase {
  final CourseRepository _repository;
  GetCoursesUseCase(this._repository);
}

// Cubit (factory, new instance per page)
@factoryMethod
CourseCubit providesCourseCubit(GetCoursesUseCase useCase) => CourseCubit(useCase);
```

---

## 4.5 Remote Configuration Strategy

**Purpose:** Centralize feature toggles, version requirements, and business logic rules.

```dart
// Access remote config
final remoteConfig = getIt<IRemoteConfigService>();

// Check app version requirements
final appVersion = remoteConfig.appVersionConfig;
if (appVersion.forceUserUpdate) {
  showForceUpdateDialog();
}

// Check course/lesson configurations
final courseConfig = remoteConfig.courseConfig;
if (!courseConfig.enable) {
  showCourseLocked();
}

// Check paywall settings
final paywallConfig = remoteConfig.paywallConfig;
final lessonLocked = paywallConfig.enableLessonLock &&
                     lessonNumber >= paywallConfig.lessonLock;
```

**Entities Provided:**
- **AppVersionConfigEntity** - Version checks (forceUserUpdate, latestAndroidVersion, latestIosVersion)
- **CourseConfigEntity** - Course feature toggles (enable, finishOptionalKp)
- **PaywallConfigEntity** - Monetization rules (enableLessonLock, lessonLock limit)

**Storage:** Firebase Remote Config with JSON fallback defaults
**Update Frequency:** Fetched on app launch, cached locally

---

## 5. Analytics & Tracking Architecture

### Multi-Provider Tracking

```
                    AppTrackingService (ITrackingService)
                            ↓
        ┌───────────────────┼───────────────────┐
        ↓                   ↓                   ↓
   FirebaseAnalytics    SentryTracking     CustomTracking
    (events, users)    (exceptions,perf)   (custom events)
```

### Event Tracking Pattern

**170+ events organized by category:** onboarding, course, lesson, roleplay, progress, settings, payments

```dart
// Onboarding events (obd_* prefix)
trackEvent(TrackingKey.obdNameContinue, parameters: {...});

// Course events (course_select_*, roadmap_*, lesson_* prefix)
trackEvent(TrackingKey.roadmapItemClick, parameters: {
  'skill_id': skillId,
  'course_id': courseId,
  'course_name': courseName,
});

// Lesson/Keypoint events (keypoint_exercise_* prefix)
trackEvent(TrackingKey.keypointExerciseCheckClick, parameters: {
  ..._keypointParams(trackingData),
  'exercise_type': 'multiple_choice',
  'is_correct': true,
});

// Roleplay events (roleplay_* prefix)
trackEvent(TrackingKey.roleplayVoiceInteraction, parameters: {
  'roleplay_id': roleplayId,
  'feedback_score': score,
});

// Premium events (premium_*, paywall_* prefix)
trackEvent(TrackingKey.paywallPackageClick, parameters: {
  'source': entryPoint.name,
  'package_id': packageId,
});
```

**Helper Methods for Parameter Building:**
- `_courseParams()` - Basic course tracking data
- `_courseLessonParams()` - Course + lesson context
- `_keypointParams()` - Full lesson hierarchy
- `_roleplayParams()` - Roleplay-specific data
- `_premiumParams()` - Paywall entry point
- `_courseParamsForPaywall()` - Course context in paywall

### Error Tracking

```dart
repository.getCourse(id).fold(
  (error) {
    getIt<ITrackingService>().trackError(
      error,
      context: {'course_id': id, 'cubit': 'CourseCubit'},
      errorType: 'repository_error',
    );
    // Sent to Crashlytics automatically
  },
  (course) { /* success */ },
);
```

---

## 6. Navigation & Deep Linking

### Go Router Type-Safe Navigation

```dart
@TypedGoRoute<CourseRoute>(
  path: '/course/:id',
  name: 'course',
  routes: [
    TypedGoRoute<LessonRoute>(path: 'lesson/:lessonId', name: 'lesson'),
  ],
)
class CourseRoute extends GoRouteData {
  final String id;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return MaterialPage(child: CoursePage(courseId: id));
  }
}

// Navigate programmatically (type-safe)
context.push(CourseRoute(id: '123'));
context.push(LessonRoute(id: '123', lessonId: '456'));

// Parse deep link: meup://course/123
GoRouter router = GoRouter(routes: [CourseRoute().route]);
```

### Deep Link Handling

```dart
// Universal link (iOS): apple-app-site-association at .info/deeplink/
// Android App Link: assetlinks.json at .info/deeplink/

// In app: DeeplinkCubit handles incoming links and navigates
// meup://course/123 → CoursePage
// meup://lesson/456 → LessonPage
```

---

## 7. Performance Architecture

### Lazy Initialization

```dart
@LazySingleton()
class HeavyService {
  // Not created until first call to getIt<HeavyService>()
}

@LazySingleton()
Future<AppConfig> provideAppConfig() async {
  return _loadConfigFromRemote();  // Only once
}
```

### Pagination Strategy

```dart
@freezed
class PageBreakRequest {
  const factory PageBreakRequest({
    @Default(1) int currentPage,
    @Default(20) int itemsPerPage,
  }) = _PageBreakRequest;
}

@freezed
class BasePageBreak<T> {
  const factory BasePageBreak({
    required List<T> items,
    required int currentPage,
    required int totalPages,
    required int itemsPerPage,
  }) = _BasePageBreak;
}

// Cubit auto-merges pages
runUseCasePageBreak<CourseEntity>(
  useCase: () => _getCourses(PageBreakRequest(currentPage: nextPage)),
  onSuccess: (newCourses, totalPages) {
    // Mixin merges: state.courses + newCourses
  },
);
```

### Image Caching

```dart
CachedNetworkImage(
  imageUrl: course.imageUrl,
  cacheManager: CacheManager.instance,
  placeholder: (context, url) => Shimmer.loading(),
  errorWidget: (context, url, error) => ErrorImage(),
)
```

---

## 8. Offline & Resilience Strategy

### Graceful Degradation

```
┌─ Online
│  ├─ Load from API (fresh data)
│  ├─ Cache locally (for offline)
│  └─ Show data
│
└─ Offline
   ├─ Check cache
   ├─ If cached: Show cached data (stale but functional)
   └─ If not cached: Show "Offline, please try later"
```

### Implementation

```dart
@override
TaskEither<AppException, List<CourseEntity>> getCourses(PageBreakRequest request) {
  return TaskEither.tryCatch(
    () async {
      try {
        final models = await _remoteDataSource.getCourses(request);
        await _localDataSource.cacheCourses(models);
        return models.map((m) => m.toEntity()).toList();
      } on DioException catch (e) {
        if (e.type == DioExceptionType.connectionTimeout) {
          final cached = await _localDataSource.getCachedCourses();
          if (cached.isNotEmpty) return cached;  // Return stale data
        }
        rethrow;
      }
    },
    (error, stackTrace) => AppException.connection(),
  );
}
```

### Retry Logic

```dart
Future<T> retryRequest<T>(Future<T> Function() request, {int maxRetries = 3}) async {
  int attempt = 0;
  while (attempt < maxRetries) {
    try {
      return await request();
    } catch (e) {
      attempt++;
      if (attempt >= maxRetries) rethrow;
      await Future.delayed(Duration(milliseconds: 100 * (2 ^ attempt)));
    }
  }
}
```

---

## 9. Security Architecture

### Token Management

```
AuthTokenCubit (HydratedCubit)
  ├─ accessToken (short-lived: 1 hour)
  ├─ refreshToken (long-lived: 30 days)
  ├─ expiryTime
  └─ Auto-refresh before expiry
```

### Secure Storage

```dart
// Android: EncryptedSharedPreferences
// iOS: Keychain

final token = _secureStorage.read(key: 'access_token');
_secureStorage.write(key: 'access_token', value: newToken);
```

### Obfuscation & Symbols

```bash
# Release build (automatic)
flutter build apk --release --obfuscate --split-debug-info=.obfuscation

# Debug symbols uploaded to Crashlytics for stack trace unobfuscation
```

---

## 10. System Constraints & Limits

| Aspect | Limit | Rationale |
|--------|-------|-----------|
| Max page size | 100 items | Minimize memory/battery drain |
| API timeout | 30 seconds | Balance UX vs network reliability |
| Cache TTL | 24 hours | Balance freshness vs bandwidth |
| Max file upload | 50 MB | Platform constraints (iOS/Android) |
| Max concurrent requests | 10 | Prevent memory exhaustion |
| Min API version | 21 (Android), 12 (iOS) | Manage support burden |

---

## Related Documentation

- **[System Architecture](./system-architecture.md)**: Core architecture, layers, data flow
- **[Code Standards](./code-standards.md)**: Naming conventions, patterns
- **[Deployment Guide](./deployment-guide.md)**: Build commands, CI/CD

---

**Document Maintained By:** Architecture Team
**Last Review:** Jan 22, 2026
**Next Review:** Mar 22, 2026
