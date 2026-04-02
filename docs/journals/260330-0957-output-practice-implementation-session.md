# Output Practice Shell Session

**Date**: 2026-03-30 09:57
**Severity**: Medium
**Component**: output_practice course shell, socket/runtime orchestration, tracking
**Status**: Resolved

## What Happened

Implemented the output-practice course-shell flow end to end: route shell wiring, tracking hooks, socket/runtime orchestration, retry affordance, and unit coverage. The work touched `lib/config/routes/data/routes_shell_course_output_practice_data.dart`, `lib/src/output_practice/presentation/cubits/output_practice_runtime_helper.dart`, `lib/src/output_practice/presentation/cubits/output_practice_socket_cubit.dart`, `lib/src/output_practice/presentation/cubits/output_practice_cubit.dart`, and `lib/src/output_practice/presentation/pages/output_practice_page.dart`.

Review caught two real problems before merge: async reconcile could apply late updates out of order, and stale session state could survive retry/re-entry. Those issues were fixed in the same pass.

## The Brutal Truth

The first pass was too optimistic. The happy path worked, but the lifecycle edges were loose enough to let old state leak back in. That is the kind of bug that burns time later because it only shows up when retry timing gets messy.

## Technical Details

Tracking now flows through `lib/config/services/tracking/app_tracking_service.dart`, `lib/config/services/tracking/i_tracking_service.dart`, and `lib/core/constants/manual/tracking_key.dart`.

Tests were added or updated under `test/unit/output_practice/`, plus route coverage in `test/unit/config/routes/routes_shell_course_output_practice_route_test.dart` and roadmap action coverage in `test/unit/course/presentation/widgets/roadmap_node_action_helper_output_practice_test.dart`.

Final verification passed with `flutter analyze` and `flutter test`.

## What We Tried

We wired the shell first, then tightened the runtime state machine after review exposed the async reconcile and stale-session issues. We rejected pushing retry logic down into leaf widgets because it would have hidden session ownership and made the race harder to reason about.

## Root Cause Analysis

Weak session ownership. Late async work could still reconcile against a session that was no longer current, so retry paths reused or mutated stale state. The fix was to make the shell and socket/runtime helpers treat session identity as authoritative and drop late updates.

## Lessons Learned

Do not call a shell flow done until retry, reconnect, and late-completion paths are covered. Async orchestration needs explicit invalidation, not optimistic guards. Keep lifecycle control in one place so stale state cannot sneak across retries.

## Next Steps

Track reconnect/resume behavior with a live integration test later. Unit coverage is good enough for now, but the real socket timing path is still the weak spot if this regresses in the wild.

**Status:** DONE
**Summary:** Journal entry written to `docs/journals/260330-0957-output-practice-implementation-session.md`.
**Concerns/Blockers:** none
