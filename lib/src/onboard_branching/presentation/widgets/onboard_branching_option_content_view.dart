part of '../../onboard_branching.dart';

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
            DText(
              text: subTitle,
              textAlign: TextAlign.center,
              textType: DTextType.textDefault,
            ),
          DText(
            text: title,
            textAlign: TextAlign.center,
            textType: DTextType.titleLarge,
          ),
          16.verticalSpace,
          Expanded(
            child: ListView.separated(
              itemCount: options.length,
              separatorBuilder: (_, _) => 12.verticalSpace,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option.id == selectedOptionId;
                return InkWell(
                  onTap: () => onSelect(option.id),
                  borderRadius: BorderRadius.circular(16.r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF554FF0) : const Color(0xFFE5E7EB),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (option.icon.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(right: 10.w, top: 2.h),
                            child: CacheNetworkGraphic(
                              url: option.icon,
                              width: 20.w,
                              height: 20.w,
                            ),
                          ),
                        Expanded(
                          child: DText(
                            text: option.label,
                            textAlign: TextAlign.start,
                            textType: DTextType.textDefault,
                          ),
                        ),
                        8.horizontalSpace,
                        Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? const Color(0xFF554FF0) : const Color(0xFF9CA3AF),
                          size: 20.w,
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
