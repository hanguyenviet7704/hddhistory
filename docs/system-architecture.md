# System Architecture

_Last updated: 2025-12-24_

## 1. High-Level View
- **Client**: Flutter app targeting Android, iOS, and desktop/web (build scripts focus on mobile) with Clean Architecture modules.
- **Backend**: External APIs accessed via REST (Dio + Retrofit) and GraphQL (`graphql_flutter`) plus Firebase services (Auth, Remote Config, Messaging, Analytics, Crashlytics).
- **Configuration Layer**: `.info/app/*.json` and `.env/.env.<flavor>` hold build, environment, and credential metadata consumed by tooling and runtime.
- **CI/Build Tooling**: `tools/<os>/...` scripts orchestrate setup, lint/test, builds, distribution, Firebase sync, and smoke validation across macOS/Linux/Windows.

```
UI Widgets → Cubits/BLoCs → Use Cases → Repository Interfaces → Repository Impl → Data Sources (REST/GraphQL/Firebase/local)
```

## 2. Clean Architecture Layers
### Presentation
- Located inside `lib/src/<feature>/presentation/` and `lib/config/routes/`.
- Uses `flutter_bloc` / `hydrated_bloc` for stateful flows, `go_router` for navigation.
- UI components rely on `flutter_screenutil`, `AppTheme`, and generated assets.

### Domain
- `lib/src/<feature>/domain/` defines entities, repositories, and use cases returning `TaskEither<AppException, T>`.
- Pure Dart with no Flutter imports, enabling unit-test isolation.

### Data
- `lib/src/<feature>/data/` holds models, DTOs, repository implementations, and `datasources/apis` (Retrofit) or `datasources/graphql`.
- JSON serialization via `json_serializable`/`freezed`; DI via `injectable`.
- Shared helpers live in `lib/core/` (errors, http interceptors, caching, tokens).

## 3. Cross-Cutting Concerns
| Concern | Location | Notes |
| --- | --- | --- |
| Dependency Injection | `lib/config/di`, `injectable.config.dart` | `get_it` container bootstrapped in `main_<flavor>.dart`; environment-specific modules register per flavor. |
| Routing | `lib/config/routes/` | `go_router_builder` generates typed routes; guard logic encapsulated in route data classes. |
| Localization | `lib/config/l10n`, `assets/i18n` | Google Sheets driven, regenerated via `slang` after localization pull. |
| Theming | `lib/config/themes/` | `theme_collection.dart` centralizes light/dark palettes and typography. |
| Error Handling | `lib/core/errors`, `AppException` hierarchy | Propagated through TaskEither, decoded from Dio/GraphQL responses.
| Persistence | `hydrated_bloc`, local caches | Secure storage for secrets via `flutter_secure_storage`.

## 4. Data Flow Examples
### User Authentication
1. UI triggers `AuthCubit.signIn()`.
2. Cubit invokes `SignInUseCase`, returning `TaskEither<AppException, User>`.
3. `AuthRepositoryImpl` delegates to REST API (`dio`/`retrofit`) and Firebase Auth SDK.
4. Results fold back to Cubit for success/error emission; hydrated storage persists tokens/settings.

### Lesson Exercise Flow
1. Lesson page loads via `LessonRoute` defined in go_router.
2. `ExerciseCubit` requests question payloads via `FetchExerciseUseCase`.
3. Repository hits remote API and merges with local progress caches.
4. Presentation layer renders overlays (recent commit focus) and tracks answers.

## 5. Build & Deployment Architecture
- **Flavor Entrypoints**: `main_dev.dart`, `main_stg.dart`, `main_prod.dart` configure `FlavorConfig` (env URLs, Firebase options, feature toggles).
- **Environment Variables**: Provided through `.env/.env.<flavor>`; consumed via `--dart-define-from-file` in scripts and IDE configs.
- **Build Scripts**: `tools/<os>/build/*` call Flutter, apply build args (`--obfuscate --split-debug-info=.obfuscation`), handle signing, outputs defined in `.info/app/build.json`.
- **Distribution**: `tools/<os>/distribution/*` read `.info/distribution/*.txt` + Firebase config to upload artifacts, testers, release notes.
- **CI Hooks**: `tools/smoke.sh` verifies script parity; `.github/workflows/tools-smoke.yml` (referenced) exercises matrix builds.

## 6. External Integrations
- **Firebase**: Auth, Remote Config, Messaging, Analytics, Crashlytics configured per flavor via `flutterfire_config.sh`.
- **Payments**: `in_app_purchase_*` packages with platform-specific store integrations.
- **Notifications**: `awesome_notifications`, `firebase_messaging` for push and local notifications.
- **Analytics/Monitoring**: `firebase_analytics`, `sentry_flutter`.
- **Media**: `video_player`, `just_audio`, `gal`, screenshot/recording utilities.

## 7. Infrastructure & Security
- Secrets and signing assets isolated under `.info/key/` (excluded from VCS and repomix exports).
- Distribution lists and release notes stored in `.info/distribution/` with merge logic to Firebase configs.
- Build scripts enforce validations (presence of env files, CLI tools, version manager detection) before executing heavy tasks.
- Crashlytics and Sentry provide runtime monitoring; TaskEither surfaces domain-safe errors back to UI for user-friendly messaging.

## 8. Future Considerations
1. Define explicit API contracts per feature (OpenAPI/GraphQL schema doc) to tighten doc-to-code traceability.
2. Expand observability section with dashboards, alerting, and log correlation once backend endpoints stabilize.
3. Capture infra-as-code references if CI/CD pipelines extend beyond script usage (currently implied through manual script runs).
