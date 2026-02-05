part of '../../../course.dart';

class CompletionCheckIcon extends StatelessWidget {
  final bool isCompleted;

  const CompletionCheckIcon({
    super.key,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24.w,
      height: 24.h,
      decoration: BoxDecoration(
        color: isCompleted ? AppCustomColor.brandPrimary : AppCustomColor.buttonDisable,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.check,
          color: AppCustomColor.textWhite,
          size: 13.33.sp,
        ),
      ),
    );
  }
}
