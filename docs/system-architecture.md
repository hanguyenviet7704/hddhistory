# System Architecture

**Last Updated:** 2026-02-27  
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

## 3. Module Topology (`lib/src`)
Current modules: `achievenment`, `auth`, `common`, `course`, `data_collect`, `feedback`, `home`, `lesson`, `monetization`, `onboard`, `onboard_branching`, `profile`, `progress`, `roleplay`, `setting`.

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
4. If refresh fails, app session is reset and user is routed back to auth flow.
5. For non-401 failures, repository/request helpers map transport errors to `AppException` and return `TaskEither` left states.

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
- Shell-based navigation and nested course/lesson/roleplay flows are handled in route config files.

### Lesson runtime flow
- `CourseRoadmapRoute` composes roadmap + lesson + progress + feedback state providers.
- `LessonRoute` composes lesson execution providers (`LessonCubit`, exercise/theory/speaking variants, `ProgressCubit`, `FeedbackCubit`, `PageCubit`).
- Completion routes (`KeypointCompleteRoute`, `BadgeProgressRoute`) merge lesson progress back into roadmap/home state.

### Roleplay runtime flow
- `RoleplayIntroRoute` and `RoleplayRoute` provide roleplay orchestration via `RoleplayCubit` (+ feedback where needed).
- `RoleplayFeedbackRoute` merges `RoleplayCubit`, `RoleplayPointCubit`, `HomeCubit`, and `FeedbackCubit` for post-session analytics and UI.
- Route-level provider composition keeps runtime concerns scoped to each flow stage.

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
