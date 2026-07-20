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

    // ThemedGlassCard renders an identical opaque white card on the Default
    // preset (same colour/radius/shadow as before) and a frosted-glass panel
    // over a custom study background (design item 12) — width/min-height are
    // applied here since ThemedGlassCard itself doesn't take size constraints.
    return SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
        constraints: effectiveMinHeight == null ? const BoxConstraints() : BoxConstraints(minHeight: effectiveMinHeight),
        child: ThemedGlassCard(
          padding: padding ?? EdgeInsets.all(16.w),
          radius: 20,
          shadow: [
            BoxShadow(
              color: AppCustomColor.borderDefault,
              blurRadius: 4.r,
            ),
          ],
          child: child,
        ),
      ),
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
