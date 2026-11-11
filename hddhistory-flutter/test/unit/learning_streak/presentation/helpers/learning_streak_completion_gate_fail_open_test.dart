import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hddhistory/hddhistory.dart';

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
  group('LearningStreakCompletionGate fail-open behavior', () {
    setUp(() async {
      await setupLocaleCubitForTests();
    });

    tearDown(() async {
      await resetInjectorForTests();
    });

    testWidgets('skips overlay and commit on repository failure', (tester) async {
      var overlayCount = 0;
      final harness = _registerGateHarness(
        (_) => TaskEither.left(const AppException.server('boom')),
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
      expect(harness.learningStreakCubit.state.lastStreakCountedDay, isNull);

      await _closeGateHarness(harness);
    });

    testWidgets('skips overlay and commit on timeout outcome', (tester) async {
      var overlayCount = 0;
      final harness = _registerGateHarness(
        (_) => TaskEither.left(const AppException.pending('learning_streak_timeout')),
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
      expect(harness.learningStreakCubit.state.lastStreakCountedDay, isNull);

      await _closeGateHarness(harness);
    });

    testWidgets('skips overlay and commit on ignored stale user response', (tester) async {
      var overlayCount = 0;
      late _GateHarness harness;
      harness = _registerGateHarness(
        (_) {
          harness.userCubit.setTestUser(const UserEntity(id: 'user-2'));
          return _remoteStreak(4);
        },
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
      expect(harness.learningStreakCubit.state.lastStreakCountedDay, isNull);

      await _closeGateHarness(harness);
    });

    testWidgets('returns failedOpen when repository throws before task creation', (tester) async {
      var overlayCount = 0;
      final harness = _registerGateHarness(
        (_) => throw StateError('unexpected repository error'),
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

      expect(result, LearningStreakCompletionGateResult.failedOpen);
      expect(overlayCount, 0);
      expect(harness.learningStreakCubit.state.lastStreakCountedDay, isNull);

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
