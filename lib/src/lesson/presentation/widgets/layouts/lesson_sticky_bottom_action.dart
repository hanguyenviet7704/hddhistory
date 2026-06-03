part of '../../../lesson.dart';

class LessonStickyBottomAction extends StatelessWidget {
  const LessonStickyBottomAction({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(top: 24.h),
        child: child,
      ),
    );
  }
}
