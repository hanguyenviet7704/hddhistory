# Lesson Document Explanation Options Planning

## Context

- Date: 2026-04-02
- Branch: `feature/MEUP-719`
- Scope: lesson `DocumentItem` explanation options only

## What Happened

- Reviewed lesson document renderer, new explanation option entities/models, lesson raw spec, and Figma node `7900:14665`.
- Locked boundary: this is document content, not exercise logic.
- Agreed interaction: single-select, tap again collapses, state may reset on rebuild, page CTA stays `Continue`.
- Wrote implementation plan at `plans/260402-1548-lesson-document-explanation-options/`.

## Decisions

- Keep state local to a dedicated explanation document widget.
- Extend document availability to recognize option-backed explanation docs.
- Reuse shared document render path; do not couple to `ChoiceCubit` or `TheoryCubit`.
- Match Figma card visuals only, not the exercise-shell semantics.

## Next

- Implement phases in order: contract/data gate -> explanation renderer -> validation/tests.
