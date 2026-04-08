part of '../../video_lesson.dart';

class VideoLessonNotesSheet extends StatefulWidget {
  const VideoLessonNotesSheet({
    super.key,
    required this.state,
    required this.onClose,
    required this.onBack,
    required this.onAddNote,
    required this.onSave,
    required this.onRetry,
    required this.onLoadMore,
    required this.onDraftChanged,
    required this.onEditNote,
    required this.onDeleteNote,
  });

  final VideoLessonState state;
  final VoidCallback onClose;
  final VoidCallback onBack;
  final VoidCallback onAddNote;
  final VoidCallback onSave;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final ValueChanged<String> onDraftChanged;
  final ValueChanged<UserVideoLessonNoteEntity> onEditNote;
  final ValueChanged<UserVideoLessonNoteEntity> onDeleteNote;

  @override
  State<VideoLessonNotesSheet> createState() => _VideoLessonNotesSheetState();
}

class _VideoLessonNotesSheetState extends State<VideoLessonNotesSheet> {
  quill.QuillController? _controller;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  String _lastSerializedDraft = '';

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    _replaceController(widget.state.noteDraft);
  }

  @override
  void didUpdateWidget(covariant VideoLessonNotesSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.noteDraft != widget.state.noteDraft) {
      final nextDraft = videoLessonCanonicalizeNoteContent(widget.state.noteDraft);
      if (_lastSerializedDraft != nextDraft) {
        _replaceController(widget.state.noteDraft);
      }
    }

    final enteredEditor = oldWidget.state.notesMode != VideoLessonNotesMode.editor && widget.state.notesMode == VideoLessonNotesMode.editor;
    if (!enteredEditor) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller
      ?..removeListener(_handleControllerChanged)
      ..dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  quill.QuillController get _noteController => _controller!;

  void _replaceController(String rawDraft) {
    final nextDocument = videoLessonNoteDocumentFromContent(rawDraft);
    final nextController = quill.QuillController(
      document: nextDocument,
      selection: TextSelection.collapsed(offset: max(0, nextDocument.length - 1)),
    );
    nextController.addListener(_handleControllerChanged);
    _controller
      ?..removeListener(_handleControllerChanged)
      ..dispose();
    _controller = nextController;
    _lastSerializedDraft = videoLessonEncodeNoteDocument(nextDocument);
  }

  void _handleControllerChanged() {
    final controller = _controller;
    if (controller == null) return;
    final nextDraft = videoLessonEncodeNoteDocument(controller.document);
    if (_lastSerializedDraft == nextDraft) return;
    _lastSerializedDraft = nextDraft;
    widget.onDraftChanged(nextDraft);
  }

  @override
  Widget build(BuildContext context) {
    return _VideoLessonDraggableBottomSheetFrame(
      height: widget.state.notesMode == VideoLessonNotesMode.editor ? min(MediaQuery.sizeOf(context).height * 0.84, 700.h) : 406.h,
      onDismiss: widget.onClose,
      handleKey: const ValueKey('video-lesson-notes-sheet-handle'),
      dragRegionKey: const ValueKey('video-lesson-notes-sheet-header-drag-region'),
      header: _VideoLessonNotesSheetHeader(
        state: widget.state,
        onClose: widget.onClose,
        onBack: widget.onBack,
      ),
      child: widget.state.notesMode == VideoLessonNotesMode.editor
          ? _VideoLessonNoteEditorView(
              state: widget.state,
              controller: _noteController,
              focusNode: _focusNode,
              scrollController: _scrollController,
              onSave: widget.onSave,
            )
          : _VideoLessonNoteListView(
              state: widget.state,
              onRetry: widget.onRetry,
              onLoadMore: widget.onLoadMore,
              onAddNote: widget.onAddNote,
              onEditNote: widget.onEditNote,
              onDeleteNote: widget.onDeleteNote,
            ),
    );
  }
}

class _VideoLessonNotesSheetHeader extends StatelessWidget {
  const _VideoLessonNotesSheetHeader({
    required this.state,
    required this.onClose,
    required this.onBack,
  });

  final VideoLessonState state;
  final VoidCallback onClose;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    if (state.notesMode == VideoLessonNotesMode.editor) {
      return Padding(
        padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 8.h),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20.r,
                color: AppCustomColor.textSecondary,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: onClose,
              icon: Icon(
                Icons.close_rounded,
                size: 24.r,
                color: AppCustomColor.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                AppText(
                  context.l10n.videoLesson.notesTitle,
                  style: AppStyle.textBold18.copyWith(
                    color: AppCustomColor.textPrimary,
                    height: 1.4,
                  ),
                ),
                if (state.notes.isNotEmpty) ...[
                  8.horizontalSpace,
                  AppText(
                    state.notes.length.toString(),
                    style: AppStyle.textBold18.copyWith(
                      color: AppCustomColor.textTertiary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(
              Icons.close_rounded,
              size: 24.r,
              color: AppCustomColor.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
