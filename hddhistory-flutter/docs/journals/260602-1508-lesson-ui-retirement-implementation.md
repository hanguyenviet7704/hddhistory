# Lesson UI Retirement Implementation

**Date**: 2026-06-02 15:08 +07
**Status**: DONE

## Context

Retired the old lesson presentation UI under `lib/src/lesson` and replaced it with a shared shell/layout model that matches the new Figma-driven flow. The goal was to keep lesson behavior intact while removing duplicated presentation variants across theory, exercise, and audio surfaces.

## What changed

- Added a shared `LessonShellLayout` for both no-audio and audio lesson flows.
- Kept no-audio keypoints in a lavender close-only shell.
- Kept audio keypoints on the Read/Listen toggle flow.
- Made the sticky bottom action always render when provided, instead of hiding behind `LessonCubit.isBottomButtonVisible`.
- Added `LessonContentCard` and made `DocumentWidget` configurable via `asCard`.
- Wrapped exercise bodies in the shared card pattern to remove surface drift.
- Replaced the audio surface with `LessonAudioPlayerCard` and moved the speed pill into the shell header.
- Preserved playback, seek, and speed sheet behavior while simplifying the shell around it.

## Validation

- `flutter test test/unit/lesson` passed.
- `flutter analyze` passed.
- Docs updated in `docs/system-architecture.md` and `docs/codebase-summary.md`.

## Decisions

- Kept Cubit, routing, progress, tracking, review queue, completion, and audio runtime untouched.
- Retired only the presentation shell/body/card layer, not the lesson domain flow.
- Chose a shared shell over per-body UI forks because the old layout was already fragmented and was leaking behavior differences.
- Left the existing `pubspec.yaml` release-version edit alone because it pre-existed this work; do not fold that into this change by accident.

## Follow-ups

- Make sure the new Dart files are included before commit:
  - `lesson_shell_layout.dart`
  - `lesson_shell_header.dart`
  - `lesson_mode_toggle.dart`
  - `lesson_sticky_bottom_action.dart`
  - `lesson_content_card.dart`
  - `lesson_audio_player_card.dart`
- Keep the dirty `pubspec.yaml` version edit separate from this implementation commit.
