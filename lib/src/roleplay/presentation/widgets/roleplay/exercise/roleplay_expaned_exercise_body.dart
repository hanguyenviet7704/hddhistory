part of '../../../../roleplay.dart';

class _ExpandedExerciseBody extends StatefulWidget {
  final QuestionEntity exercise;
  final int contentId;
  final int contentIndex;
  final bool readOnly;
  final ValueChanged<bool>? onAnswerChecked;
  final bool showResult;
  final bool isCorrect;
  final VoidCallback? onContinue;

  const _ExpandedExerciseBody({
    required this.exercise,
    required this.contentId,
    required this.contentIndex,
    this.readOnly = false,
    this.onAnswerChecked,
    this.showResult = false,
    this.isCorrect = false,
    this.onContinue,
  });

  @override
  State<_ExpandedExerciseBody> createState() => _ExpandedExerciseBodyState();
}

class _ExpandedExerciseBodyState extends State<_ExpandedExerciseBody> {
  final ScrollController _scrollController = ScrollController();
  bool _hasTrackedResultScroll = false;
  bool _hasTrackedResultScrollBottom = false;

  RoleplayTrackingData? _trackingData() => RoleplayTrackingData.fromContext();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(covariant _ExpandedExerciseBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showResult && !oldWidget.showResult) {
      _hasTrackedResultScroll = false;
      _hasTrackedResultScrollBottom = false;
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!widget.showResult) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final trackingData = _trackingData();
    if (trackingData == null) return;

    if (!_hasTrackedResultScroll && position.userScrollDirection != ScrollDirection.idle) {
      AppService.instance.appTrackingService.trackRoleplayQuizResultScroll(trackingData);
      _hasTrackedResultScroll = true;
    }

    if (!_hasTrackedResultScrollBottom && position.pixels >= position.maxScrollExtent - 16) {
      AppService.instance.appTrackingService.trackRoleplayQuizResultScroll(trackingData);
      _hasTrackedResultScrollBottom = true;
    }
  }

  void _handleAnswerChecked(BuildContext context, bool isCorrect) {
    _storeExerciseResult(context, isCorrect);
    widget.onAnswerChecked?.call(isCorrect);
  }

  void _storeExerciseResult(BuildContext context, bool isCorrect) {
    final ExerciseResultEntity baseResult = switch (widget.exercise.type) {
      QuestionTypeEnum.singleChoice => context.read<ChoiceCubit>().toExerciseResult(),
      QuestionTypeEnum.multipleChoice => context.read<ChoiceCubit>().toExerciseResult(),
      QuestionTypeEnum.dragAndDrop => context.read<DragAndDropCubit>().toExerciseResult(),
      QuestionTypeEnum.arrangeTheSequence => context.read<ArrangeTheSequenceCubit>().toExerciseResult(),
      QuestionTypeEnum.cuesPlacement => context.read<CuesPlacementCubit>().toExerciseResult(),
      QuestionTypeEnum.stressPlacement => context.read<MarkStressWordCubit>().toExerciseResult(),
      QuestionTypeEnum.speaking => context.read<SpeakingCubit>().toExerciseResult(),
    };

    context.read<RoleplayCubit>().setExerciseResult(
      contentId: widget.contentId,
      contentIndex: widget.contentIndex,
      result: baseResult.copyWith(passed: isCorrect),
    );
  }

  Widget _buildExerciseLessonBody(BuildContext context, QuestionTypeEnum questionType) {
    final onChecked = widget.readOnly ? (_) {} : (bool isCorrect) => _handleAnswerChecked(context, isCorrect);
    return switch (questionType) {
      QuestionTypeEnum.singleChoice => SingleChoiceLessonBody(onAnswerChecked: onChecked, isReadOnly: widget.readOnly),
      QuestionTypeEnum.multipleChoice => MultipleChoiceLessonBody(onAnswerChecked: onChecked, isReadOnly: widget.readOnly),
      QuestionTypeEnum.dragAndDrop => DragAndDropLessonBody(onAnswerChecked: onChecked, isReadOnly: widget.readOnly),
      QuestionTypeEnum.arrangeTheSequence => ArrangeTheSequenceLessonBody(onAnswerChecked: onChecked, isReadOnly: widget.readOnly),
      QuestionTypeEnum.cuesPlacement => CuesPlacementLessonBody(onAnswerChecked: onChecked, isReadOnly: widget.readOnly),
      QuestionTypeEnum.stressPlacement => MarkStressWordLessonBody(onAnswerChecked: onChecked, isReadOnly: widget.readOnly),
      QuestionTypeEnum.speaking => SpeakingLessonBody(
        onAnswerChecked: onChecked,
        onRoleplayReplayTap: widget.readOnly ? _trackReviewReplay : null,
        isReadOnly: widget.readOnly,
      ),
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

  Widget _buildContinueButton() {
    final isSpeaking = widget.exercise.type == QuestionTypeEnum.speaking;
    final Color accentColor = isSpeaking || widget.isCorrect ? AppCustomColor.successGreen : AppCustomColor.errorRed;

    return ExerciseContinueButton(
      onPressed: () {
        if (!widget.readOnly) {
          final trackingData = _trackingData();
          if (trackingData != null) {
            AppService.instance.appTrackingService.trackRoleplayQuizContinue(trackingData);
          }
        }
        widget.onContinue?.call();
      },
      text: t.exercise.exerciseSkipButton,
      backgroundColor: accentColor,
      textColor: AppCustomColor.textWhite,
      isEnabled: true,
    );
  }

  Widget _buildResultStatusRow() {
    final isSpeaking = widget.exercise.type == QuestionTypeEnum.speaking;
    final Color accentColor = isSpeaking || widget.isCorrect ? AppCustomColor.successGreen : AppCustomColor.errorRed;
    final String statusText = isSpeaking
        ? t.exercise.exerciseCompleteVoiceTask
        : (widget.isCorrect ? t.exercise.exerciseFeedbackCorrectTitle : t.exercise.exerciseFeedbackIncorrectTitle);
    final Widget icon = isSpeaking || widget.isCorrect ? AppAsset.icons.app.icTick.image(width: 24.w, height: 24.w) : AppAsset.icons.app.icClose.image(width: 24.w, height: 24.w);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          icon,
          8.horizontalSpace,
          AppText(
            statusText,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: AppStyle.text16.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget lessonBody = _buildExerciseLessonBody(context, widget.exercise.type);
    Widget bottomButton = widget.showResult ? _buildContinueButton() : _buildBottomButton(context, lessonBody);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Column(
        children: [
          if (widget.showResult) ...[
            _buildResultStatusRow(),
            8.verticalSpace,
          ],
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                children: [
                  AbsorbPointer(
                    absorbing: widget.readOnly && widget.exercise.type != QuestionTypeEnum.speaking,
                    child: lessonBody,
                  ),
                  60.verticalSpace,
                ],
              ),
            ),
          ),
          12.verticalSpace,
          bottomButton,
        ],
      ),
    );
  }

  void _trackReviewReplay() {
    final trackingData = _trackingData();
    if (trackingData == null) return;
    AppService.instance.appTrackingService.trackRoleplayQuizReviewReplay(trackingData);
  }
}
