part of '../../learning_streak.dart';

enum LearningStreakCompletionGateResult {
  skippedSameDay,
  skippedNotRemotePositive,
  skippedBlockedModal,
  skippedUnmounted,
  committed,
  dismissedOrUncommitted,
  failedOpen,
}

typedef LearningStreakOverlayPresenter =
    Future<bool> Function(
      BuildContext context,
      UserLearningStreakEntity streak,
    );

class LearningStreakCompletionGate {
  const LearningStreakCompletionGate._();

  static Future<LearningStreakCompletionGateResult> run(
    BuildContext context, {
    DateTime? nowUtc,
    Duration timeout = const Duration(seconds: 2),
    LearningStreakOverlayPresenter? showOverlay,
  }) async {
    try {
      final userCubit = AppDI.injector.get<UserCubit>();
      final learningStreakCubit = AppDI.injector.get<LearningStreakCubit>();
      final gateUtcDay = resolveGateUtcDay(nowUtc ?? DateTime.now().toUtc());

      if (learningStreakCubit.isSameStreakCountedUtcDay(gateUtcDay)) {
        return LearningStreakCompletionGateResult.skippedSameDay;
      }

      final streakResult = await learningStreakCubit.loadUserLearningStreak(
        triggerSource: LearningStreakTriggerSource.completionCta,
        requestedUserId: userCubit.state.user.id,
        timeout: timeout,
      );

      if (!context.mounted) {
        return LearningStreakCompletionGateResult.skippedUnmounted;
      }

      if (!streakResult.isRemoteSuccessWithPositiveStreak) {
        return LearningStreakCompletionGateResult.skippedNotRemotePositive;
      }

      if (LearningStreakModalGuard.hasBlockingModal(context)) {
        return LearningStreakCompletionGateResult.skippedBlockedModal;
      }

      final presenter =
          showOverlay ??
          (BuildContext overlayContext, UserLearningStreakEntity streak) {
            return LearningStreakSuccessOverlay.show(
              overlayContext,
              streak: streak,
            );
          };
      final committed = await presenter(context, streakResult.streak);

      if (!context.mounted) {
        return LearningStreakCompletionGateResult.skippedUnmounted;
      }

      if (committed) {
        learningStreakCubit.setLastStreakCountedDate(gateUtcDay);
        return LearningStreakCompletionGateResult.committed;
      }

      return LearningStreakCompletionGateResult.dismissedOrUncommitted;
    } catch (_) {
      return LearningStreakCompletionGateResult.failedOpen;
    }
  }

  @visibleForTesting
  static DateTime resolveGateUtcDay(DateTime value) {
    final utc = value.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }
}
