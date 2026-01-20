part of '../../lesson.dart';

class LessonPage extends StatefulWidget {
  const LessonPage({super.key});

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};
  int _lastRenderedItemCount = 0;
  bool _didNotifyExerciseScroll = false;
  String _lastExerciseScrollKey = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollPosition);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScrollPosition);
    _scrollController.dispose();
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
      _lastRenderedItemCount = 0;
      _itemKeys.clear();
      return const SizedBox.shrink();
    }

    _handleAutoScroll(state, items.length);
    _scheduleBottomButtonCheck();

    return NotificationListener<UserScrollNotification>(
      onNotification: _handleUserScroll,
      child: ListView.separated(
        controller: _scrollController,
        itemCount: items.length,
        padding: EdgeInsets.only(bottom: 160.h),
        separatorBuilder: (context, index) => 40.verticalSpace,
        itemBuilder: (context, index) {
          _itemKeys.putIfAbsent(index, () => GlobalKey());
          final bool isNewestItem = index == items.length - 1;
          final double viewportHeight = _scrollController.hasClients
              ? _scrollController.position.viewportDimension
              : MediaQuery.sizeOf(context).height;
          return KeyedSubtree(
            key: _itemKeys[index],
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              constraints: BoxConstraints(minHeight: isNewestItem ? viewportHeight : 0),
              child: items[index],
            ),
          );
        },
      ),
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

  void _handleScrollPosition() {
    _updateBottomButtonVisibility();
  }

  bool _handleUserScroll(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.idle) {
      _didNotifyExerciseScroll = false;
    } else if (!_didNotifyExerciseScroll) {
      _didNotifyExerciseScroll = true;
      _trackKeypointExerciseScroll();
    }
    return false;
  }

  void _handleAutoScroll(LessonState state, int itemCount) {
    final previousCount = _lastRenderedItemCount;
    _lastRenderedItemCount = itemCount;
    if (itemCount < previousCount) {
      _itemKeys.clear();
      return;
    }
    if (itemCount <= previousCount) return;

    final shouldSuppress = state.suppressNextAutoScroll;
    final targetIndex = itemCount - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (shouldSuppress) {
        context.read<LessonCubit>().clearSuppressNextAutoScroll();
        return;
      }
      _scrollToIndex(targetIndex);
    });
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;
    final key = _itemKeys[index];
    final targetContext = key?.currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      alignment: 0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _scheduleBottomButtonCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateBottomButtonVisibility();
    });
  }

  void _updateBottomButtonVisibility() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    const threshold = 0.5;
    final shouldShow = position.extentAfter <= threshold;
    context.read<LessonCubit>().setBottomButtonVisible(shouldShow);
  }
}
