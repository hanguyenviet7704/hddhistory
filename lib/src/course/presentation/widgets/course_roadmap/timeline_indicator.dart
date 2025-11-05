part of '../../../course.dart';

class TimelineIndicator extends StatelessWidget {
  final ProcessEnum process;

  const TimelineIndicator({
    super.key,
    required this.process,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 21.w,
      height: 21.w,
      padding: EdgeInsets.all(3.w),
      decoration: _getDecoration(),
      child: _getIcon(),
    );
  }

  BoxDecoration _getDecoration() {
    return switch (process) {
      ProcessEnum.done => BoxDecoration(
        color: AppCustomColor.brandPrimary,
        shape: BoxShape.circle,
      ),
      ProcessEnum.inProgress => BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppCustomColor.brandPrimary,
          width: 3.w,
        ),
      ),
      ProcessEnum.notStarted => BoxDecoration(
        color: AppCustomColor.borderSecondary,
        shape: BoxShape.circle,
      ),
    };
  }

  Widget? _getIcon() {
    return switch (process) {
      ProcessEnum.done => Icon(
        Icons.check_rounded,
        size: 16.w,
        color: AppCustomColor.backgroundWhite,
      ),
      ProcessEnum.notStarted => Icon(
        Icons.lock_rounded,
        size: 14.w,
        color: AppCustomColor.textQuaternary,
      ),
      ProcessEnum.inProgress => Container(
        decoration: BoxDecoration(
          color: AppCustomColor.brandPrimary,
          shape: BoxShape.circle,
        ),
      ),
    };
  }
}
