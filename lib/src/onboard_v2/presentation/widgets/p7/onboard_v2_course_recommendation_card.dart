part of '../../../onboard_v2.dart';

class OnboardV2CourseRecommendationCard extends StatelessWidget {
  const OnboardV2CourseRecommendationCard({super.key, required this.course});

  final CourseEntity course;

  @override
  Widget build(BuildContext context) {
    final image = course.image.trim();
    final onboardingL10n = context.l10n.onboarding;
    return Column(
      children: [
        Container(
          width: 250.w,
          height: 250.w,
          padding: EdgeInsets.all(45.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: const [BoxShadow(color: Color(0x3DE7E7E9), blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: image.isNotEmpty ? Image.network(image, fit: BoxFit.cover, errorBuilder: (_, _, _) => _fallback()) : _fallback(),
          ),
        ),
        22.verticalSpace,
        AppText(
          onboardingL10n.onboardingV2P7Label.toUpperCase(),
          textAlign: TextAlign.center,
          style: AppStyle.text13.copyWith(color: AppCustomColor.textBrand.op(0.5), fontWeight: FontWeight.w700),
        ),
        8.verticalSpace,
        AppText(
          course.title.text.isNotEmpty ? course.title.text : onboardingL10n.onboardingV2P7CourseTitleFallback,
          textAlign: TextAlign.center,
          overflow: TextOverflow.visible,
          style: AppStyle.text20.copyWith(color: AppCustomColor.textBrand, fontWeight: FontWeight.w800),
        ),
        16.verticalSpace,
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(color: AppCustomColor.backgroundBrand, borderRadius: BorderRadius.circular(12.r)),
          child: Row(
            children: [
              Image.asset(AppAsset.images.app.successDecoration.path, width: 35.w, height: 35.w),
              12.horizontalSpace,
              Expanded(
                child: AppText(
                  onboardingL10n.onboardingV2P7SocialProof,
                  overflow: TextOverflow.visible,
                  style: AppStyle.text14.copyWith(color: AppCustomColor.textBrand),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fallback() {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: OnboardV2GradientText.gradient),
      child: Center(
        child: Icon(Icons.menu_book_rounded, size: 64.w, color: Colors.white),
      ),
    );
  }
}
