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
            DText(
              text: subTitle,
              textAlign: TextAlign.center,
              textType: DTextType.textDefault,
              color: const Color(0xB3110751),
            ),
          DText(
            text: title,
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
                final isSelected = option.id == selectedOptionId;
                return InkWell(
                  onTap: () => onSelect(option.id),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: 12.w, top: 1.h),
                          child: option.icon.isNotEmpty
                              ? CacheNetworkGraphic(
                                  url: option.icon,
                                  width: 24.w,
                                  height: 24.w,
                                  fit: BoxFit.cover,
                                )
                              : SizedBox(width: 24.w, height: 24.w),
                        ),
                        Expanded(
                          child: DText(
                            text: option.label,
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
