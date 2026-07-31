import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

class _FakeLearningStreakRepository implements ILearningStreakRepository {
  _FakeLearningStreakRepository(this.handler);

  TaskEither<AppException, LearningStreakFetchEntity> Function(String userId) handler;

  /// Overridden per test that exercises the check-in path; the default is a
  /// success carrying whatever [handler] would return, so tests that only care
  /// about the read path need not set it.
  TaskEither<AppException, UserLearningStreakEntity> Function(String userId)? checkInHandler;

  @override
  TaskEither<AppException, LearningStreakFetchEntity> getUserLearningStreak(String userId) {
    return handler(userId);
  }

  @override
  TaskEither<AppException, UserLearningStreakEntity> checkInStreak(String userId) {
    final override = checkInHandler;
    if (override != null) return override(userId);
    return handler(userId).map((fetch) => fetch.streak);
  }

  @override
  TaskEither<AppException, StreakPopupConfigEntity> getStreakPopupConfig() {
    return TaskEither.right(const StreakPopupConfigEntity());
  }
}

void main() {
  group('LearningStreakCubit', () {
    setUp(() async {
      await setupLocaleCubitForTests();
    });

    tearDown(() async {
      await resetInjectorForTests();
    });

    test('emits success with remote origin', () async {
      final repo = _FakeLearningStreakRepository(
        (_) => TaskEither.right(
          const LearningStreakFetchEntity(
            streak: UserLearningStreakEntity(currentStreak: 4),
            origin: LearningStreakDataOrigin.remote,
          ),
        ),
      );
      final cubit = LearningStreakCubit(GetUserLearningStreakUseCase(repo), CheckInStreakUseCase(repo));

      final result = await cubit.loadUserLearningStreak(
        triggerSource: LearningStreakTriggerSource.completionCta,
        requestedUserId: 'user-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrigin, LearningStreakDataOrigin.remote);
      expect(cubit.state.status, LearningStreakStatus.success);
      expect(cubit.state.selectedItem.currentStreak, 4);

      await cubit.close();
    });

    test('returns timeout outcome when request exceeds timeout', () async {
      final repo = _FakeLearningStreakRepository(
        (_) => TaskEither.tryCatch(
          () async {
            await Future<void>.delayed(const Duration(milliseconds: 120));
            return const LearningStreakFetchEntity(
              streak: UserLearningStreakEntity(currentStreak: 2),
              origin: LearningStreakDataOrigin.remote,
            );
          },
          (error, _) => AppException.unexpected(error.toString()),
        ),
      );
      final cubit = LearningStreakCubit(GetUserLearningStreakUseCase(repo), CheckInStreakUseCase(repo));

      final result = await cubit.loadUserLearningStreak(
        triggerSource: LearningStreakTriggerSource.completionCta,
        requestedUserId: 'user-1',
        timeout: const Duration(milliseconds: 10),
      );

      expect(result.isTimeout, isTrue);
      expect(cubit.state.status, LearningStreakStatus.failure);

      await cubit.close();
    });

    test('ignores stale response when a newer request completes first', () async {
      final firstCompleter = Completer<LearningStreakFetchEntity>();
      final secondCompleter = Completer<LearningStreakFetchEntity>();
      var callCount = 0;

      final repo = _FakeLearningStreakRepository(
        (_) => TaskEither.tryCatch(
          () async {
            callCount += 1;
            if (callCount == 1) return firstCompleter.future;
            return secondCompleter.future;
          },
          (error, _) => AppException.unexpected(error.toString()),
        ),
      );
      final cubit = LearningStreakCubit(GetUserLearningStreakUseCase(repo), CheckInStreakUseCase(repo));

      final firstRequest = cubit.loadUserLearningStreak(
        triggerSource: LearningStreakTriggerSource.homeChip,
        requestedUserId: 'user-1',
        timeout: const Duration(seconds: 2),
      );

      final secondRequest = cubit.loadUserLearningStreak(
        triggerSource: LearningStreakTriggerSource.completionCta,
        requestedUserId: 'user-1',
        timeout: const Duration(seconds: 2),
      );

      secondCompleter.complete(
        const LearningStreakFetchEntity(
          streak: UserLearningStreakEntity(currentStreak: 2),
          origin: LearningStreakDataOrigin.remote,
        ),
      );
      final secondResult = await secondRequest;

      firstCompleter.complete(
        const LearningStreakFetchEntity(
          streak: UserLearningStreakEntity(currentStreak: 9),
          origin: LearningStreakDataOrigin.remote,
        ),
      );
      final firstResult = await firstRequest;

      expect(secondResult.isSuccess, isTrue);
      expect(firstResult.isIgnored, isTrue);
      expect(cubit.state.selectedItem.currentStreak, 2);

      await cubit.close();
    });

    test('keeps previous success streak when safe-default fallback is enabled', () async {
      final repo = _FakeLearningStreakRepository(
        (_) => TaskEither.right(
          const LearningStreakFetchEntity(
            streak: UserLearningStreakEntity(currentStreak: 6),
            origin: LearningStreakDataOrigin.remote,
          ),
        ),
      );
      final cubit = LearningStreakCubit(GetUserLearningStreakUseCase(repo), CheckInStreakUseCase(repo));

      await cubit.loadUserLearningStreak(
        triggerSource: LearningStreakTriggerSource.homeChip,
        requestedUserId: 'user-1',
      );

      repo.handler = (_) => TaskEither.left(AppException.unexpected('network'));
      final result = await cubit.loadUserLearningStreak(
        triggerSource: LearningStreakTriggerSource.homeChip,
        requestedUserId: 'user-1',
        allowSafeDefaultOnFailure: true,
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrigin, LearningStreakDataOrigin.remote);
      expect(result.streak.currentStreak, 6);
      expect(cubit.state.selectedItem.currentStreak, 6);

      await cubit.close();
    });
  });

  group('LearningStreakCubit.checkIn', () {
    setUp(() async {
      await setupLocaleCubitForTests();
    });

    tearDown(() async {
      await resetInjectorForTests();
    });

    test('emits the returned streak and latches today on success', () async {
      final repo = _FakeLearningStreakRepository((_) => _remoteStreak(0));
      repo.checkInHandler = (_) => TaskEither.right(
        const UserLearningStreakEntity(
          currentStreak: 3,
          weekStudy: [false, false, true, true, true, false, false],
        ),
      );
      final cubit = LearningStreakCubit(GetUserLearningStreakUseCase(repo), CheckInStreakUseCase(repo));

      final didCheckIn = await cubit.checkIn(requestedUserId: 'user-1');

      expect(didCheckIn, isTrue);
      expect(cubit.state.selectedItem.currentStreak, 3);
      expect(cubit.state.dataOrigin, LearningStreakDataOrigin.remote);
      // The toast reads its week strip straight off state, so the strip the
      // check-in responded with has to land there rather than be dropped.
      expect(cubit.state.selectedItem.weekStudy[4], isTrue);
      expect(cubit.isSameCheckInDay(StreakDay.today()), isTrue);

      await cubit.close();
    });

    test('leaves the day unlatched on failure so the next tick retries', () async {
      final repo = _FakeLearningStreakRepository((_) => _remoteStreak(0));
      repo.checkInHandler = (_) => TaskEither.left(AppException.unexpected('network'));
      final cubit = LearningStreakCubit(GetUserLearningStreakUseCase(repo), CheckInStreakUseCase(repo));

      final didCheckIn = await cubit.checkIn(requestedUserId: 'user-1');

      expect(didCheckIn, isFalse);
      // Latching here would cost the user the day: nothing was recorded server
      // side, and no further attempt would be made until tomorrow.
      expect(cubit.state.lastCheckInDate, isNull);
      expect(cubit.isSameCheckInDay(StreakDay.today()), isFalse);

      await cubit.close();
    });

    test('keeps the two once-a-day latches independent', () async {
      final repo = _FakeLearningStreakRepository((_) => _remoteStreak(0));
      repo.checkInHandler = (_) => TaskEither.right(const UserLearningStreakEntity(currentStreak: 1));
      final cubit = LearningStreakCubit(GetUserLearningStreakUseCase(repo), CheckInStreakUseCase(repo));

      await cubit.checkIn(requestedUserId: 'user-1');

      // The day is recorded but no toast has been shown, which is exactly the
      // state a `popupEnabled: false` config leaves behind.
      expect(cubit.isSameCheckInDay(StreakDay.today()), isTrue);
      expect(cubit.isSameStreakCountedDay(StreakDay.today()), isFalse);

      cubit.setLastStreakCountedDate(StreakDay.today());
      expect(cubit.isSameStreakCountedDay(StreakDay.today()), isTrue);

      await cubit.close();
    });
  });
}

TaskEither<AppException, LearningStreakFetchEntity> _remoteStreak(int currentStreak) {
  return TaskEither.right(
    LearningStreakFetchEntity(
      streak: UserLearningStreakEntity(currentStreak: currentStreak),
      origin: LearningStreakDataOrigin.remote,
    ),
  );
}
