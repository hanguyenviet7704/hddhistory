import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  final now = DateTime(2026, 7, 27, 22, 0);

  HabitReloadAction resolve({
    required HabitPageStatus status,
    DateTime? lastLoadedAt,
  }) {
    return resolveHabitReloadAction(
      status: status,
      lastLoadedAt: lastLoadedAt,
      now: now,
    );
  }

  group('resolveHabitReloadAction', () {
    test('blocks with a spinner on the very first load', () {
      expect(
        resolve(status: HabitPageStatus.initial),
        HabitReloadAction.blocking,
      );
    });

    test('blocks again after a failed load so the retry can show progress', () {
      expect(
        resolve(status: HabitPageStatus.failure),
        HabitReloadAction.blocking,
      );
    });

    test('does nothing while a load is already running', () {
      expect(
        resolve(status: HabitPageStatus.loading),
        HabitReloadAction.none,
      );
    });

    test('does nothing when a recent load already confirmed the state', () {
      // The case that made the Habit tab feel slow for accounts with NO habits:
      // "empty" used to be indistinguishable from "never loaded", so every Home
      // mount and every tab entry refetched behind a blocking spinner.
      expect(
        resolve(
          status: HabitPageStatus.success,
          lastLoadedAt: now.subtract(const Duration(seconds: 5)),
        ),
        HabitReloadAction.none,
      );
    });

    test('refreshes silently once the loaded data goes stale', () {
      expect(
        resolve(
          status: HabitPageStatus.success,
          lastLoadedAt: now.subtract(kHabitFreshnessWindow).subtract(const Duration(seconds: 1)),
        ),
        HabitReloadAction.silent,
      );
    });

    test('blocks when success was emitted without a load timestamp (cache-only render)', () {
      expect(
        resolve(status: HabitPageStatus.success, lastLoadedAt: null),
        HabitReloadAction.blocking,
      );
    });
  });
}
