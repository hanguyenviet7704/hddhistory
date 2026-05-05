part of '../../../onboard_v2.dart';

class OnboardV2CourseRecommendationCard extends StatelessWidget {
  const OnboardV2CourseRecommendationCard({super.key, required this.course});

  final CourseEntity course;

  @override
  Widget build(BuildContext context) {
    final image = course.image.trim();
    final onboardingL10n = context.l10n.onboarding;
    final socialProofLines = _resolveSocialProofLines(onboardingL10n.onboardingV2P7SocialProof);
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
            child: image.isNotEmpty
                ? DCachedImage(
                    url: image,
                    width: 160.w,
                    height: 160.w,
                    fit: BoxFit.cover,
                  )
                : _fallback(),
          ),
        ),
        24.verticalSpace,
        SizedBox(
          width: 303.w,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _labelStar(),
              8.horizontalSpace,
              AppText(
                onboardingL10n.onboardingV2P7Label.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppStyle.text13.copyWith(color: AppCustomColor.textBrand.op(0.5), fontWeight: FontWeight.w700),
              ),
              8.horizontalSpace,
              _labelStar(),
            ],
          ),
        ),
        4.verticalSpace,
        SizedBox(
          width: 303.w,
          child: AppText(
            course.title.text.isNotEmpty ? course.title.text : onboardingL10n.onboardingV2P7CourseTitleFallback,
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
            style: AppStyle.text20.copyWith(color: AppCustomColor.textBrand, fontWeight: FontWeight.w800),
          ),
        ),
        17.5.verticalSpace,
        Container(
          width: 303.w,
          constraints: BoxConstraints(minHeight: 98.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
          decoration: BoxDecoration(color: AppCustomColor.backgroundBrand, borderRadius: BorderRadius.circular(12.r)),
          child: Row(
            children: [
              Image.asset(AppAsset.images.app.successDecoration.path, width: 35.w, height: 35.w),
              12.horizontalSpace,
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: socialProofLines.first,
                        style: AppStyle.text16.copyWith(color: AppCustomColor.textBrand, fontWeight: FontWeight.w700, height: 1.5),
                      ),
                      if (socialProofLines.length > 1)
                        TextSpan(
                          text: '\n${socialProofLines.skip(1).join(' ')}',
                          style: AppStyle.text12.copyWith(color: AppCustomColor.textBrand.op(0.7), height: 1.5),
                        ),
                    ],
                  ),
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _labelStar() {
    return Icon(Icons.star_rounded, size: 8.w, color: AppCustomColor.textBrand.op(0.18));
  }

  Widget _fallback() {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: OnboardV2GradientText.gradient),
      child: Center(
        child: Icon(Icons.menu_book_rounded, size: 64.w, color: Colors.white),
      ),
    );
  }

  List<String> _resolveSocialProofLines(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return const [''];

    final lines = trimmed.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    if (lines.length > 1) return [lines.first, lines.skip(1).join(' ')];

    return switch (trimmed) {
      '93.8 % users feel more focused after this path' => const [
        '93.8 % users',
        'facing similar challenges have improved with this course',
      ],
      '93.8 % người dùng tập trung hơn sau lộ trình này' => const [
        '93.8 % người dùng',
        'có thử thách tương tự đã cải thiện với khóa học này',
      ],
      '93.8 % 用户在这条路径后感觉更专注' => const [
        '93.8 % 用户',
        '通过这门课程改善了类似挑战',
      ],
      _ => [trimmed],
    };
  }
}
