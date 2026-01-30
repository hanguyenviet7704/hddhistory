part of '../../../course.dart';

class LessonKeypointCard extends StatelessWidget {
  final KeypointEntity keypoint;
  final VoidCallback? onTap;

  const LessonKeypointCard({
    super.key,
    required this.keypoint,
    this.onTap,
  });

  Color get _textColor {
    switch (keypoint.progess) {
      case ProcessEnum.done:
        return AppCustomColor.textPrimary;
      case ProcessEnum.inProgress:
        return AppCustomColor.brandPrimary300;
      case ProcessEnum.notStarted:
        return AppCustomColor.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            constraints: BoxConstraints(minHeight: 44.h, minWidth: double.infinity),
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundWhite,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: keypoint.progess == ProcessEnum.inProgress ? AppCustomColor.brandPrimary : AppCustomColor.borderDefault,
                width: keypoint.progess == ProcessEnum.inProgress ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppCustomColor.borderDefault, // WhiteOnGray shadow from Figma
                  blurRadius: 4,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: AppText(
              keypoint.title.text,
              style: AppStyle.text14.copyWith(
                fontWeight: FontWeight.w500,
                color: _textColor,
                height: 1.75,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
