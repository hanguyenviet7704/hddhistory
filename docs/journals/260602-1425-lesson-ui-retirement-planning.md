---
type: journal
date: 2026-06-02
topic: lesson-ui-retirement-planning
---

# Lesson UI Retirement Planning

## Context

User approved retiring the current `lib/src/lesson` presentation UI. New UI must match Figma nodes `9858:48418`, `9858:48484`, and `9858:48564`.

## What Happened

- Confirmed new shell applies to audio and read-only lessons.
- Confirmed read-only shell shows close only.
- Confirmed all exercise bodies/cards use the same outer style as theory.
- Confirmed sticky `Continue` is always visible when a bottom action exists.
- Created deep TDD plan at `plans/260602-1425-lesson-ui-retirement/plan.md`.
- Captured research, red-team, and validation reports inside the plan directory.

## Decisions

- Preserve Cubits, route contract, progress, tracking, review queue, completion, and audio runtime.
- Retire presentation shell/body/card/audio UI only.
- Use `/ck:cook ... --tdd` for implementation.

## Next

Implement Phase 1 first: shell foundation and sticky bottom CTA tests.

Unresolved questions: none.
