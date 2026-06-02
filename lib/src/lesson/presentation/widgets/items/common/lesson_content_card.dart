part of '../../../../lesson.dart';

class LessonContentCard extends StatelessWidget {
  const LessonContentCard({
    super.key,
    required this.child,
    this.padding,
    this.minHeight,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final effectiveMinHeight = minHeight ?? LessonCardMinHeightScope.maybeOf(context);

    return Container(
      width: double.infinity,
      constraints: effectiveMinHeight == null ? null : BoxConstraints(minHeight: effectiveMinHeight),
      padding: padding ?? EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppCustomColor.borderDefault,
            blurRadius: 4.r,
          ),
        ],
      ),
      child: child,
    );
  }
}

class LessonCardMinHeightScope extends InheritedWidget {
  const LessonCardMinHeightScope({
    super.key,
    required this.minHeight,
    required super.child,
  });

  final double minHeight;

  static double? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LessonCardMinHeightScope>()?.minHeight;
  }

  @override
  bool updateShouldNotify(LessonCardMinHeightScope oldWidget) => minHeight != oldWidget.minHeight;
}
