# Code Standards

**Last Updated:** 2026-03-16  
**Scope:** Dart/Flutter source in this repository

## 1. Architecture Rules
### Layer boundaries
```text
presentation -> domain -> data
```
- `presentation`: pages/widgets/cubits/blocs and UI-only mapping.
- `domain`: entities, repository interfaces, use cases.
- `data`: API clients, models, repository implementations, local/remote sources.

### Mandatory constraints
1. Do not import data-layer types (Retrofit models, Dio classes) into presentation/domain.
2. Keep repository interfaces in `domain`, implementations in `data`.
3. Keep domain logic platform-agnostic where possible.
4. Keep feature work inside `lib/src/<feature>/` unless explicitly shared.

## 2. State Management Standards
- Primary pattern: Cubit/Bloc via `flutter_bloc`.
- Persistent state: HydratedCubit only where persistence is needed.
- Use mixins from `lib/core/base/bloc/`:
  - `runUseCase<T>`
  - `runUseCaseList<T>`
  - `runUseCaseVoid`
  - `runUseCasePageBreak<T>()`

### Preferred flow
```text
Widget/Page -> Cubit/Bloc -> UseCase -> Repository Interface -> Repository Impl -> API/Cache
```

## 3. Error Handling and Result Types
- Use functional return types: `TaskEither<AppException, T>`.
- Use `AppException` for normalized error categories and user-facing display messages.
- For network and transform pipelines, prefer helpers in the restful request handler mixin.

## 4. Naming Conventions
### Files and directories
- Dart files: `snake_case.dart`.
- Feature folders: existing path names are canonical and must be preserved (`achievenment`, `onboard_branching`, etc.).

### Types and members
- Classes/enums/types: PascalCase.
- Variables/functions/methods: camelCase.
- Private members: `_camelCase`.

### Suffix patterns
- Cubits/Blocs: `*Cubit`, `*Bloc`.
- Use cases: `*UseCase` / `*Usecase` (keep existing local naming where already established).
- Entities/models: `*Entity`, `*Model`.
- API clients: `*Api`.

## 5. Module Layout Standard
Canonical layout for features:
```text
lib/src/<feature>/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── cubits/ or blocs/
    ├── pages/
    └── widgets/
```

Notes:
- Some existing modules do not have all subfolders (for example `common`, `setting`).
- Do not force structural churn unless required by task scope.

### Config service boundaries
- `lib/config/services/notification/` keeps only `notification_service.dart` and `notification_core_config.dart` as app-facing files.
- Keep notification imported into `lib/config/services/services.dart` as a regular library seam; do not reintroduce notification as a `part` file.
- Keep notification internals grouped under `adapters`, `bootstrap`, `constants`, `models`, `permissions`, `routing`, `runtime`, and `schedulers`.
- Do not leak `firebase_messaging`, `awesome_notifications`, or other transport-specific types outside the notification core public API.

## 6. Pagination and API Contract Standards
- Use `PageBreakRequest` for paginated endpoints.
- App-facing fields: `page`, `limit`, `orderBy`, `order`, `search`, `filter`.
- Serialized query fields: `page`, `take`, `orderBy`, `order`, `search`.
- Paginated response shape: `BasePageBreak<T>` with `totalPages`, `currentPage`, `itemsPerPage`, `items`.

## 7. Dependency Injection Standards
- DI stack: `get_it` + `injectable`.
- Annotate DI registrations (`@lazySingleton`, `@factoryMethod`) following existing patterns.
- Resolve dependencies through DI container, not ad-hoc global constructors.

## 8. Code Generation Standards
Do not edit generated files directly:
- `*.g.dart`
- `*.freezed.dart`
- `*.config.dart`
- `*.graphql.dart`

Regenerate with:
```bash
dart run build_runner build --delete-conflicting-outputs
```

## 9. Localization Standards
- Source of truth: `assets/i18n/<locale>/<module>.yaml`.
- Generated outputs: `lib/config/l10n/`.
- Key style: lowerCamelCase, with module namespace implied by file.
- Access translations in widgets with `context.l10n`; use `Translations.of(context)` only when an explicit local variable is clearer.
- Use the generated global `l10n` accessor only for helpers that do not receive a `BuildContext`.
- Do not add or restore custom translation helpers such as `context.text`.
- Standard sync flow:
```bash
# macOS/Linux
tools/<os>/localization/localization.sh pull
tools/<os>/localization/localization.sh push --apply
tools/<os>/localization/localization.sh pull
tools/<os>/localization/localization.sh slang

# Windows
tools\\windows\\localization\\localization.bat pull
tools\\windows\\localization\\localization.bat push --apply
tools\\windows\\localization\\localization.bat pull
tools\\windows\\localization\\localization.bat slang
```
- After localization config or key changes, rerun `slang` and `flutter analyze` before merge.

## 10. Testing and Quality Gates
### Required local checks before merge
```bash
flutter analyze
flutter test
```

### Test organization
- Mirror features under `test/unit/<feature>/`.
- Test file naming: `<target>_test.dart`.
- Cover success and failure branches for new business logic.

## 11. Security and Secrets
1. Never commit production secrets, signing keys, or private provisioning files.
2. Keep credentials in CI variables or local secure storage.
3. Keep release builds obfuscated with split debug info output.
4. Keep symbol upload behavior explicit in CI (or intentionally skipped with env switch).

## 12. Build and Runtime Constraints
- Dart SDK (`pubspec.yaml`): `>=3.11.0 <4.0.0`.
- iOS deployment target (`ios/Podfile`): `15.0`.
- Flavors: `dev`, `stg`, `prod` (`lib/main_<flavor>.dart`).

## 13. Git and Change Hygiene
- Keep changes scoped and reviewable.
- Avoid unrelated refactors in feature/fix PRs.
- Prefer conventional commit style.

Examples:
```text
feat: add roleplay feedback summary card
fix: handle null filter in page break request
docs: sync deployment variable contract
```

## 14. Documentation Sync Rules
Update docs when any of the following change:
1. Module inventory under `lib/src`.
2. Runtime constraints (SDK, iOS/Android minimums).
3. API request/response contracts.
4. Build/deployment script flags or CI variable contracts.

Minimum docs to review after technical changes:
- `docs/codebase-summary.md`
- `docs/system-architecture.md`
- `docs/deployment-guide.md`
- `docs/api-integration-guide.md`
- `docs/gitlab-cicd-setup-guide.md`
