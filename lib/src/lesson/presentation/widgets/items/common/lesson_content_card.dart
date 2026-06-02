part of '../../../../lesson.dart';

class LessonContentCard extends StatelessWidget {
  const LessonContentCard({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
