part of '../../../../roleplay.dart';

class _RoleplayExerciseAnswerHeader extends StatelessWidget {
  final QuestionEntity exercise;
  final bool showsStatusHeader;
  final bool isCorrect;
  final TextStyle questionTextStyle;

  const _RoleplayExerciseAnswerHeader({
    required this.exercise,
    required this.showsStatusHeader,
    required this.isCorrect,
    required this.questionTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (showsStatusHeader) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RoleplayStatusRow(isCorrect: isCorrect),
                _buildChevron(size: 18.w),
              ],
            ),
            4.verticalSpace,
            AppText(
              exercise.questionText,
              maxLines: 5,
              style: questionTextStyle,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: AppText(
              exercise.questionText,
              maxLines: 5,
              style: questionTextStyle,
            ),
          ),
          8.horizontalSpace,
          _buildChevron(size: 24.w),
        ],
      ),
    );
  }

  Widget _buildChevron({double size = 18}) {
    return Icon(
      Icons.chevron_right,
      size: size,
      color: AppCustomColor.textTertiary,
    );
  }
}

class _RoleplayStatusRow extends StatelessWidget {
  final bool isCorrect;
  const _RoleplayStatusRow({required this.isCorrect});

  Color get statusColor => isCorrect ? AppCustomColor.successGreen : AppCustomColor.errorRed;
  String get statusText => isCorrect
      ? l10n.exercise.exerciseFeedbackRight
      : l10n.exercise.exerciseFeedbackNotTrue;
  Widget get icon => isCorrect
      ? AppAsset.icons.app.icTick.image(width: 18.w, height: 18.w)
      : AppAsset.icons.app.icClose.image(width: 18.w, height: 18.w);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        icon,
        8.horizontalSpace,
        AppText(
          statusText,
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: AppStyle.text14.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w700,
            height: 1.75,
          ),
        ),
      ],
    );
  }
}
