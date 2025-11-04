part of '../../course.dart';

class TimelineIndicator extends StatelessWidget {
  final ProcessEnum process;

  const TimelineIndicator({
    super.key,
    required this.process,
  });

  @override
  Widget build(BuildContext context) {
    return ContainerIndicator(
      size: 24.0,
      child: Container(
        width: 24.w,
        height: 24.h,
        decoration: _getDecoration(),
        child: _getIcon(),
      ),
    );
  }

  BoxDecoration _getDecoration() {
    switch (process) {
      case ProcessEnum.done:
        return BoxDecoration(
          color: AppCustomColor.brandPrimary,
          shape: BoxShape.circle,
        );
      case ProcessEnum.inProgress:
        return BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppCustomColor.brandPrimary,
            width: 3.w,
          ),
        );
      case ProcessEnum.notStarted:
        return BoxDecoration(
          color: AppCustomColor.borderSecondary,
          shape: BoxShape.circle,
        );
    }
  }

  Widget? _getIcon() {
    switch (process) {
      case ProcessEnum.done:
        return Icon(
          Icons.check_rounded,
          size: 16.w,
          color: AppCustomColor.backgroundWhite,
        );
      case ProcessEnum.notStarted:
        return Icon(
          Icons.lock_rounded,
          size: 14.w,
          color: AppCustomColor.textQuaternary,
        );
      case ProcessEnum.inProgress:
        return null; // Empty circle with border
    }
  }
}
