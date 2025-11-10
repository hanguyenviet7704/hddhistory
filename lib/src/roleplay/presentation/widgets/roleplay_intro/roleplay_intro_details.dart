part of '../../../roleplay.dart';

class RoleplayIntroDetails extends StatelessWidget {
  final LearningItemEntity learningItem;

  const RoleplayIntroDetails({
    super.key,
    required this.learningItem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          learningItem.title.text,
          maxLines: 2,
          style: AppStyle.text32.copyWith(
            fontWeight: FontWeight.w700,
            color: AppCustomColor.textWhite,
            height: 40 / 32,
          ),
        ),
        12.verticalSpace,
        if (learningItem.estimateCompleTime.text.isNotEmpty)
          AppText(
            learningItem.estimateCompleTime.text,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: AppCustomColor.textWhite,
              letterSpacing: 0.2,
            ),
          ),
        12.verticalSpace,
        AppText(
          learningItem.description.text,
          maxLines: 6,
          style: AppStyle.text16.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            height: 24 / 16,
          ),
        ),
      ],
    );
  }
}
