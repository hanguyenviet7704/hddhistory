part of '../../../course.dart';

class RoadmapRoleplayCard extends StatelessWidget {
  final LessonEntity lesson;
  final bool isLocked;
  final VoidCallback? onTap;

  const RoadmapRoleplayCard({
    super.key,
    required this.lesson,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppCustomColor.brandPrimary, // Purple border as seen in Figma
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppCustomColor.brandPrimary.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            if (lesson.image.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  lesson.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppCustomColor.backgroundGray,
                    child: Center(
                      child: SvgPicture.asset(
                        AppAsset.svg.app.icLayer, // Fallback icon
                        colorFilter: ColorFilter.mode(
                          AppCustomColor.textQuaternary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              // Placeholder if no image
              Container(
                height: 120.h,
                color: AppCustomColor.backgroundGray,
                child: Center(
                  child: SvgPicture.asset(
                    AppAsset.svg.app.icLayer,
                    colorFilter: ColorFilter.mode(
                      AppCustomColor.textQuaternary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),

            // Content Section
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    lesson.title.text,
                    style: AppStyle.textBold18.copyWith(
                      color: AppCustomColor.brandPrimary,
                    ),
                  ),
                  8.verticalSpace,
                  Row(
                    children: [
                      SvgPicture.asset(
                        AppAsset.svg.app.icClock,
                        width: 16.w,
                        colorFilter: ColorFilter.mode(
                          AppCustomColor.textSecondary,
                          BlendMode.srcIn,
                        ),
                      ),
                      8.horizontalSpace,
                      AppText(
                        lesson.estimateCompleTime.text,
                        style: AppStyle.text14.copyWith(
                          color: AppCustomColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
