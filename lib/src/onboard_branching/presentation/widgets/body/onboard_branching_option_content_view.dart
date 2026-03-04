part of '../../../onboard_branching.dart';

class OnboardBranchingOptionDisplayItem {
  const OnboardBranchingOptionDisplayItem({
    required this.id,
    required this.label,
    this.icon = '',
  });

  final String id;
  final String label;
  final String icon;
}

class OnboardBranchingOptionContentView extends StatelessWidget {
  const OnboardBranchingOptionContentView({
    super.key,
    required this.title,
    required this.subTitle,
    required this.options,
    required this.selectedOptionId,
    required this.onSelect,
    required this.onContinue,
    required this.continueEnabled,
  });

  final String title;
  final String subTitle;
  final List<OnboardBranchingOptionDisplayItem> options;
  final String? selectedOptionId;
  final ValueChanged<String> onSelect;
  final VoidCallback onContinue;
  final bool continueEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (subTitle.trim().isNotEmpty)
            AppText(
              subTitle,
              maxLines: 3,
              textAlign: TextAlign.center,
              style: AppStyle.text14.copyWith(
                color: const Color(0xB3110751),
              ),
            ),
          AppText(
            title,
            maxLines: 5,
            textAlign: TextAlign.center,
            style: AppStyle.text20.copyWith(
              color: const Color(0xFF110751),
              fontWeight: FontWeight.w700,
            ),
          ),
          16.verticalSpace,
          Spacer(),
          ListView.separated(
            itemCount: options.length,
            separatorBuilder: (_, _) => 12.verticalSpace,
            padding: EdgeInsets.symmetric(vertical: 20.h),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = option.id == selectedOptionId;
              return OnboardBranchingSelectableOptionCard(
                label: option.label,
                isSelected: isSelected,
                onTap: () => onSelect(option.id),
                leadingIconUrl: option.icon,
                leadingSize: 24,
                placeholderColor: Colors.transparent,
              );
            },
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
