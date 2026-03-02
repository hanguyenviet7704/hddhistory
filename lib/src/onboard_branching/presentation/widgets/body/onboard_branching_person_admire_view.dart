part of '../../../onboard_branching.dart';

class OnboardBranchingPersonAdmireSelectView extends StatelessWidget {
  const OnboardBranchingPersonAdmireSelectView({
    super.key,
    required this.question,
    required this.subQuestion,
    required this.options,
    required this.selectedOptionName,
    required this.onSelect,
    required this.onContinue,
    required this.continueEnabled,
  });

  final String question;
  final String subQuestion;
  final List<OnboardingScenarioPersonOptionEntity> options;
  final String? selectedOptionName;
  final ValueChanged<OnboardingScenarioPersonOptionEntity> onSelect;
  final VoidCallback onContinue;
  final bool continueEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (subQuestion.trim().isNotEmpty)
            DText(
              text: subQuestion,
              textAlign: TextAlign.center,
              textType: DTextType.textDefault,
              color: const Color(0xB3110751),
            ),
          DText(
            text: question,
            textAlign: TextAlign.center,
            textType: DTextType.titleLarge,
            color: const Color(0xFF110751),
            fontWeight: FontWeight.w700,
          ),
          16.verticalSpace,
          Expanded(
            child: ListView.separated(
              itemCount: options.length,
              separatorBuilder: (_, _) => 12.verticalSpace,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option.name == selectedOptionName;
                return InkWell(
                  onTap: () => onSelect(option),
                  borderRadius: BorderRadius.circular(16.r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF4B44CA) : Colors.transparent,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? null
                          : const [
                              BoxShadow(
                                color: Color(0x3CE7E7E9),
                                blurRadius: 3,
                                offset: Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: option.image?.trim().isNotEmpty == true
                              ? CacheNetworkGraphic(
                                  url: option.image!,
                                  width: 44.w,
                                  height: 44.w,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 44.w,
                                  height: 44.w,
                                  color: const Color(0xFFC7C5FA),
                                ),
                        ),
                        12.horizontalSpace,
                        Expanded(
                          child: DText(
                            text: option.name,
                            textAlign: TextAlign.start,
                            textType: DTextType.textDefault,
                            color: isSelected ? const Color(0xFF0D121C) : const Color(0xFF364152),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          12.verticalSpace,
          OnboardBranchingPrimaryButton(
            text: context.text.onboarding.onboardingSkipGreetingButton,
            enabled: continueEnabled,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

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
                          child: _OnboardBranchingTagChip(
                            text: badgeTexts[0],
                            backgroundColor: const Color(0xFFD9C3F2),
                            textColor: const Color(0xFF4A3979),
                          ),
                        ),
                        Positioned(
                          left: 24.w,
                          bottom: 110.h,
                          child: _OnboardBranchingTagChip(
                            text: badgeTexts[1],
                            backgroundColor: const Color(0xFFB2DDFF),
                            textColor: const Color(0xFF294575),
                          ),
                        ),
                        Positioned(
                          left: 34.w,
                          bottom: 68.h,
                          child: _OnboardBranchingTagChip(
                            text: badgeTexts[2],
                            backgroundColor: const Color(0xFFFECDCA),
                            textColor: const Color(0xFF773531),
                          ),
                        ),
                        Positioned(
                          left: 8.w,
                          bottom: 28.h,
                          child: _OnboardBranchingTagChip(
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

class _OnboardBranchingTagChip extends StatelessWidget {
  const _OnboardBranchingTagChip({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(1000.r),
      ),
      child: AppText(
        text,
        style: AppStyle.text10.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
          height: 1.75,
        ),
      ),
    );
  }
}
