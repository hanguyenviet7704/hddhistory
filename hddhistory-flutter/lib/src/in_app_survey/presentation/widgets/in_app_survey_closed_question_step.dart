part of '../../in_app_survey.dart';

class InAppSurveyClosedQuestionStep extends StatelessWidget {
  const InAppSurveyClosedQuestionStep({
    super.key,
    required this.branch,
    required this.selectedOptionIds,
    required this.onToggleOption,
  });

  final InAppSurveyBranchEntity branch;
  final List<String> selectedOptionIds;
  final ValueChanged<String> onToggleOption;

  @override
  Widget build(BuildContext context) {
    final options = branch.closedQuestion.options.where((option) => option.id.trim().isNotEmpty && _surveyText(option.value).isNotEmpty).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InAppSurveyTitle(_surveyText(branch.closedQuestion.question)),
        2.verticalSpace,
        _InAppSurveyGuide(_surveyText(branch.closedQuestion.guide)),
        24.verticalSpace,
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          separatorBuilder: (_, _) => 8.verticalSpace,
          itemBuilder: (context, index) {
            final option = options[index];
            final isSelected = selectedOptionIds.contains(option.id);
            return _ClosedQuestionOptionRow(
              option: option,
              isSelected: isSelected,
              onTap: () => onToggleOption(option.id),
            );
          },
        ),
      ],
    );
  }
}

class _ClosedQuestionOptionRow extends StatelessWidget {
  const _ClosedQuestionOptionRow({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final InAppSurveyOptionEntity option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = _surveyText(option.value);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        child: Container(
          constraints: BoxConstraints(minHeight: 50.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected ? _InAppSurveyColors.brandPrimary : Colors.transparent,
              width: isSelected ? 2 : 0,
            ),
            boxShadow: isSelected
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x3DE7E7E9),
                      blurRadius: 1.5,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              if (option.icon.trim().isNotEmpty) ...[
                _InAppSurveyRemoteGraphic(
                  url: option.icon,
                  size: 20.w,
                ),
                12.horizontalSpace,
              ],
              Expanded(
                child: AppText(
                  label,
                  maxLines: 3,
                  overflow: TextOverflow.visible,
                  style: AppStyle.text14.copyWith(
                    color: isSelected ? _InAppSurveyColors.brandText : _InAppSurveyColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    height: 1.75,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
