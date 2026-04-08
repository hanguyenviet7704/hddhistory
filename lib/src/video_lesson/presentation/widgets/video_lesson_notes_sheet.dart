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
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        height: widget.state.notesMode == VideoLessonNotesMode.editor ? min(MediaQuery.sizeOf(context).height * 0.84, 700.h) : 406.h,
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 10.h),
              width: 44.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppCustomColor.borderDefault,
                borderRadius: BorderRadius.circular(30.r),
              ),
            ),
            Expanded(
              child: widget.state.notesMode == VideoLessonNotesMode.editor
                  ? _VideoLessonNoteEditorView(
                      state: widget.state,
                      controller: _noteController,
                      focusNode: _focusNode,
                      scrollController: _scrollController,
                      onClose: widget.onClose,
                      onBack: widget.onBack,
                      onSave: widget.onSave,
                    )
                  : _VideoLessonNoteListView(
                      state: widget.state,
                      onClose: widget.onClose,
                      onRetry: widget.onRetry,
                      onLoadMore: widget.onLoadMore,
                      onAddNote: widget.onAddNote,
                      onEditNote: widget.onEditNote,
                      onDeleteNote: widget.onDeleteNote,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
