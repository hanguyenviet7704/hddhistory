part of '../../home.dart';

class SkillsetCardWidget extends StatelessWidget {
  final SkillsetEntity skillset;
  final VoidCallback? onTap;

  const SkillsetCardWidget({
    super.key,
    required this.skillset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundGray,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Skillset title
                  AppText(
                    skillset.title.text,
                    style: AppStyle.textBold14.copyWith(
                      color: AppCustomColor.textPrimary,
                    ),
                    maxLines: 2,
                  ),
                  4.verticalSpace,
                  // Course count
                  AppText(
                    context.text.home.coursesCount(count: skillset.courses.length),
                    style: AppStyle.text12.copyWith(
                      color: AppCustomColor.textTertiary,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            // Skillset image
            Expanded(
              child: skillset.image.isNotEmpty
                  ? CacheNetworkGraphic(
                      borderRadius: BorderRadius.all(Radius.circular(16.r)),
                      url: skillset.image,
                      alignment: Alignment.bottomRight,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    )
                  : Icon(
                      Icons.category,
                      color: AppCustomColor.textTertiary,
                      size: 40.w,
                    ),
            ),

            // Skillset info
          ],
        ),
      ),
    );
  }
}
