part of '../../onboard_branching.dart';

class OnboardBranchingRecommendationView extends StatelessWidget {
  const OnboardBranchingRecommendationView({
    super.key,
    required this.percent,
    required this.course,
    required this.isLoadingTryNow,
    required this.onTryNow,
    required this.onChooseMyself,
  });

  final double percent;
  final CourseEntity course;
  final bool isLoadingTryNow;
  final VoidCallback onTryNow;
  final VoidCallback onChooseMyself;

  @override
  Widget build(BuildContext context) {
    final percentText = percent > 0 ? '${percent.toStringAsFixed(2)}%' : '--';
    final courseTitle = course.title.text.trim().isNotEmpty ? course.title.text : 'A recommended course for you';
    final courseSubtitle = course.description.text.trim().isNotEmpty ? course.description.text : 'We matched this based on your branching responses.';

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 108.w,
                    height: 108.w,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEEF2FF),
                    ),
                    alignment: Alignment.center,
                    child: AppText(
                      percentText,
                      textAlign: TextAlign.center,
                      style: AppStyle.textBold24.copyWith(color: const Color(0xFF4F46E5)),
                    ),
                  ),
                  20.verticalSpace,
                  AppText(
                    'Your personalized recommendation',
                    textAlign: TextAlign.center,
                    style: AppStyle.textBold20.copyWith(color: const Color(0xFF111827)),
                  ),
                  14.verticalSpace,
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          courseTitle,
                          maxLines: 3,
                          textAlign: TextAlign.start,
                          style: AppStyle.text16.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        8.verticalSpace,
                        DText(
                          text: courseSubtitle,
                          textAlign: TextAlign.start,
                          textType: DTextType.textDefault,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          OnboardBranchingPrimaryButton(
            text: context.text.onboarding.onboardingStartNowButton,
            loading: isLoadingTryNow,
            onPressed: onTryNow,
          ),
          10.verticalSpace,
          SizedBox(
            height: 52.h,
            child: OutlinedButton(
              onPressed: isLoadingTryNow ? null : onChooseMyself,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1000.r)),
              ),
              child: AppText(
                'I want to choose myself',
                style: AppStyle.text16.copyWith(
                  color: const Color(0xFF334155),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
