---
description: Implement or refresh Flutter UI from Figma with token mapping and responsive layout
argument-hint: [ NODE=<figma_url_or_id> ] [ KIND=page|widget|update ] [ FEATURE=<name> ] [ STATE=existing|new|none ]
---
You are Codex translating a Figma design into Flutter UI for the Meup app using existing design tokens and architecture.

## Inputs
- Require `NODE` (`https://figma.com/...node-id=` or raw node id). Ask for it if missing.
- If `KIND` is missing, ask whether this is a new page, updating an existing page, creating a reusable widget, or refreshing a widget.
- If `FEATURE` is missing, ask which module under `lib/src/` owns the UI.
- Clarify state integration via `STATE` (`existing` Cubit name, `new`, or `none`) plus any gestures/animations or assets needed.

## Workflow
1. Pull design context with the Figma MCP (`get_design_context` and screenshots when needed). Extract hierarchy, colors, typography, spacing, radii, and imagery.
2. Map tokens:
   - Match Figma colors to `AppCustomColor`/theme palettes; introduce new tokens only when necessary and document them.
   - Match typography to `AppStyle` entries or extend if required.
3. Find similar implementations in the repo (same feature or layout) to stay consistent with ScreenUtil usage, Cubit patterns, and widget structure.
4. Implement the UI:
   - For pages, create/extend `presentation/pages/<page>/` with a `Page` wrapper (DI + BlocProvider) and a `View` widget containing the layout.
   - For widgets, place them under `presentation/widgets/` with configurable parameters and doc comments.
   - Use responsive helpers (`.w`, `.h`, `.r`, `.sp`), SafeArea, and existing reusable widgets before inventing new ones.
   - Wire localization keys and routes when screens introduce new copy/navigation.
5. Connect state management per `STATE`: reuse cubits when provided, scaffold a new HydratedCubit otherwise, or keep stateless if not needed.
6. Validate: run any relevant tests for the feature plus `flutter analyze`. Mention screenshot diffs if generated.

## Validation & Reporting
- Summarize new/updated files with their responsibilities and how the design tokens were mapped.
- Call out follow-ups (animations, assets, translations) if they could not be completed.
- Provide guidance for QA (navigation path, feature flags) if applicable.
