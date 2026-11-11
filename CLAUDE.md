# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build, Test, and Development Commands

### Code Generation (Required after model/API changes)
```bash
dart run build_runner build --delete-conflicting-outputs  # Generate all code
dart run build_runner watch --delete-conflicting-outputs  # Watch mode
dart run build_runner clean                               # Clean generated files
```

### Testing and Analysis
```bash
flutter analyze                 # Static analysis — the default correctness gate
flutter test test/unit/<feature>/<target>_test.dart   # ONE targeted test
dart format lib/ test/          # Format code (180 char line width)
```

**Do not run the full `flutter test` suite on this dev machine** — it exhausts RAM.
Verify with `flutter analyze`; run a single test file when one is genuinely needed.

### Localization
```bash
dart run slang                  # Regenerate lib/config/l10n/ from the YAML
```
The YAML under `assets/i18n/<locale>/<module>.yaml` **is** the source of truth —
edit it directly, then regenerate. The Google-Sheets round-trip under
`tools/<os>/localization/` still exists but is no longer the workflow.

### Building
```bash
# Local run / install (simulator, emulator, attached device)
./tools/macos/build/run_app.sh <dev|stg|prod>
./tools/macos/build/install_app.sh <dev|stg|prod>

# Android
./tools/macos/build/build_apk.sh <dev|stg|prod>
./tools/macos/build/build_appbundle.sh <dev|stg|prod>

# iOS (macOS only)
./tools/macos/build/build_ios.sh <dev|stg|prod>
./tools/macos/build/build_ipa.sh <dev|stg|prod>

# After flavor changes
flutter clean && dart run flutter_flavorizr && flutter pub get
```

## Architecture Overview

**Clean Architecture** with three layers per feature module:

```
lib/src/<feature>/
├── domain/       # Business logic: entities, repository interfaces, use cases
├── data/         # Data sources (remote/local), models, repository implementations
└── presentation/ # UI pages, widgets, BLoCs/Cubits
```

### Key Directories
- `lib/config/` - App-wide config: DI (`di/`), routes (`routes/`), l10n (`l10n/`), themes (`themes/`), services (`services/`)
- `lib/core/` - Shared utilities: base classes (`base/`), constants (`constants/`), helpers (`helpers/`), UI utils (`utils/`)
- `lib/src/` - Feature modules: auth, course, lesson, roleplay, monetization, etc.
- `tools/` - Cross-platform build/config scripts (macOS, Linux, Windows)
- `.info/` - Centralized project configuration (app.json, firebase.json, build.json)

### State Management
- **BLoC/Cubit** pattern with `flutter_bloc`
- **HydratedBloc** for persistent state (theme, locale, settings)
- **UseCase Handler Mixins** reduce boilerplate: `CubitUseCaseHandlerMixin` with `executeUseCase`, `executeListUseCase`, `executePageBreakUseCase`

### Data Flow
Widget → Cubit/BLoC → UseCase → Repository Interface → Data Source

Do not expose `dio`/`graphql` types beyond data layer.

### Networking
- **REST**: Dio + Retrofit (code-generated API clients in `data/datasources/remote/`)
- **GraphQL**: graphql_flutter (templates in `data/datasources/graphql/template/`, generated in `gen/`)
- **Error Handling**: Functional with `fpdart` (`TaskEither<AppException, T>`)

### Dependency Injection
- `get_it` + `injectable` annotations (`@LazySingleton`, `@factoryMethod`)
- Resolve via `getIt<T>()` or constructor injection

### Navigation
- `go_router` with type-safe code generation
- Route data files in `lib/config/routes/` organized by feature

## Multi-Environment Setup

Three flavors: `dev`, `stg`, `prod`

| Flavor | Entry Point | Env File |
|--------|------------|----------|
| dev | `main_dev.dart` | `.env/.env.dev` |
| stg | `main_stg.dart` | `.env/.env.stg` |
| prod | `main_prod.dart` | `.env/.env.prod` |

Uses `--dart-define-from-file` (NOT `--dart-define`) for environment configuration.

## Code Generation Tools

| Generator | Purpose |
|-----------|---------|
| `go_router_builder` | Type-safe routing |
| `retrofit_generator` | REST API clients |
| `json_serializable` | JSON serialization |
| `freezed` | Immutable classes/states |
| `injectable_generator` | Dependency injection |
| `graphql_codegen` | GraphQL clients |
| `flutter_gen_runner` | Asset references |
| `slang_build_runner` | Localization |

Never edit generated files (`*.g.dart`, `*.config.dart`, `*.freezed.dart`). Rerun generators instead.

## Coding Conventions

### Naming
- Files/dirs: `snake_case.dart`
- Types: `PascalCase`
- Cubit/BLoC: suffix with `Cubit`/`Bloc`

### Commit Messages
Format: `type: subject` — no numeric ticket ID (those fell out of use).
- Types: `feature`, `fix`, `refactor`, `style`, `docs`, `test`, `chore`, `perf`
- Imperative, lowercase, English or Vietnamese — match surrounding history
- Example: `feat: one swipeable keypoint screen with per-card narration`

### Branch Naming
`type/<slug>` (e.g. `feature/keypoint-swipe-narration`). The integration
branch is `develop`.

## Localization

- YAML source: `assets/i18n/<locale>/<module>.yaml` — **this is the source of truth**
- Generated Dart: `lib/config/l10n/` (config `slang.yaml`, base locale `en`,
  `fallback_strategy: base_locale`, non-base locales lazily deferred)
- **Five locales ship** — `en`, `vi`, `zh`, `ja`, `ko`. A new key must be added to
  all five, or it silently falls back to English.
- Keys: lowerCamelCase without module prefix (module is the namespace)
- Workflow: edit YAML → `dart run slang` → `flutter analyze`

## Testing

- Tests in `test/unit/<feature>/` mirroring feature structure
- Name: `<target>_test.dart`
- Mock injected services and storage for `hydrated_bloc`
- Run `flutter analyze` before PR, plus targeted test files — never the full suite
  on this machine (RAM). For on-device UI verification use the `sim-test` skill.

## Security Notes

Do not commit: `google-services.json`, `GoogleService-Info.plist`, keystores, Apple provisioning, localization SA JSON.

Release builds use `--obfuscate --split-debug-info=.obfuscation`; symbols auto-upload to Crashlytics.
