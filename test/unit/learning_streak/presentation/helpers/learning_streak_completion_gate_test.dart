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

class _TestUserCubit extends UserCubit {
  _TestUserCubit() : super(NoOpTrackingService());

  void setTestUser(UserEntity user) {
    emit(state.copyWith(auth: state.auth.copyWith(user: user)));
  }
}

void main() {
  group('LearningStreakCompletionGate', () {
    setUp(() async {
      await setupLocaleCubitForTests();
    });

    tearDown(() async {
      await resetInjectorForTests();
    });

    testWidgets('skips when the UTC day was already counted', (tester) async {
      var fetchCount = 0;
      final harness = _registerGateHarness(
        (_) {
          fetchCount += 1;
          return _remoteStreak(3);
        },
      );
      harness.learningStreakCubit.setLastStreakCountedDate(DateTime.utc(2026, 4, 22));

      final context = await _pumpGateContext(tester);
      final result = await LearningStreakCompletionGate.run(
        context,
        nowUtc: DateTime.utc(2026, 4, 22, 12),
      );

      expect(result, LearningStreakCompletionGateResult.skippedSameDay);
      expect(fetchCount, 0);

      await _closeGateHarness(harness);
    });

    testWidgets('commits the UTC day after a remote positive streak overlay commit', (tester) async {
      var overlayCount = 0;
      final harness = _registerGateHarness(
        (_) => _remoteStreak(5),
      );

      final context = await _pumpGateContext(tester);
      final result = await LearningStreakCompletionGate.run(
        context,
        nowUtc: DateTime.utc(2026, 4, 22, 9),
        showOverlay: (_, streak) async {
          overlayCount += 1;
          expect(streak.currentStreak, 5);
          return true;
        },
      );

      expect(result, LearningStreakCompletionGateResult.committed);
      expect(overlayCount, 1);
      // The latch stores the user's LOCAL day now, so derive the expectation the
      // same way rather than hard-coding a UTC midnight — otherwise this passes
      // or fails depending on the machine's timezone.
      expect(
        harness.learningStreakCubit.state.lastStreakCountedDay,
        StreakDay.resolve(DateTime.utc(2026, 4, 22, 9)),
      );

      await _closeGateHarness(harness);
    });

    testWidgets('skips non-remote-positive streak results without showing overlay', (tester) async {
      var overlayCount = 0;
      final harness = _registerGateHarness(
        (_) => _remoteStreak(0),
      );

      final context = await _pumpGateContext(tester);
      final result = await LearningStreakCompletionGate.run(
        context,
        nowUtc: DateTime.utc(2026, 4, 22, 9),
        showOverlay: (_, _) async {
          overlayCount += 1;
          return true;
        },
      );

      expect(result, LearningStreakCompletionGateResult.skippedNotRemotePositive);
      expect(overlayCount, 0);

      await _closeGateHarness(harness);
    });

    testWidgets('returns blocked-modal result without showing overlay', (tester) async {
      var overlayCount = 0;
      final harness = _registerGateHarness(
        (_) => _remoteStreak(2),
      );

      final context = await _pumpGateContext(tester);
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => const SizedBox.shrink(),
        ),
      );
      await tester.pumpAndSettle();

      final result = await LearningStreakCompletionGate.run(
        context,
        nowUtc: DateTime.utc(2026, 4, 22, 9),
        showOverlay: (_, _) async {
          overlayCount += 1;
          return true;
        },
      );

      expect(result, LearningStreakCompletionGateResult.skippedBlockedModal);
      expect(overlayCount, 0);

      Navigator.of(context).pop();
      await tester.pumpAndSettle();
      await _closeGateHarness(harness);
    });
  });
}

typedef _GateHarness = ({
  _TestUserCubit userCubit,
  LearningStreakCubit learningStreakCubit,
});

_GateHarness _registerGateHarness(
  TaskEither<AppException, LearningStreakFetchEntity> Function(String userId) handler,
) {
  final userCubit = _TestUserCubit()..setTestUser(const UserEntity(id: 'user-1'));
  final repository = _FakeLearningStreakRepository(handler);
  final learningStreakCubit = LearningStreakCubit(
    GetUserLearningStreakUseCase(repository),
    CheckInStreakUseCase(repository),
  );

  AppDI.injector.registerSingleton<UserCubit>(userCubit);
  AppDI.injector.registerSingleton<LearningStreakCubit>(learningStreakCubit);

  return (
    userCubit: userCubit,
    learningStreakCubit: learningStreakCubit,
  );
}

Future<void> _closeGateHarness(_GateHarness harness) async {
  await harness.learningStreakCubit.close();
  await harness.userCubit.close();
}

TaskEither<AppException, LearningStreakFetchEntity> _remoteStreak(int currentStreak) {
  return TaskEither.right(
    LearningStreakFetchEntity(
      streak: UserLearningStreakEntity(currentStreak: currentStreak),
      origin: LearningStreakDataOrigin.remote,
    ),
  );
}

Future<BuildContext> _pumpGateContext(WidgetTester tester) async {
  late BuildContext capturedContext;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          capturedContext = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return capturedContext;
}
