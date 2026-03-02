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
    final percentText = percent > 0 ? '${percent.toStringAsFixed(1)} %' : '--';
    final courseTitle = course.title.text.trim().isNotEmpty ? course.title.text : context.text.onboarding.onboardingBranchingRecommendationDefaultTitle;
    final courseSubtitle = course.description.text.trim().isNotEmpty ? course.description.text : context.text.onboarding.onboardingBranchingRecommendationDefaultSubtitle;

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
                  12.verticalSpace,
                  Container(
                    width: 199.w,
                    height: 250.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3CE7E7E9),
                          blurRadius: 3,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.fromLTRB(16.w, 22.h, 16.w, 22.h),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: course.image.trim().isNotEmpty
                          ? CacheNetworkGraphic(
                              url: course.image,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: const Color(0xFFEBEAFD),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                size: 46.w,
                                color: const Color(0xFF554FF0),
                              ),
                            ),
                    ),
                  ),
                  16.verticalSpace,
                  AppText(
                    context.text.onboarding.onboardingBranchingRecommendationLabel,
                    textAlign: TextAlign.center,
                    style: AppStyle.text13.copyWith(
                      color: const Color(0x80110751),
                      fontWeight: FontWeight.w600,
                      height: 1.75,
                    ),
                  ),
                  4.verticalSpace,
                  DText(
                    text: courseTitle,
                    textAlign: TextAlign.center,
                    textType: DTextType.titleLarge,
                    color: const Color(0xFF110751),
                    fontWeight: FontWeight.w700,
                  ),
                  24.verticalSpace,
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBEAFD),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3CE7E7E9),
                          blurRadius: 3,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 36.w,
                          color: const Color(0xFF32B38C),
                        ),
                        12.horizontalSpace,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                '$percentText ${context.text.onboarding.onboardingBranchingRecommendationUsersSuffix}',
                                maxLines: 1,
                                textAlign: TextAlign.start,
                                style: AppStyle.textBold24.copyWith(
                                  color: const Color(0xFF110751),
                                  fontSize: 30.sp,
                                  height: 1.1,
                                ),
                              ),
                              DText(
                                text: courseSubtitle,
                                textAlign: TextAlign.start,
                                textType: DTextType.textSmall,
                                color: const Color(0xB3110751),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          16.verticalSpace,
          OnboardBranchingPrimaryButton(
            text: context.text.onboarding.onboardingStartNowButton,
            loading: isLoadingTryNow,
            onPressed: onTryNow,
          ),
          8.verticalSpace,
          SizedBox(
            height: 44.h,
            child: TextButton(
              onPressed: isLoadingTryNow ? null : onChooseMyself,
              child: AppText(
                context.text.onboarding.onboardingBranchingChooseMyselfButton,
                style: AppStyle.text16.copyWith(
                  color: const Color(0xB3110751),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
