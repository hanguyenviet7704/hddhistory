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
  QuestionPayloadEntity get _payload => widget.exercise.typedPayload;
  bool get _isSpeakingPayload => _payload is QuestionSpeakingPayloadEntity;
  bool get _isNoCorrectSingleChoicePayload => _payload is QuestionSingleChoiceNoCorrectAnswerPayloadEntity;
  bool get _isUnsupportedPayload => _payload is QuestionUnsupportedPayloadEntity;

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

  void _handleUnsupportedContinue(BuildContext context) {
    if (!widget.readOnly) {
      final trackingData = _trackingData();
      if (trackingData != null) {
        AppService.instance.appTrackingService.trackRoleplayQuizContinue(trackingData);
      }
    }
    _storeExerciseResult(context, true);
    widget.onContinue?.call();
  }

  void _storeExerciseResult(BuildContext context, bool isCorrect) {
    final ExerciseResultEntity baseResult = switch (_payload) {
      QuestionSingleChoicePayloadEntity() ||
      QuestionSingleChoiceNoCorrectAnswerPayloadEntity() ||
      QuestionMultipleChoicePayloadEntity() => context.read<ChoiceCubit>().toExerciseResult(),
      QuestionDragAndDropPayloadEntity() => context.read<DragAndDropCubit>().toExerciseResult(),
      QuestionArrangeTheSequencePayloadEntity() => context.read<ArrangeTheSequenceCubit>().toExerciseResult(),
      QuestionCuesPlacementPayloadEntity() => context.read<CuesPlacementCubit>().toExerciseResult(),
      QuestionStressPlacementPayloadEntity() => context.read<MarkStressWordCubit>().toExerciseResult(),
      QuestionSpeakingPayloadEntity() => context.read<SpeakingCubit>().toExerciseResult(),
      QuestionUnsupportedPayloadEntity() => ExerciseResultEntity(
        exerciseId: widget.exercise.exerciseId.isNotEmpty ? widget.exercise.exerciseId : widget.exercise.id.toString(),
        type: widget.exercise.type,
        form: widget.exercise.form,
      ),
      _ => ExerciseResultEntity(
        exerciseId: widget.exercise.exerciseId.isNotEmpty ? widget.exercise.exerciseId : widget.exercise.id.toString(),
        type: widget.exercise.type,
        form: widget.exercise.form,
      ),
    };

    context.read<RoleplayCubit>().setExerciseResult(
      contentId: widget.contentId,
      contentIndex: widget.contentIndex,
      result: baseResult.copyWith(passed: isCorrect),
    );
  }

  Widget _buildExerciseLessonBody(BuildContext context) {
    final onChecked = widget.readOnly ? (_) {} : (bool isCorrect) => _handleAnswerChecked(context, isCorrect);
    return switch (_payload) {
      QuestionSingleChoicePayloadEntity() => SingleChoiceLessonBody(
        onAnswerChecked: onChecked,
        isReadOnly: widget.readOnly,
      ),
      QuestionSingleChoiceNoCorrectAnswerPayloadEntity() => SingleChoiceNoCorrectAnswerLessonBody(
        onAnswerChecked: onChecked,
        isReadOnly: widget.readOnly,
      ),
      QuestionMultipleChoicePayloadEntity() => MultipleChoiceLessonBody(
        onAnswerChecked: onChecked,
        isReadOnly: widget.readOnly,
      ),
      QuestionDragAndDropPayloadEntity() => DragAndDropLessonBody(
        onAnswerChecked: onChecked,
        isReadOnly: widget.readOnly,
      ),
      QuestionArrangeTheSequencePayloadEntity() => ArrangeTheSequenceLessonBody(
        onAnswerChecked: onChecked,
        isReadOnly: widget.readOnly,
      ),
      QuestionCuesPlacementPayloadEntity() => CuesPlacementLessonBody(
        onAnswerChecked: onChecked,
        isReadOnly: widget.readOnly,
      ),
      QuestionStressPlacementPayloadEntity() => MarkStressWordLessonBody(
        onAnswerChecked: onChecked,
        isReadOnly: widget.readOnly,
      ),
      QuestionSpeakingPayloadEntity() => SpeakingLessonBody(
        onAnswerChecked: onChecked,
        onRoleplayReplayTap: widget.readOnly ? _trackReviewReplay : null,
        isReadOnly: widget.readOnly,
      ),
      QuestionUnsupportedPayloadEntity() => UnsupportedLessonBody(
        question: widget.exercise,
        onContinue: widget.readOnly ? null : () => _handleUnsupportedContinue(context),
        isReadOnly: widget.readOnly,
      ),
      _ => UnsupportedLessonBody(
        question: widget.exercise,
        onContinue: widget.readOnly ? null : () => _handleUnsupportedContinue(context),
        isReadOnly: widget.readOnly,
      ),
    };
  }

  Widget _buildBottomButton(BuildContext context, Widget lessonBody) {
    return switch (lessonBody) {
      SingleChoiceLessonBody body => body.buildBottomButton(context),
      SingleChoiceNoCorrectAnswerLessonBody body => body.buildBottomButton(context),
      MultipleChoiceLessonBody body => body.buildBottomButton(context),
      DragAndDropLessonBody body => body.buildBottomButton(context),
      ArrangeTheSequenceLessonBody body => body.buildBottomButton(context),
      CuesPlacementLessonBody body => body.buildBottomButton(context),
      MarkStressWordLessonBody body => body.buildBottomButton(context),
      SpeakingLessonBody body => body.buildBottomButton(context),
      UnsupportedLessonBody body => body.buildBottomButton(context),
      TheoryLessonBody body => body.buildBottomButton(context),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildContinueButton() {
    final bool shouldShowSuccess = _isSpeakingPayload || _isNoCorrectSingleChoicePayload || _isUnsupportedPayload || widget.isCorrect;
    final Color accentColor = shouldShowSuccess ? AppCustomColor.successGreen : AppCustomColor.errorRed;

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
      text: l10n.exercise.exerciseSkipButton,
      backgroundColor: accentColor,
      textColor: AppCustomColor.textWhite,
      isEnabled: true,
    );
  }

  Widget _buildResultStatusRow() {
    final bool shouldShowSuccess = _isSpeakingPayload || _isNoCorrectSingleChoicePayload || _isUnsupportedPayload || widget.isCorrect;
    final Color accentColor = shouldShowSuccess ? AppCustomColor.successGreen : AppCustomColor.errorRed;
    final String statusText = _isSpeakingPayload
        ? l10n.exercise.exerciseCompleteVoiceTask
        : (_isNoCorrectSingleChoicePayload || _isUnsupportedPayload)
        ? l10n.exercise.exerciseLessonCompleteTitle
        : (widget.isCorrect ? l10n.exercise.exerciseFeedbackCorrectTitle : l10n.exercise.exerciseFeedbackIncorrectTitle);
    final Widget icon = shouldShowSuccess ? AppAsset.icons.app.icTick.image(width: 24.w, height: 24.w) : AppAsset.icons.app.icClose.image(width: 24.w, height: 24.w);

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
    Widget lessonBody = _buildExerciseLessonBody(context);
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
                    absorbing: widget.readOnly && !_isSpeakingPayload,
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
