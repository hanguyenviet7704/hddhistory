part of '../../../lesson.dart';

class UnsupportedLessonBody extends LessonBodyWidget {
  final QuestionEntity question;
  final VoidCallback? onContinue;
  final bool isReadOnly;

  const UnsupportedLessonBody({
    super.key,
    required this.question,
    this.onContinue,
    this.isReadOnly = false,
  });

  String _unsupportedTypeLabel() {
    final payload = question.typedPayload;
    if (payload is QuestionUnsupportedPayloadEntity && payload.rawType.isNotEmpty) {
      return payload.rawType;
    }
    return '';
  }

  @override
  Widget buildBottomButton(BuildContext context) {
    if (isReadOnly || onContinue == null) return const SizedBox.shrink();
    return ExerciseContinueButton(
      onPressed: onContinue,
      text: context.l10n.lesson.navigationPopupTapToContinue,
      isEnabled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final unsupportedType = _unsupportedTypeLabel();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question.document.isNotEmpty) ...[
          DocumentWidget(documents: question.document),
          12.verticalSpace,
        ],
        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                context.l10n.lesson.emptyPopupTitle,
                style: AppStyle.text16.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D121C),
                ),
              ),
              8.verticalSpace,
              AppText(
                context.l10n.lesson.emptyPopupDescription,
                maxLines: 4,
                style: AppStyle.text14.copyWith(
                  color: const Color(0xFF364152),
                ),
              ),
              if (unsupportedType.isNotEmpty) ...[
                12.verticalSpace,
                AppText(
                  'Type: $unsupportedType',
                  style: AppStyle.text12.copyWith(
                    color: const Color(0xFF7F8EA4),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
