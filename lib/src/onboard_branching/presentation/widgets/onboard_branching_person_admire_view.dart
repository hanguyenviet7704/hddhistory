part of '../../onboard_branching.dart';

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
            ),
          DText(
            text: question,
            textAlign: TextAlign.center,
            textType: DTextType.titleLarge,
          ),
          16.verticalSpace,
          Expanded(
            child: GridView.builder(
              itemCount: options.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option.name == selectedOptionName;
                return InkWell(
                  onTap: () => onSelect(option),
                  borderRadius: BorderRadius.circular(16.r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF554FF0) : const Color(0xFFE5E7EB),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: option.image?.trim().isNotEmpty == true
                                ? CacheNetworkGraphic(url: option.image!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                                : Container(
                                    color: const Color(0xFFF3F4F6),
                                    alignment: Alignment.center,
                                    child: Icon(Icons.person_outline_rounded, size: 32.w, color: const Color(0xFF9CA3AF)),
                                  ),
                          ),
                        ),
                        10.verticalSpace,
                        AppText(
                          option.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: AppStyle.text14.copyWith(
                            color: const Color(0xFF111827),
                            fontWeight: FontWeight.w600,
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: option.image?.trim().isNotEmpty == true
                        ? CacheNetworkGraphic(url: option.image!, width: 220.w, height: 220.w, fit: BoxFit.cover)
                        : Container(
                            width: 220.w,
                            height: 220.w,
                            color: const Color(0xFFF3F4F6),
                            alignment: Alignment.center,
                            child: Icon(Icons.person_outline_rounded, size: 44.w, color: const Color(0xFF9CA3AF)),
                          ),
                  ),
                  20.verticalSpace,
                  AppText(
                    option.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: AppStyle.textBold24.copyWith(color: const Color(0xFF111827)),
                  ),
                  10.verticalSpace,
                  DText(
                    text: option.title.text,
                    textAlign: TextAlign.center,
                    textType: DTextType.titleMedium,
                  ),
                  10.verticalSpace,
                  DText(
                    text: option.subTitle.text,
                    textAlign: TextAlign.center,
                    textType: DTextType.textDefault,
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
}
