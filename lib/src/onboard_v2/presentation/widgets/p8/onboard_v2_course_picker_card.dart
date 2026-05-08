part of '../../../onboard_v2.dart';

class OnboardV2CoursePickerCard extends StatelessWidget {
  const OnboardV2CoursePickerCard({super.key, required this.course});

  final CourseEntity course;

  @override
  Widget build(BuildContext context) {
    final image = course.image.trim();
    final onboardingL10n = context.l10n.onboarding;
    final title = course.title.text.trim().isNotEmpty ? course.title.text.trim() : onboardingL10n.onboardingV2P8CourseTitleFallback;
    final description = course.description.text.trim();
    return Column(
      children: [
        Container(
          width: 260.w,
          height: 260.w,
          padding: EdgeInsets.all(28.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: const [BoxShadow(color: Color(0x3DE7E7E9), blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: image.isNotEmpty
                ? DCachedImage(
                    url: image,
                    width: 204.w,
                    height: 204.w,
                    fit: BoxFit.cover,
                  )
                : const DecoratedBox(
                    decoration: BoxDecoration(gradient: OnboardV2GradientText.gradient),
                    child: Center(child: Icon(Icons.menu_book_rounded, size: 64, color: Colors.white)),
                  ),
          ),
        ),
        20.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _labelStar(),
            8.horizontalSpace,
            AppText(
              onboardingL10n.onboardingV2P8Label.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppStyle.text13.copyWith(color: AppCustomColor.textBrand.op(0.5), fontWeight: FontWeight.w700),
            ),
            8.horizontalSpace,
            _labelStar(),
          ],
        ),
        6.verticalSpace,
        SizedBox(
          width: 303.w,
          child: AppText(
            title,
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
            style: AppStyle.text24.copyWith(color: AppCustomColor.textBrand, fontWeight: FontWeight.w800, height: 1.25),
          ),
        ),
        if (description.isNotEmpty) ...[
          8.verticalSpace,
          SizedBox(
            width: 303.w,
            child: AppText(
              description,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary, height: 1.5),
            ),
          ),
        ],
      ],
    );
  }

  Widget _labelStar() {
    return Icon(Icons.star_rounded, size: 8.w, color: AppCustomColor.textBrand.op(0.18));
  }
}
