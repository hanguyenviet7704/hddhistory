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

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final bool isSpeaking = exercise.type == QuestionTypeEnum.speaking;
    final Color labelColor = AppCustomColor.successGreen;
    final String label = isSpeaking ? t.exercise.exerciseYourAnswer : t.exercise.exerciseFeedbackCorrectAnswer;
    final QuestionEntity? roleplayExercise = context.select<RoleplayCubit, QuestionEntity?>(
      (cubit) {
        for (final content in cubit.state.currentRoleplay.contents) {
          if (content.type == RoleplayContentType.exercise && content.exercise.id == exercise.id) {
            return content.exercise;
          }
        }
        return null;
      },
    );
    final String recordText = roleplayExercise?.result.recordAnswer.review ?? '';
    final String recordAudio = roleplayExercise?.result.recordAnswer.record ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            exercise.questionText,
            maxLines: 5,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.textTertiary,
              height: 1.5,
            ),
          ),
          8.verticalSpace,
          AppText(
            label,
            style: AppStyle.text14.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          8.verticalSpace,
          _buildAnswerBody(context, recordText: recordText, recordAudio: recordAudio),
        ],
      ),
    );
  }

  Widget _buildAnswerBody(BuildContext context, {String? recordText, String? recordAudio}) {
    switch (exercise.type) {
      case QuestionTypeEnum.singleChoice:
        return _buildBulletList([_correctOptions.firstOrNull ?? '']);
      case QuestionTypeEnum.multipleChoice:
        return _buildBulletList(_correctOptions);
      case QuestionTypeEnum.dragAndDrop:
        return _buildGapFillingSentence();
      case QuestionTypeEnum.arrangeTheSequence:
        return _buildNumberedList(_sequenceAnswers);
      case QuestionTypeEnum.stressPlacement:
        // Stress placement not used in roleplay; show nothing
        return const SizedBox.shrink();
      case QuestionTypeEnum.cuesPlacement:
        return _buildBulletList(_correctOptions);
      case QuestionTypeEnum.speaking:
        return _buildSpeakingAnswer(recordText: recordText, recordAudio: recordAudio);
    }
  }

  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .where((e) => e.isNotEmpty)
          .map(
            (e) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: AppText(
                e,
                maxLines: 5,
                style: AppStyle.text14.copyWith(
                  color: AppCustomColor.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildNumberedList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.where((e) => e.isNotEmpty).toList().asMap().entries.map((entry) {
        return Padding(
          padding: EdgeInsets.only(bottom: entry.key == items.length - 1 ? 0 : 6.h),
          child: AppText(
            '${entry.key + 1}. ${entry.value}',
            maxLines: 5,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildParagraph(String text) {
    return AppText(
      text,
      maxLines: 6,
      style: AppStyle.text14.copyWith(
        color: AppCustomColor.textPrimary,
        fontWeight: FontWeight.w600,
        height: 1.6,
      ),
    );
  }

  Widget _buildGapFillingSentence() {
    final template = exercise.targetArea.text;
    if (template.isEmpty) return const SizedBox.shrink();

    final answers = exercise.answer.isNotEmpty ? exercise.answer.map((a) => a.correctAnswer.text).toList() : _correctOptions;

    final parts = template.split('___');
    final spans = <InlineSpan>[];

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isNotEmpty) {
        spans.add(
          TextSpan(
            text: part,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
          ),
        );
      }

      if (i < answers.length) {
        final answer = answers[i].replaceAll('"', '').replaceAll('“', '').replaceAll('”', '').trim();
        spans.add(
          TextSpan(
            text: answer,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.successGreen,
              fontWeight: FontWeight.w700,
              height: 1.6,
            ),
          ),
        );
      }
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildSpeakingAnswer({String? recordText, String? recordAudio}) {
    if (recordAudio != null && recordAudio.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundGray,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: AudioPlayerWidget(audioUrl: recordAudio),
      );
    }

    if (recordText != null && recordText.isNotEmpty) {
      return _buildParagraph(recordText);
    }

    return const SizedBox.shrink();
  }
}
