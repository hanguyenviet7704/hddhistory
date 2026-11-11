part of '../../../onboard_v2.dart';

/// Thẻ khoá học của S10: ảnh bìa bo góc nằm trong một thẻ tím nhạt, dưới ảnh là
/// tên khoá và mô tả ngắn.
class OnboardV2CoursePickerCard extends StatelessWidget {
  const OnboardV2CoursePickerCard({super.key, required this.course});

  final CourseEntity course;

  static const _imageHeight = 236.0;

  @override
  Widget build(BuildContext context) {
    final onboardingL10n = context.l10n.onboarding;
    final image = course.image.trim();
    final title = course.title.text.trim().isNotEmpty ? course.title.text.trim() : onboardingL10n.onboardingV2P8CourseTitleFallback;
    final description = course.description.text.trim();

    return Container(
      decoration: BoxDecoration(
        color: AppCustomColor.onboardResultCardBg,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: AppCustomColor.onboardResultCardBorder, width: 1.5.w),
      ),
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: SizedBox(
              width: double.infinity,
              height: _imageHeight.h,
              child: image.isNotEmpty
                  ? DCachedImage(url: image, width: double.infinity, height: _imageHeight.h, fit: BoxFit.cover)
                  : ColoredBox(
                      color: AppCustomColor.borderBrand,
                      child: Center(
                        child: Icon(Icons.menu_book_rounded, size: 64.w, color: AppCustomColor.brandPrimary),
                      ),
                    ),
            ),
          ),
          16.verticalSpace,
          // Thẻ bị ép đúng chiều cao của bộ bài, còn tên khoá thì dài ngắn tuỳ
          // khoá — để co được thì chữ bị cắt bớt chứ không tràn khung.
          Flexible(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.text16.copyWith(
                      fontSize: 17.sp,
                      color: AppCustomColor.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      height: 1.3,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    8.verticalSpace,
                    AppText(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyle.text12.copyWith(
                        fontSize: 12.5.sp,
                        color: AppCustomColor.onboardResultCardDesc,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
