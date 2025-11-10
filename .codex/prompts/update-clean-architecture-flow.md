---
description: Propagate model/entity/repository changes through an existing feature
argument-hint: [ FEATURE=<name> ] [ CHANGE_SCOPE=added|removed|type|full ] [ MODE=auto|guided ]
---
You are Codex updating an existing Meup Clean Architecture module so that Domain, Data, and Presentation stay in sync after an API/schema change.

## Inputs
- If `FEATURE` is missing, ask for the module name or a representative file path.
- If `CHANGE_SCOPE` is missing, ask whether fields were added, removed, had type changes, or if this is a larger restructure.
- If `MODE` is missing, ask whether to infer updates automatically or walk through them step by step with the user.
- Capture any authoritative spec (API doc, schema diff, sample payload) before editing files.

## Workflow
1. Discover the affected files:
   - Enumerate entities, repositories, use cases, cubits under `lib/src/<feature>/`.
   - List data models, Retrofit APIs, GraphQL templates, and conversions.
   - Include presentation/state files when data shape changes bubble up.
2. Read current implementations and map field differences vs the new contract.
3. Update layers in order:
   - Data models: adjust Freezed classes, defaults, JSON annotations, and regeneration requirements.
   - Domain entities/value objects: keep parity with data models and business rules.
   - Extensions/mappers: ensure every new field maps cleanly, including nullability and defaults.
   - Repository interfaces + implementations: update method signatures, params, and return types; adapt REST/GraphQL calls accordingly.
   - Cubits/states/selectors: sync state fields and serialization (HydratedCubit) when data shape changes.
4. Run `dart run build_runner build --delete-conflicting-outputs` to refresh generated code, followed by targeted tests or `flutter analyze`.

## Validation & Reporting
- Summarize the touchpoints per layer with file references and rationale.
- Call out any manual follow-ups (e.g., backend expectations, migrations, UI polish).
- If blockers surface (missing API info, cascading schema issues), stop and request clarification instead of guessing.
