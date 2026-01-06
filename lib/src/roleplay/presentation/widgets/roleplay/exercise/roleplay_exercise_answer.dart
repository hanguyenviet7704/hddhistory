part of '../../../../roleplay.dart';

class RoleplayExerciseAnswerCard extends StatelessWidget {
  final QuestionEntity exercise;

  const RoleplayExerciseAnswerCard({
    super.key,
    required this.exercise,
  });

  List<String> get _correctOptions {
    final options = exercise.options.where((o) => o.isCorrect).toList();
    if (options.isNotEmpty) {
      return options.map((o) => o.value.text.isNotEmpty ? o.value.text : o.text.text).where((text) => text.isNotEmpty).toList();
    }
    return exercise.answer.map((a) => a.correctAnswer.text).toList();
  }

  List<String> get _sequenceAnswers {
    // Primary source: ordered answers from backend
    if (exercise.answer.isNotEmpty) {
      return exercise.answer
          .map((a) {
            // Prefer explicit correctAnswer text
            if (a.correctAnswer.text.isNotEmpty) return a.correctAnswer.text;

            // Fallback: map by id to option text/value
            final match = exercise.options.firstWhere(
              (o) => o.id == a.id,
              orElse: () => const OptionEntity(),
            );
            if (match.id != 0) {
              if (match.text.text.isNotEmpty) return match.text.text;
              if (match.value.text.isNotEmpty) return match.value.text;
            }
            return '';
          })
          .where((text) => text.isNotEmpty)
          .toList();
    }

    // Fallback: use all options in their given order
    final orderedOptions = exercise.options.map((o) => o.text.text.isNotEmpty ? o.text.text : o.value.text).where((text) => text.isNotEmpty).toList();
    if (orderedOptions.isNotEmpty) return orderedOptions;

    return _correctOptions;
  }

  TextStyle get _questionTextStyle => AppStyle.text14.copyWith(
        color: AppCustomColor.textSecondary,
        fontWeight: FontWeight.w700,
        height: 1.75,
      );

  TextStyle get _labelTextStyle => AppStyle.text12.copyWith(
        color: AppCustomColor.textTertiary,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  TextStyle get _answerTextStyle => AppStyle.text14.copyWith(
        color: AppCustomColor.textPrimary,
        fontWeight: FontWeight.w500,
        height: 1.75,
      );

  @override
  Widget build(BuildContext context) {
    return BlocSelector<RoleplayCubit, RoleplayState, ExerciseResultEntity>(
      selector: (state) => state.currentRoleplay.contents
          .firstWhere((content) => content.type == RoleplayContentType.exercise && content.exercise.id == exercise.id)
          .exercise
          .result,
      builder: (context, result) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppCustomColor.roleplayAnswerBackground,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLeading(context, result.isCorrect),
              Padding(
                padding: EdgeInsets.fromLTRB(8.w, 12.h, 8.w, 8.h),
                child: _buildAnswerCard(context, result),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeading(BuildContext context, bool isCorrect) {
    final bool showStatus = exercise.type != QuestionTypeEnum.speaking;

    if (showStatus) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusRow(context, isCorrect),
                _buildChevron(size: 18.w),
              ],
            ),
            4.verticalSpace,
            AppText(
              exercise.questionText,
              maxLines: 5,
              style: _questionTextStyle,
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
              style: _questionTextStyle,
            ),
          ),
          8.horizontalSpace,
          _buildChevron(size: 24.w),
        ],
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context, bool isCorrect) {
    final Color statusColor = isCorrect ? AppCustomColor.successGreen : AppCustomColor.errorRed;
    final String statusText = isCorrect ? t.exercise.exerciseFeedbackRight : t.exercise.exerciseFeedbackNotTrue;
    final Widget icon = isCorrect
        ? AppAsset.icons.app.icTick.image(width: 18.w, height: 18.w)
        : AppAsset.icons.app.icDanger.image(width: 18.w, height: 18.w);

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

  Widget _buildChevron({double size = 18}) {
    return Icon(
      Icons.chevron_right,
      size: size,
      color: AppCustomColor.textTertiary,
    );
  }

  Widget _buildAnswerCard(BuildContext context, ExerciseResultEntity result) {
    final String label = exercise.type == QuestionTypeEnum.speaking ? t.exercise.exerciseYourAnswer : t.exercise.exerciseAnswer;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 1),
            blurRadius: 3.r,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: _labelTextStyle,
          ),
          4.verticalSpace,
          _buildAnswerBody(context, result),
        ],
      ),
    );
  }

  Widget _buildAnswerBody(BuildContext context, ExerciseResultEntity result) {
    switch (exercise.type) {
      case QuestionTypeEnum.singleChoice:
        return _buildAnswerLines([_correctOptions.firstOrNull ?? '']);
      case QuestionTypeEnum.multipleChoice:
        return _buildAnswerLines(_correctOptions);
      case QuestionTypeEnum.dragAndDrop:
        return _buildGapFillingSentence();
      case QuestionTypeEnum.arrangeTheSequence:
        return _buildNumberedList(_sequenceAnswers);
      case QuestionTypeEnum.stressPlacement:
      case QuestionTypeEnum.cuesPlacement:
        return const SizedBox.shrink();
      case QuestionTypeEnum.speaking:
        return _buildSpeakingAnswer(result.recordAnswer);
    }
  }

  Widget _buildAnswerLines(List<String> items) {
    final lines = items.where((e) => e.isNotEmpty).toList();
    if (lines.isEmpty) return const SizedBox.shrink();

    return AppText(
      lines.join('\n'),
      maxLines: 10,
      overflow: TextOverflow.visible,
      style: _answerTextStyle,
    );
  }

  Widget _buildNumberedList(List<String> items) {
    final lines = items.where((e) => e.isNotEmpty).toList();
    if (lines.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.asMap().entries.map((entry) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 21.w,
              child: AppText(
                '${entry.key + 1}.',
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: _answerTextStyle,
              ),
            ),
            Expanded(
              child: AppText(
                entry.value,
                maxLines: 6,
                overflow: TextOverflow.visible,
                style: _answerTextStyle,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildParagraph(String text) {
    return AppText(
      text,
      maxLines: 8,
      overflow: TextOverflow.visible,
      style: _answerTextStyle,
    );
  }

  Widget _buildGapFillingSentence() {
    final template = exercise.targetArea.text;
    if (template.isEmpty) return const SizedBox.shrink();

    final answers = exercise.answer.isNotEmpty ? exercise.answer.map((a) => a.correctAnswer.text).toList() : _correctOptions;

    final parts = template.split('___');
    final spans = <InlineSpan>[];
    final baseStyle = _answerTextStyle;
    final highlightStyle = _answerTextStyle.copyWith(
      color: AppCustomColor.successGreen,
      fontWeight: FontWeight.w700,
    );

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isNotEmpty) {
        spans.add(TextSpan(text: part, style: baseStyle));
      }

      if (i < answers.length) {
        final answer = answers[i].replaceAll('"', '').replaceAll('“', '').replaceAll('”', '').trim();
        spans.add(TextSpan(text: answer, style: highlightStyle));
      }
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildSpeakingAnswer(AnswerEntity recordAnswer) {
    if (recordAnswer.record.isNotEmpty) {
      return RoleplayAudioAnswerPlayer(source: recordAnswer.record);
    }

    if (recordAnswer.review.isNotEmpty) {
      return _buildParagraph(recordAnswer.review);
    }

    return const SizedBox.shrink();
  }
}
