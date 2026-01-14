part of '../../lesson.dart';

class LessonPage extends StatefulWidget {
  const LessonPage({super.key});

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  String _lastExerciseScrollKey = '';

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TheoryCubit, TheoryState>(
          listenWhen: (previous, current) {
            return previous.currentDocumentIndex != current.currentDocumentIndex ||
                previous.currentLearningItem.id != current.currentLearningItem.id ||
                previous.currentDocument.id != current.currentDocument.id;
          },
          listener: (context, state) => _trackKeypointTheoryScrView(state),
        ),
        BlocListener<ExerciseCubit, ExerciseState>(
          listenWhen: (previous, current) {
            return previous.currentQuestionIndex != current.currentQuestionIndex ||
                previous.currentLearningItem.id != current.currentLearningItem.id ||
                previous.currentQuestion.id != current.currentQuestion.id;
          },
          listener: (context, state) => _trackKeypointExerciseScrView(state),
        ),
      ],
      child: BlocSelector<LessonCubit, LessonState, ({LearningItemType type, LessonStatus status, bool hasItems})>(
        selector: (state) => (type: state.currentLearningItem.type, status: state.status, hasItems: state.pageData.items.isNotEmpty),
        builder: (context, selected) {
          Widget lessonBody = const SizedBox.shrink();
          Widget bottomButton = const SizedBox.shrink();

          switch (selected.type) {
            case LearningItemType.exercise || LearningItemType.roleplay:
              final QuestionEntity question = context.select((ExerciseCubit bloc) => bloc.state.currentQuestion);
              lessonBody = _buildExerciseLessonBody(question.type);
              bottomButton = _buildBottomButton(context, lessonBody);
              break;
            case LearningItemType.theory:
              lessonBody = TheoryLessonBody(onAnswerChecked: _handleAnswerChecked);
              bottomButton = _buildBottomButton(context, lessonBody);
              break;
          }

          return LessonLayout(
            body: lessonBody,
            bottom: bottomButton,
            isLoading: selected.status == LessonStatus.loading,
            onScroll: _trackKeypointExerciseScroll,
          );
        },
      ),
    );
  }

  void _handleAnswerChecked(bool isCorrect) {
    debugPrint('Answer is correct: $isCorrect');
  }

  Widget _buildExerciseLessonBody(QuestionTypeEnum questionType) {
    return switch (questionType) {
      QuestionTypeEnum.singleChoice => SingleChoiceLessonBody(onAnswerChecked: _handleAnswerChecked),
      QuestionTypeEnum.multipleChoice => MultipleChoiceLessonBody(onAnswerChecked: _handleAnswerChecked),
      QuestionTypeEnum.dragAndDrop => DragAndDropLessonBody(onAnswerChecked: _handleAnswerChecked),
      QuestionTypeEnum.arrangeTheSequence => ArrangeTheSequenceLessonBody(onAnswerChecked: _handleAnswerChecked),
      QuestionTypeEnum.cuesPlacement => CuesPlacementLessonBody(onAnswerChecked: _handleAnswerChecked),
      QuestionTypeEnum.stressPlacement => MarkStressWordLessonBody(onAnswerChecked: _handleAnswerChecked),
      QuestionTypeEnum.speaking => SpeakingLessonBody(onAnswerChecked: _handleAnswerChecked),
    };
  }

  Widget _buildBottomButton(BuildContext context, Widget lessonBody) {
    return switch (lessonBody) {
      SingleChoiceLessonBody body => body.buildBottomButton(context),
      MultipleChoiceLessonBody body => body.buildBottomButton(context),
      DragAndDropLessonBody body => body.buildBottomButton(context),
      ArrangeTheSequenceLessonBody body => body.buildBottomButton(context),
      CuesPlacementLessonBody body => body.buildBottomButton(context),
      MarkStressWordLessonBody body => body.buildBottomButton(context),
      SpeakingLessonBody body => body.buildBottomButton(context),
      TheoryLessonBody body => body.buildBottomButton(context),
      _ => const SizedBox.shrink(),
    };
  }

  void _trackKeypointTheoryScrView(TheoryState state) {
    if (state.currentLearningItem.id.isEmpty) return;
    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData == null) return;
    AppService.instance.appTrackingService.trackKeypointTheoryScrView(trackingData);
  }

  void _trackKeypointExerciseScrView(ExerciseState state) {
    if (state.currentLearningItem.type != LearningItemType.exercise) return;
    if (state.currentQuestion.id == 0) return;
    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData == null) return;
    AppService.instance.appTrackingService.trackKeypointExerciseScrView(trackingData);
  }

  void _trackKeypointExerciseScroll() {
    final lessonState = context.read<LessonCubit>().state;
    if (lessonState.currentLearningItem.type != LearningItemType.exercise) return;
    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData == null) return;
    final scrollKey = '${lessonState.currentLearningItem.id}:${lessonState.currentLessonIndex}';
    if (scrollKey == _lastExerciseScrollKey) return;
    _lastExerciseScrollKey = scrollKey;
    AppService.instance.appTrackingService.trackKeypointExerciseScroll(trackingData);
  }
}
