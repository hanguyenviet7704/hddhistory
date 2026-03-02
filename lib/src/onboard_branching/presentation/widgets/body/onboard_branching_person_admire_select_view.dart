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
                return OnboardBranchingSelectableOptionCard(
                  label: option.name,
                  isSelected: isSelected,
                  onTap: () => onSelect(option),
                  leadingImageUrl: option.image ?? '',
                  leadingSize: 44,
                  placeholderColor: const Color(0xFFC7C5FA),
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
