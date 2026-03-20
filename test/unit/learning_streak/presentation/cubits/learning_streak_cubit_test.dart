import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

class _FakeLearningStreakRepository implements ILearningStreakRepository {
  _FakeLearningStreakRepository(this.handler);

  TaskEither<AppException, LearningStreakFetchEntity> Function(String userId) handler;

  @override
  TaskEither<AppException, LearningStreakFetchEntity> getUserLearningStreak(String userId) {
    return handler(userId);
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
      final cubit = LearningStreakCubit(GetUserLearningStreakUseCase(repo));

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
      final cubit = LearningStreakCubit(GetUserLearningStreakUseCase(repo));

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
      final cubit = LearningStreakCubit(GetUserLearningStreakUseCase(repo));

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
      final cubit = LearningStreakCubit(GetUserLearningStreakUseCase(repo));

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
}
