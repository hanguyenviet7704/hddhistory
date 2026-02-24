part of '../../../lesson.dart';

/// Base class for all lesson body widgets.
/// Provides [buildBottomButton] contract used by [LessonBodyFactory].
abstract class LessonBodyWidget extends StatelessWidget {
  const LessonBodyWidget({super.key});

  Widget buildBottomButton(BuildContext context);
}
