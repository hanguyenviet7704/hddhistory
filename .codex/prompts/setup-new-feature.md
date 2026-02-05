---
description: Scaffold a full Clean Architecture feature (domain, data, presentation skeleton)
argument-hint: [ FEATURE=<snake_case> ] [ DATA_SOURCE=rest|graphql|local|none ] [ CUBIT=true|false ]
---
You are Codex building a brand-new feature inside `lib/src/` following Meup’s Clean Architecture patterns.

## Inputs
- If `FEATURE` is missing, ask for the canonical snake_case feature name (e.g., `user_notifications`).
- If `DATA_SOURCE` is missing, ask whether the feature talks to REST, GraphQL, local storage only, or is domain-only.
- If `CUBIT` is missing, ask whether state management scaffolds should be created (HydratedCubit by default).
- Ask for functional requirements: API specs, GraphQL operations, or reference features to mirror. Capture any unique constraints.

## Workflow
1. Explore existing code for analogous features (same data source or UX). Note DI usage, mixins, naming, and file layout. Reference `CLAUDE.md` when needed.
2. Domain layer (`lib/src/<feature>/domain/`):
   - Create `entities/<feature>_<entity>.dart`, update `entities.dart` part directives.
   - Define repository interfaces under `repositories/` returning `Either<AppException, T>`.
   - Generate use cases with params/value objects under `usecases/` and register them with `@lazySingleton`.
3. Data layer (`lib/src/<feature>/data/`):
   - Freezed models with JSON serialization under `models/` plus `toEntity()` extensions.
   - Repository implementations using `GraphQLRequestHandlerMixin` or `RestfulRequestHandlerMixin` depending on `DATA_SOURCE`.
   - Retrofit APIs (`datasources/apis`) or `.graphql` templates plus generated classes when required.
   - Wire repositories to interfaces via `@LazySingleton(as: IFeatureRepository)`.
4. Presentation scaffolding (only when `CUBIT=true`):
   - Create Cubit/State pair under `presentation/cubits/`.
   - Provide starter page/view files or widgets if requirements include UI hooks. Keep UI minimal; this command focuses on logic skeletons.
5. Tests:
   - Drop placeholder unit test files for entities, use cases, repositories, and cubits following existing naming conventions in `test/unit/<feature>/`.
6. Run `dart run build_runner build --delete-conflicting-outputs` (and `flutter analyze`) to ensure Freezed/Injectable artifacts are generated.

## Validation & Reporting
- Present the directory tree of created files and highlight important classes with brief responsibilities.
- Surface follow-ups: missing API details, TODOs inside code, next steps for `/update-new-ux-ui`.
- Remind the user to flesh out real logic/tests where placeholders remain.
