part of '../../lesson.dart';

class LessonPage extends StatefulWidget {
  const LessonPage({super.key});

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  late final LessonPageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LessonPageController(
      onBottomButtonVisibilityChanged: (isVisible) => context.read<LessonCubit>().setBottomButtonVisible(isVisible),
      onClearSuppressNextAutoScroll: () => context.read<LessonCubit>().clearSuppressNextAutoScroll(),
      isMounted: () => mounted,
    );
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
          final lessonBody = _buildLessonListView(state, activeBody);
          final bottomButton = _buildBottomButton(context, activeBody);

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
        return _buildExerciseLessonBody(question.type);
      case LearningItemType.theory:
        return TheoryLessonBody(onAnswerChecked: _handleAnswerChecked);
    }
  }

  Widget _buildLessonListView(LessonState state, Widget activeBody) {
    final items = _collectLessonItems(state, activeBody);
    if (items.isEmpty) {
      _controller.handleEmptyItems();
      return const SizedBox.shrink();
    }

    _controller.handleAutoScroll(
      itemCount: items.length,
      shouldSuppressAutoScroll: state.suppressNextAutoScroll,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final listHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 0.0;
        return NotificationListener<UserScrollNotification>(
          onNotification: (notification) => _controller.handleUserScroll(notification, _trackCurrentLearningItemScroll),
          child: ListView.separated(
            controller: _controller.scrollController,
            itemCount: items.length,
            padding: EdgeInsets.only(bottom: 160.h),
            separatorBuilder: (context, index) => 40.verticalSpace,
            itemBuilder: (context, index) {
              if (index == items.length - 1) {
                return KeyedSubtree(
                  key: _controller.lastItemKey,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: listHeight),
                    child: items[index],
                  ),
                );
              }
              return items[index];
            },
          ),
        );
      },
    );
  }

  List<Widget> _collectLessonItems(LessonState state, Widget activeBody) {
    final items = <Widget>[];
    if (state.pageData.items.isEmpty) return items;

    final lastItemIndex = math.min(state.currentLearningItemIndex, state.pageData.items.length - 1);
    if (lastItemIndex < 0) return items;

    for (int itemIndex = 0; itemIndex <= lastItemIndex; itemIndex++) {
      final learningItem = state.pageData.items[itemIndex];
      final isCurrentItem = itemIndex == state.currentLearningItemIndex;

      switch (learningItem.type) {
        case LearningItemType.theory:
          final documents = learningItem.documents;
          if (documents.isEmpty) continue;
          final activeDocIndex = isCurrentItem ? math.min(state.currentLessonIndex, documents.length - 1) : documents.length - 1;
          final maxDocIndex = activeDocIndex;

          for (int docIndex = 0; docIndex <= maxDocIndex; docIndex++) {
            if (isCurrentItem && docIndex == activeDocIndex) {
              items.add(activeBody);
              continue;
            }

            items.add(DocumentWidget(documents: documents[docIndex].document));
          }
          break;
        case LearningItemType.exercise || LearningItemType.roleplay:
          final questions = learningItem.questions;
          if (questions.isEmpty) continue;
          final activeQuestionIndex = isCurrentItem ? math.min(state.currentLessonIndex, questions.length - 1) : questions.length - 1;
          final maxQuestionIndex = activeQuestionIndex;

          for (int questionIndex = 0; questionIndex <= maxQuestionIndex; questionIndex++) {
            if (isCurrentItem && questionIndex == activeQuestionIndex) {
              items.add(activeBody);
              continue;
            }

            items.add(_buildReviewExerciseBody(questions[questionIndex]));
          }
          break;
      }
    }

    return items;
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

  Widget _buildReviewExerciseBody(QuestionEntity question) {
    return switch (question.type) {
      QuestionTypeEnum.singleChoice => _buildChoiceReviewBody(question, isMultiple: false),
      QuestionTypeEnum.multipleChoice => _buildChoiceReviewBody(question, isMultiple: true),
      QuestionTypeEnum.dragAndDrop => _buildDragDropReviewBody(question),
      QuestionTypeEnum.arrangeTheSequence => _buildArrangeSequenceReviewBody(question),
      QuestionTypeEnum.cuesPlacement => _buildCuesPlacementReviewBody(question),
      QuestionTypeEnum.stressPlacement => _buildStressPlacementReviewBody(question),
      QuestionTypeEnum.speaking => _buildSpeakingReviewBody(question),
    };
  }

  Widget _buildChoiceReviewBody(QuestionEntity question, {required bool isMultiple}) {
    return BlocProvider<ChoiceCubit>(
      create: (_) {
        final cubit = ChoiceCubit();
        cubit.setQuestion(question);
        cubit.applyExerciseResult(question.result);
        return cubit;
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
    return BlocProvider<DragAndDropCubit>(
      create: (_) {
        final cubit = DragAndDropCubit();
        cubit.setQuestion(question);
        cubit.applyExerciseResult(question.result);
        return cubit;
      },
      child: DragAndDropLessonBody(
        onAnswerChecked: (_) {},
        isReadOnly: true,
      ),
    );
  }

  Widget _buildArrangeSequenceReviewBody(QuestionEntity question) {
    return BlocProvider<ArrangeTheSequenceCubit>(
      create: (_) {
        final cubit = ArrangeTheSequenceCubit();
        cubit.setQuestion(question);
        cubit.applyExerciseResult(question.result);
        return cubit;
      },
      child: ArrangeTheSequenceLessonBody(
        onAnswerChecked: (_) {},
        isReadOnly: true,
      ),
    );
  }

  Widget _buildCuesPlacementReviewBody(QuestionEntity question) {
    return BlocProvider<CuesPlacementCubit>(
      create: (_) {
        final cubit = CuesPlacementCubit();
        cubit.setQuestion(question);
        cubit.applyExerciseResult(question.result);
        return cubit;
      },
      child: CuesPlacementLessonBody(
        onAnswerChecked: (_) {},
        isReadOnly: true,
      ),
    );
  }

  Widget _buildStressPlacementReviewBody(QuestionEntity question) {
    return BlocProvider<MarkStressWordCubit>(
      create: (_) {
        final cubit = MarkStressWordCubit();
        cubit.setQuestion(question);
        cubit.applyExerciseResult(question.result);
        return cubit;
      },
      child: MarkStressWordLessonBody(
        onAnswerChecked: (_) {},
        isReadOnly: true,
      ),
    );
  }

  Widget _buildSpeakingReviewBody(QuestionEntity question) {
    return BlocProvider<SpeakingCubit>(
      create: (_) {
        final cubit = SpeakingCubit(
          AppDI.injector.get<SendVoiceFeedbackStreamUseCase>(),
          AppDI.injector.get<SendScoreRecordUseCase>(),
          AppDI.injector.get<UploadCubit>(),
          AppDI.injector.get<LocaleCubit>(),
        );
        cubit.setReviewResult(question, question.result);
        return cubit;
      },
      child: SpeakingLessonBody(
        onAnswerChecked: (_) {},
        isReadOnly: true,
      ),
    );
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

  void _trackCurrentLearningItemScroll() {
    final lessonState = context.read<LessonCubit>().state;
    final learningItemType = lessonState.currentLearningItem.type;
    if (learningItemType != LearningItemType.exercise && learningItemType != LearningItemType.theory) return;

    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData == null) return;

    final scrollKey = '${lessonState.currentLearningItem.id}:${lessonState.currentLessonIndex}:${learningItemType.name}';
    if (!_controller.shouldTrackScroll(scrollKey)) return;

    if (learningItemType == LearningItemType.exercise) {
      AppService.instance.appTrackingService.trackKeypointExerciseScroll(trackingData);
      return;
    }

    AppService.instance.appTrackingService.trackKeypointTheoryScroll(trackingData);
  }
}
