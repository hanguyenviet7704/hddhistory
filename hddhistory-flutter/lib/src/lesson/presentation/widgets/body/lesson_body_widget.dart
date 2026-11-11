part of '../../../lesson.dart';

/// Base class for all lesson body widgets.
/// Provides [buildBottomButton] contract used by [LessonBodyFactory].
abstract class LessonBodyWidget extends StatelessWidget {
  const LessonBodyWidget({super.key});

  Widget buildBottomButton(BuildContext context);

  /// Whether this body already draws its own Check / result affordance inside
  /// the card (Keypoint v2 design), so the host must NOT also float
  /// [buildBottomButton] over the deck.
  ///
  /// Only the four exercise types the v2 design covers opt in; the rest keep
  /// the screen-wide sticky button. Roleplay always calls
  /// [buildBottomButton] directly and ignores this.
  bool get rendersOwnAction => false;
}
