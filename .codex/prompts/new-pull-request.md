---
description: Analyze git changes and draft a Clean Architecture aware PR description
argument-hint: [ TARGET_BRANCH=develop|main|<name> ] [ INCLUDE_SHOTS=true|false ]
---
You are Codex preparing a pull request summary for the Meup Flutter app. Produce a high-signal PR description that classifies every change across architecture layers and flags risk.

## Inputs
- If `TARGET_BRANCH` is absent, ask which branch to diff against (default `develop`).
- If `INCLUDE_SHOTS` is absent, ask whether screenshots or recordings are available; mention them only when the user confirms.
- Confirm the working tree is clean aside from intentional changes; ask the user to stash/commit otherwise.

## Workflow
1. Collect git data: current branch, diff vs `TARGET_BRANCH`, stats, per-file lists, commit subjects, and `pubspec.yaml` diff for dependency changes.
2. Derive ticket IDs from the branch name (`MEUP-###` or similar). Ask the user if none can be inferred.
3. Categorize changes:
   - Map files to architecture layers (Domain/Data/Presentation/Config/Assets/Tests/Docs/Build).
   - Group commits by intent (features, improvements, fixes, tests, docs, tooling).
   - Detect breaking interface changes (e.g., repository signatures, removed entity fields, route updates).
   - Detect dependency additions or version bumps from `pubspec.yaml`.
4. Summarize impact: highlight high/medium/low risk areas, new dependencies, migrations, or follow-up work.
5. Draft the PR content in Markdown with sections:
   - Summary (2–3 sentences).
   - Ticket / Branch / Target.
   - Change statistics (files, additions, deletions, commit count).
   - Layer-by-layer breakdown with concise bullet points.
   - Breaking changes / migrations (if any).
   - New dependencies or tooling updates.
   - Testing evidence (list the commands/results actually run).
   - Screenshots/media (only when `INCLUDE_SHOTS=true` and assets are available).

## Validation & Reporting
- Quote concrete file paths and commit SHAs where helpful.
- Call out gaps: missing tests, flaky analysis, or items needing reviewer focus.
- Close with clear next steps (e.g., “run flutter test” if unverified).
