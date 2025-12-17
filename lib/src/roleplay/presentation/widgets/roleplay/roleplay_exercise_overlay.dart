part of '../../../roleplay.dart';

class RoleplayExerciseOverlay extends StatelessWidget {
  final QuestionEntity exercise;
  final bool isExpanded;

  const RoleplayExerciseOverlay({
    super.key,
    required this.exercise,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewPadding = MediaQuery.paddingOf(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.only(bottom: viewPadding.bottom > 0 ? viewPadding.bottom / 4 : 8.h),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.op(0.08),
              offset: const Offset(0, -4),
              blurRadius: 8,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.only(bottom: viewPadding.bottom > 0 ? viewPadding.bottom / 2 : 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DragHandle(),
              if (isExpanded) _ExpandedExerciseBody(questionText: exercise.questionText) else _CollapsedExerciseBody(questionText: exercise.questionText),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 24.w, 0),
      child: Center(
        child: Container(
          width: 48.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: AppCustomColor.borderSecondary,
            borderRadius: BorderRadius.circular(30.r),
          ),
        ),
      ),
    );
  }
}

class _CollapsedExerciseBody extends StatelessWidget {
  final String questionText;

  const _CollapsedExerciseBody({required this.questionText});

  @override
  Widget build(BuildContext context) {
    final Translations t = Translations.of(context);

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            questionText,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppStyle.text20.copyWith(
              color: AppCustomColor.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          24.verticalSpace,
          Center(
            child: AppText(
              t.roleplay.rolePlayExerciseTapToAnswer,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: AppStyle.text16.copyWith(
                color: AppCustomColor.brandPrimary,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedExerciseBody extends StatelessWidget {
  final String questionText;

  const _ExpandedExerciseBody({required this.questionText});

  List<String> get _placeholderOptions => const [
    'Căng thẳng, mệt mỏi từ trước đó',
    'Câu từ mang tính xúc phạm',
    'Đồng nghiệp đóng góp vô lý',
    'Phản ứng theo bản năng',
    'Im lặng đồng nghĩa là dễ "bị bắt nạt"',
  ];

  @override
  Widget build(BuildContext context) {
    final Translations t = Translations.of(context);

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            questionText,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppStyle.text20.copyWith(
              color: AppCustomColor.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          24.verticalSpace,
          AppText(
            t.roleplay.rolePlayExerciseSelectAllThatApply,
            style: AppStyle.text12.copyWith(
              color: AppCustomColor.textTertiary,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          8.verticalSpace,
          ..._placeholderOptions.asMap().entries.map((entry) {
            final bool isSelected = entry.key < 2;
            return Padding(
              padding: EdgeInsets.only(bottom: entry.key == _placeholderOptions.length - 1 ? 0 : 8.h),
              child: _AnswerCard(
                label: entry.value,
                isSelected: isSelected,
              ),
            );
          }),
          24.verticalSpace,
          SizedBox(
            height: 48.h,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppCustomColor.brandPrimary,
                borderRadius: BorderRadius.circular(1000.r),
              ),
              child: Center(
                child: AppText(
                  t.exercise.exerciseCheckButton,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: AppStyle.text16.copyWith(
                    color: AppCustomColor.textWhite,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _AnswerCard({
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isSelected ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary;
    final TextStyle textStyle = isSelected
        ? AppStyle.text14.copyWith(
            color: AppCustomColor.textSecondary,
            fontWeight: FontWeight.w500,
            height: 1.75,
          )
        : AppStyle.text14.copyWith(
            color: AppCustomColor.textSecondary,
            height: 1.75,
          );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
      ),
      child: AppText(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      ),
    );
  }
}
