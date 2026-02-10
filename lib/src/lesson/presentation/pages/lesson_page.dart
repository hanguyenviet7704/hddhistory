part of '../../lesson.dart';

class LessonPage extends StatefulWidget {
  const LessonPage({super.key});

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  late final LessonPageController _controller;
  late final LessonReviewBodyBuilder _reviewBodyBuilder;
  late final LessonBodyFactory _bodyFactory;
  late final LessonTimelineBuilder _timelineBuilder;
  late final LessonTrackingDelegate _trackingDelegate;

  @override
  void initState() {
    super.initState();
    _controller = LessonPageController(
      onBottomButtonVisibilityChanged: (isVisible) => context.read<LessonCubit>().setBottomButtonVisible(isVisible),
      onClearSuppressNextAutoScroll: () => context.read<LessonCubit>().clearSuppressNextAutoScroll(),
      isMounted: () => mounted,
    );
    _reviewBodyBuilder = const LessonReviewBodyBuilder();
    _bodyFactory = LessonBodyFactory(
      onAnswerChecked: _handleAnswerChecked,
      onContinueUnsupported: () => AppDI.injector.get<ExerciseCubit>().nextQuestion(),
      reviewBodyBuilder: _reviewBodyBuilder,
    );
    _timelineBuilder = const LessonTimelineBuilder();
    _trackingDelegate = const LessonTrackingDelegate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showLessonNavigationPopupIfNeeded();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
          listener: (context, state) => _trackingDelegate.trackKeypointTheoryScrView(state),
        ),
        BlocListener<ExerciseCubit, ExerciseState>(
          listenWhen: (previous, current) {
            return previous.currentQuestionIndex != current.currentQuestionIndex ||
                previous.currentLearningItem.id != current.currentLearningItem.id ||
                previous.currentQuestion.id != current.currentQuestion.id;
          },
          listener: (context, state) => _trackingDelegate.trackKeypointExerciseScrView(state),
        ),
      ],
      child: BlocBuilder<LessonCubit, LessonState>(
        buildWhen: (previous, current) {
          if (previous.isBottomButtonVisible != current.isBottomButtonVisible) {
            final normalizedPrevious = previous.copyWith(isBottomButtonVisible: current.isBottomButtonVisible);
            return normalizedPrevious != current;
          }
          return true;
        },
        builder: (context, state) {
          final activeBody = _buildActiveBody(context, state);
          final lessonBody = _timelineBuilder.buildLessonListView(
            state: state,
            activeBody: activeBody,
            controller: _controller,
            buildReviewBody: _bodyFactory.buildReviewBody,
            onTrackCurrentLearningItemScroll: _trackCurrentLearningItemScroll,
          );
          final bottomButton = _bodyFactory.buildBottomButton(context, activeBody);

          return LessonLayout(
            body: lessonBody,
            bottom: bottomButton,
            isLoading: state.status == LessonStatus.loading,
          );
        },
      ),
    );
  }

  void _handleAnswerChecked(bool isCorrect) {
    debugPrint('Answer is correct: $isCorrect');
    final lessonState = context.read<LessonCubit>().state;
    if (lessonState.currentLearningItem.type != LearningItemType.exercise) return;
    context.read<LessonCubit>().markPendingAdvance();
  }

  void _showLessonNavigationPopupIfNeeded() {
    final userCubit = context.read<UserCubit>();
    _controller.showLessonNavigationPopupIfNeeded(
      isFirstTime: userCubit.state.isFirstTimeLessonNavigationGuide,
      onMarkSeen: () => userCubit.setIsFirstTimeLessonNavigationGuide(false),
      onShowPopup: () => LessonNavigationPopup.show(context),
    );
  }

  Widget _buildActiveBody(BuildContext context, LessonState state) {
    if (state.pageData.items.isEmpty) return const SizedBox.shrink();

    switch (state.currentLearningItem.type) {
      case LearningItemType.exercise || LearningItemType.roleplay:
        final QuestionEntity question = context.select((ExerciseCubit bloc) => bloc.state.currentQuestion);
        return _bodyFactory.buildExerciseBody(question);
      case LearningItemType.theory:
        return TheoryLessonBody(onAnswerChecked: _handleAnswerChecked);
    }
  }

  void _trackCurrentLearningItemScroll() {
    _trackingDelegate.trackCurrentLearningItemScroll(
      lessonState: context.read<LessonCubit>().state,
      shouldTrackScroll: _controller.shouldTrackScroll,
    );
  }
}
