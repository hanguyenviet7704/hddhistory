part of '../../../../lesson.dart';

class LessonReviewBodyBuilder {
  const LessonReviewBodyBuilder();

  Widget buildReviewBody(QuestionEntity question) {
    final payload = question.typedPayload;

    return switch (payload) {
      QuestionSingleChoicePayloadEntity() => _buildChoiceReviewBody(question, isMultiple: false),
      QuestionSingleChoiceNoCorrectAnswerPayloadEntity() => _buildChoiceReviewBody(question, isMultiple: false),
      QuestionMultipleChoicePayloadEntity() => _buildChoiceReviewBody(question, isMultiple: true),
      QuestionDragAndDropPayloadEntity() => _buildDragDropReviewBody(question),
      QuestionArrangeTheSequencePayloadEntity() => _buildArrangeSequenceReviewBody(question),
      QuestionCuesPlacementPayloadEntity() => _buildCuesPlacementReviewBody(question),
      QuestionStressPlacementPayloadEntity() => _buildStressPlacementReviewBody(question),
      QuestionSpeakingPayloadEntity() => _buildSpeakingReviewBody(question),
      QuestionUnsupportedPayloadEntity() => UnsupportedLessonBody(question: question, isReadOnly: true),
      _ => UnsupportedLessonBody(question: question, isReadOnly: true),
    };
  }

  Widget _buildChoiceReviewBody(QuestionEntity question, {required bool isMultiple}) {
    return _buildReadOnlyCubitBody<ChoiceCubit>(
      createCubit: ChoiceCubit.new,
      setupCubit: (cubit) {
        cubit
          ..setQuestion(question)
          ..applyExerciseResult(question.result);
      },
      child: isMultiple
          ? MultipleChoiceLessonBody(
              onAnswerChecked: (_) {},
              isReadOnly: true,
            )
          : SingleChoiceLessonBody(
              onAnswerChecked: (_) {},
              isReadOnly: true,
            ),
    );
  }

  Widget _buildDragDropReviewBody(QuestionEntity question) {
    return _buildReadOnlyCubitBody<DragAndDropCubit>(
      createCubit: DragAndDropCubit.new,
      setupCubit: (cubit) {
        cubit
          ..setQuestion(question)
          ..applyExerciseResult(question.result);
      },
      child: DragAndDropLessonBody(
        onAnswerChecked: (_) {},
        isReadOnly: true,
      ),
    );
  }

  Widget _buildArrangeSequenceReviewBody(QuestionEntity question) {
    return _buildReadOnlyCubitBody<ArrangeTheSequenceCubit>(
      createCubit: ArrangeTheSequenceCubit.new,
      setupCubit: (cubit) {
        cubit
          ..setQuestion(question)
          ..applyExerciseResult(question.result);
      },
      child: ArrangeTheSequenceLessonBody(
        onAnswerChecked: (_) {},
        isReadOnly: true,
      ),
    );
  }

  Widget _buildCuesPlacementReviewBody(QuestionEntity question) {
    return _buildReadOnlyCubitBody<CuesPlacementCubit>(
      createCubit: CuesPlacementCubit.new,
      setupCubit: (cubit) {
        cubit
          ..setQuestion(question)
          ..applyExerciseResult(question.result);
      },
      child: CuesPlacementLessonBody(
        onAnswerChecked: (_) {},
        isReadOnly: true,
      ),
    );
  }

  Widget _buildStressPlacementReviewBody(QuestionEntity question) {
    return _buildReadOnlyCubitBody<MarkStressWordCubit>(
      createCubit: MarkStressWordCubit.new,
      setupCubit: (cubit) {
        cubit
          ..setQuestion(question)
          ..applyExerciseResult(question.result);
      },
      child: MarkStressWordLessonBody(
        onAnswerChecked: (_) {},
        isReadOnly: true,
      ),
    );
  }

  Widget _buildSpeakingReviewBody(QuestionEntity question) {
    return _buildReadOnlyCubitBody<SpeakingCubit>(
      createCubit: () => SpeakingCubit(
        AppDI.injector.get<SendVoiceFeedbackStreamUseCase>(),
        AppDI.injector.get<SendScoreRecordUseCase>(),
        AppDI.injector.get<UploadCubit>(),
        AppDI.injector.get<LocaleCubit>(),
      ),
      setupCubit: (cubit) => cubit.setReviewResult(question, question.result),
      child: SpeakingLessonBody(
        onAnswerChecked: (_) {},
        isReadOnly: true,
      ),
    );
  }

  Widget _buildReadOnlyCubitBody<T extends Cubit<dynamic>>({
    required T Function() createCubit,
    required void Function(T cubit) setupCubit,
    required Widget child,
  }) {
    return BlocProvider<T>(
      create: (_) {
        final cubit = createCubit();
        setupCubit(cubit);
        return cubit;
      },
      child: child,
    );
  }
}
