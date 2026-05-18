part of '../../in_app_survey.dart';

class InAppSurveyRatingStep extends StatelessWidget {
  const InAppSurveyRatingStep({
    super.key,
    required this.config,
    required this.onSelectBranch,
  });

  final InAppSurveyConfigEntity config;
  final ValueChanged<int> onSelectBranch;

  @override
  Widget build(BuildContext context) {
    final branches = config.branches;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _InAppSurveyTitle(_surveyText(config.introQuestion.question)),
        2.verticalSpace,
        _InAppSurveyGuide(_surveyText(config.introQuestion.guide)),
        20.verticalSpace,
        Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              branches.length,
              (index) => Expanded(
                child: _RatingBranchButton(
                  branch: branches[index],
                  index: index,
                  isFirst: index == 0,
                  isLast: index == branches.length - 1,
                  onTap: () => onSelectBranch(index),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RatingBranchButton extends StatelessWidget {
  const _RatingBranchButton({
    required this.branch,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final InAppSurveyBranchEntity branch;
  final int index;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = _label;
    final emojiUrl = branch.emoji.lightUrl.trim().isNotEmpty ? branch.emoji.lightUrl : branch.emoji.darkUrl;

    return Semantics(
      button: true,
      label: label.isEmpty ? 'Survey rating ${index + 1}' : label,
      child: InkWell(
        borderRadius: BorderRadius.circular(999.r),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 58.h, minWidth: 44.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 44.w,
                height: 44.w,
                child: Center(
                  child: _InAppSurveyRemoteGraphic(
                    url: emojiUrl,
                    size: 36.w,
                  ),
                ),
              ),
              if (label.isNotEmpty) ...[
                6.verticalSpace,
                AppText(
                  label,
                  maxLines: 1,
                  enableFitScaleDown: true,
                  textAlign: TextAlign.center,
                  style: AppStyle.text14.copyWith(
                    color: isLast ? _InAppSurveyColors.textPrimary : _InAppSurveyColors.textTertiary,
                    height: 1.75,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String get _label {
    final name = branch.emoji.name?.trim() ?? '';
    if (isFirst) return name.isEmpty ? 'Awful' : name;
    if (isLast) return name.isEmpty ? 'Amazing' : name;
    return '';
  }
}
