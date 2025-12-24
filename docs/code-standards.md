# Code Standards

_Last updated: 2025-12-24_

## 1. Guiding Principles
- **Clean Architecture adherence**: Presentation, domain, and data layers must remain isolated (no UI imports in domain/data; no HTTP/Dio exposure above data).
- **TaskEither-by-default**: All async domain operations use `TaskEither<AppException, T>`; do not reintroduce `Future<Either>` or raw futures in repositories/use cases.
- **State via Cubit/BLoC**: Prefer Cubit for simple flows, BLoC when multiple events. Persist long-lived state with `HydratedCubit`.
- **DI clarity**: Register every injectable in `lib/config/di` with explicit scope annotations and rely on constructor injection for testability.
- **YAGNI / KISS / DRY**: Avoid speculative abstractions, keep files <200 LOC, extract utilities when reused.

## 2. Project Structure
```
lib/
├── config/        # Routes, DI, themes, localization, services
├── core/          # Shared constants, base classes, helpers, generated assets
└── src/<feature>/ # Feature pods with domain/data/presentation
```
- Feature directories must include `domain/`, `data/`, `presentation/` as needed.
- Shared widgets live in `lib/src/presentation/widgets` to prevent cross-feature coupling.

## 3. Naming Conventions
| Artifact | Rule | Example |
| --- | --- | --- |
| Files/Folders | `snake_case` | `exercise_cubit.dart`, `exercise_repository_impl.dart` |
| Classes | `PascalCase` | `ExerciseCubit`, `FetchExerciseUseCase` |
| Interfaces | `PascalCase` with suffix (`Repository`, `UseCase`) | `ExerciseRepository` |
| Bloc/Cubit states | `PascalCase` with `State` suffix | `ExerciseState`, `ExerciseLoadedState` |
| DI tokens | Type-based | `getIt<ExerciseCubit>()` |

## 4. Error Handling
- Use `lib/core/base/error/app_exception.dart` as the canonical error type; keep error mapping inside repositories/mixins.
- Map Dio/GraphQL errors to domain-friendly `AppException` values inside repositories; presentation never sees raw HTTP codes.
- Use `TaskEither.tryCatch` to wrap side effects; fold results inside cubits/blocs for UI consumption.

## 5. Networking & Data
- **REST**: Implement Retrofit interfaces inside `data/datasources/apis/`. Generated clients live under `*.g.dart`; do not edit manually.
- **GraphQL**: Place queries in `data/datasources/graphql/template/`, run `graphql_codegen` for strongly-typed APIs.
- **Serialization**: Use `json_serializable` + `freezed` for immutable models; keep converters in `data/models/converters/` when necessary.
- **Mappers**: Provide explicit mapping functions between DTOs and domain entities (prefer extension methods for readability).

## 6. State Management Patterns
- Cubits/Blocs should expose pure states; never mutate state fields directly.
- Use `CubitUseCaseHandlerMixin` utilities (where available) to reduce boilerplate when invoking use cases.
- Persist state with HydratedBloc only when required (theme, locale, auth session). Encrypt secrets via `flutter_secure_storage`.

## 7. Testing Requirements
- Minimum: unit tests for every use case and repository; widget tests for critical flows (auth, purchase, lesson player).
- Run `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze`, and `flutter test` before raising PRs (see `TEST.md`).
- Mock dependencies via `mockito` or lightweight fakes; prefer TaskEither-friendly helpers for success/error cases.
- Track coverage via `flutter test --coverage`; maintain >80% for domain/data layers.

## 8. Tooling & Automation
- Regenerate code after touching `*.freezed.dart`, `*.g.dart`, route definitions, or DI annotations.
- Localization updates require: `tools/<os>/localization/localization.sh pull` → update sheet → `slang` → `dart run slang_build_runner`.
- Build scripts must be cross-platform; mirror macOS changes to Linux/Windows equivalents when feasible.

## 9. Git & Commit Etiquette
- Follow `type-TICKET-ID: summary` format (e.g., `feature-MEUP-123: Add lesson quiz gating`). Use types: `feature`, `fix`, `refactor`, `style`, `docs`, `test`, `chore`, `perf`.
- Scope commits to a single concern (feature, fix, refactor). Avoid mixing tooling/lint updates with feature code.
- Never commit secrets from `.info/key/` or `.env/`.

## 10. Documentation Expectations
- Update `docs/` whenever architecture, tooling, or standards change.
- Keep README under 300 lines and treat docs/*.md as the source of truth.
- Add "Last updated" stamps to major docs with ISO dates.

## 11. Review Checklist
1. Architecture boundaries respected (presentation ↔ domain ↔ data).
2. All new async flows use TaskEither + proper error mapping.
3. Tests updated/added and pass locally.
4. Build/format/analyze commands executed.
5. Documentation references adjusted (routes, envs, tooling, metrics).
