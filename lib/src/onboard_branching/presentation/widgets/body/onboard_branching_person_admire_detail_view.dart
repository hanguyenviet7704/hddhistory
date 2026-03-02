part of '../../../onboard_branching.dart';

class OnboardBranchingPersonAdmireDetailView extends StatelessWidget {
  const OnboardBranchingPersonAdmireDetailView({
    super.key,
    required this.option,
    required this.onContinue,
  });

  final OnboardingScenarioPersonOptionEntity option;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final factText = option.subTitle.text.trim().isNotEmpty ? option.subTitle.text : option.title.text;
    final badgeTexts = _buildBadgeTexts(context, option);

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
                  SizedBox(
                    width: double.infinity,
                    height: 330.h,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 200.w,
                          height: 300.h,
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
                        ),
                        Positioned(
                          top: 12.h,
                          right: 32.w,
                          child: OnboardBranchingPersonAdmireTagChip(
                            text: badgeTexts[0],
                            backgroundColor: const Color(0xFFD9C3F2),
                            textColor: const Color(0xFF4A3979),
                          ),
                        ),
                        Positioned(
                          left: 24.w,
                          bottom: 110.h,
                          child: OnboardBranchingPersonAdmireTagChip(
                            text: badgeTexts[1],
                            backgroundColor: const Color(0xFFB2DDFF),
                            textColor: const Color(0xFF294575),
                          ),
                        ),
                        Positioned(
                          left: 34.w,
                          bottom: 68.h,
                          child: OnboardBranchingPersonAdmireTagChip(
                            text: badgeTexts[2],
                            backgroundColor: const Color(0xFFFECDCA),
                            textColor: const Color(0xFF773531),
                          ),
                        ),
                        Positioned(
                          left: 8.w,
                          bottom: 28.h,
                          child: OnboardBranchingPersonAdmireTagChip(
                            text: badgeTexts[3],
                            backgroundColor: const Color(0xFFFEDF89),
                            textColor: const Color(0xFF6D4533),
                          ),
                        ),
                        if (option.image?.trim().isNotEmpty == true)
                          Positioned.fill(
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: Opacity(
                                  opacity: 0.9,
                                  child: CacheNetworkGraphic(
                                    url: option.image!,
                                    width: 200.w,
                                    height: 300.h,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  24.verticalSpace,
                  AppText(
                    context.text.onboarding.onboardingBranchingDidYouKnowTitle,
                    textAlign: TextAlign.center,
                    style: AppStyle.textBold20.copyWith(
                      color: const Color(0xFF110751),
                    ),
                  ),
                  4.verticalSpace,
                  DText(
                    text: factText,
                    textAlign: TextAlign.center,
                    textType: DTextType.textDefault,
                    color: const Color(0xB3110751),
                  ),
                ],
              ),
            ),
          ),
          12.verticalSpace,
          OnboardBranchingPrimaryButton(
            text: context.text.onboarding.onboardingSkipGreetingButton,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }

  List<String> _buildBadgeTexts(BuildContext context, OnboardingScenarioPersonOptionEntity selectedOption) {
    final titleText = selectedOption.title.text.stripHtmlTags.trim();
    final subTitleText = selectedOption.subTitle.text.stripHtmlTags.trim();
    final nameText = selectedOption.name.stripHtmlTags.trim();
    final candidates = <String>[
      titleText,
      subTitleText,
      nameText,
      selectedOption.name.replaceAll('_', ' ').trim(),
    ].map(_normalizeTag).where((item) => item.isNotEmpty).toList();

    if (candidates.length >= 4) return candidates.take(4).toList();

    final localizedFallbacks = <String>[
      context.text.onboarding.onboardingBranchingBadgeFallbackOne,
      context.text.onboarding.onboardingBranchingBadgeFallbackTwo,
      context.text.onboarding.onboardingBranchingBadgeFallbackOne,
      context.text.onboarding.onboardingBranchingBadgeFallbackTwo,
    ].map(_normalizeTag).where((item) => item.isNotEmpty);

    candidates.addAll(localizedFallbacks);
    while (candidates.length < 4) {
      candidates.add('•');
    }
    return candidates.take(4).toList();
  }

  String _normalizeTag(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return '';
    if (normalized.length <= 22) return normalized;
    return '${normalized.substring(0, 19)}...';
  }
}
