part of '../../learning_streak.dart';

class LearningStreakModalGuard {
  const LearningStreakModalGuard._();

  static bool hasBlockingModal(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null) return true;
    return !route.isCurrent;
  }
}
