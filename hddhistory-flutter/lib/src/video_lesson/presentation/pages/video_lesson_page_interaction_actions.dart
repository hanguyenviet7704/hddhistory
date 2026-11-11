part of '../../video_lesson.dart';

extension _VideoLessonPageInteractionActions on _VideoLessonPageState {
  Future<void> _handleDeleteNote(UserVideoLessonNoteEntity note) async {
    final didConfirm =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: AppText(
              context.l10n.videoLesson.deleteNoteTitle,
              style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary),
            ),
            content: AppText(
              context.l10n.videoLesson.deleteNoteMessage,
              style: AppStyle.text14.copyWith(
                color: AppCustomColor.textSecondary,
                height: 1.75,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  AppHaptic.select();
                  dialogContext.pop(false);
                },
                child: AppText(
                  context.l10n.videoLesson.keepEditingButton,
                  style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () {
                  AppHaptic.select();
                  dialogContext.pop(true);
                },
                child: AppText(
                  context.l10n.videoLesson.deleteNoteButton,
                  style: AppStyle.text14.copyWith(color: AppCustomColor.errorRed),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!didConfirm) return;

    final trackingData = _trackingData(_cubit.state);
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackVideoLessonNoteDeleteClick(
        trackingData,
        nodeId: _cubit.state.nodeId,
        noteId: note.id,
      );
    }

    await _cubit.deleteNote(note);
  }

  Future<void> _handleSaveNote() async {
    final state = _cubit.state;
    final trackingData = _trackingData(state);
    final editingNote = state.editingNote;

    if (trackingData != null) {
      AppService.instance.appTrackingService.trackVideoLessonNoteSaveClick(
        trackingData,
        nodeId: state.nodeId,
        noteMode: editingNote == null ? 'create' : 'edit',
        noteId: editingNote?.id,
        atSecond: editingNote?.atSecond ?? state.positionSeconds,
      );
    }

    await _cubit.saveNote();
  }

  void _handleOpenCreateNote() {
    final state = _cubit.state;
    final trackingData = _trackingData(state);
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackVideoLessonAddNoteClick(
        trackingData,
        nodeId: state.nodeId,
        noteMode: 'create',
        atSecond: state.positionSeconds,
      );
    }
    _cubit.openCreateNote();
  }

  void _handleOpenEditNote(UserVideoLessonNoteEntity note) {
    final trackingData = _trackingData(_cubit.state);
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackVideoLessonNoteEditClick(
        trackingData,
        nodeId: _cubit.state.nodeId,
        noteId: note.id,
        noteMode: 'edit',
      );
    }
    _cubit.openEditNote(note);
  }

  void _handleSubmitQuestion() {
    final state = _cubit.state;
    final prompt = state.currentQuestionPrompt;
    if (prompt == null) return;
    final trackingData = _trackingData(state);
    if (trackingData != null) {
      final previewResult = state.currentQuestionIsSupported
          ? resolveChoiceCheckResult(
              isMultipleChoice: state.currentQuestionIsMultipleChoice,
              isNoCorrectSingleChoice: state.currentQuestionIsNoCorrectSingleChoice,
              selectedAnswerIndex: state.currentSelectedAnswerIndex,
              selectedAnswersIndices: state.currentSelectedAnswerIndices,
              correctOptionsIndices: _previewCorrectIndices(state),
            )
          : true;

      AppService.instance.appTrackingService.trackVideoLessonQuizCheck(
        trackingData,
        nodeId: state.nodeId,
        questionId: prompt.question.id.toString(),
        atSecond: prompt.atSecond,
        isCorrect: previewResult,
      );
    }
    _cubit.submitCurrentQuestion();
  }

  Future<void> _handleContinueAfterQuestion() async {
    final state = _cubit.state;
    final result = state.currentQuestionResult;
    final trackingData = _trackingData(state);
    if (trackingData != null && result != null) {
      AppService.instance.appTrackingService.trackVideoLessonQuizContinue(
        trackingData,
        nodeId: state.nodeId,
        questionId: result.questionId.toString(),
        atSecond: result.atSecond,
        isCorrect: result.isCorrect,
      );
    }

    final shouldResume = _cubit.continueAfterQuestion();
    if (shouldResume) {
      await _controller?.play();
      _cubit.setPlaybackState(isPlaying: true, controlsVisible: false);
      _scheduleControlsAutoHide();
    }
  }

  Set<int> _previewCorrectIndices(VideoLessonState state) {
    final question = state.currentQuestion;
    if (question == null) return const {};
    final options = questionRuntimeOptions(question);
    final indices = <int>{};
    for (int i = 0; i < options.length; i++) {
      if (options[i].isCorrect) indices.add(i);
    }
    if (state.currentQuestionIsNoCorrectSingleChoice && state.currentSelectedAnswerIndex >= 0) {
      return {state.currentSelectedAnswerIndex};
    }
    return indices;
  }
}
