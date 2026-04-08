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
    final isEditor = widget.state.notesMode == VideoLessonNotesMode.editor;

    return _VideoLessonDraggableBottomSheetFrame(
      height: isEditor ? min(MediaQuery.sizeOf(context).height * 0.84, 700.h) : 406.h,
      onDismiss: widget.onClose,
      handleKey: const ValueKey('video-lesson-notes-sheet-handle'),
      dragRegionKey: const ValueKey('video-lesson-notes-sheet-header-drag-region'),
      header: AnimatedSwitcher(
        duration: _videoLessonMediumAnimationDuration,
        switchInCurve: _videoLessonEntranceCurve,
        switchOutCurve: _videoLessonExitCurve,
        transitionBuilder: _buildNotesModeTransition,
        child: _VideoLessonNotesSheetHeader(
          key: ValueKey('video-lesson-notes-sheet-header-${widget.state.notesMode.name}'),
          state: widget.state,
          onClose: widget.onClose,
          onBack: widget.onBack,
        ),
      ),
      child: AnimatedSwitcher(
        duration: _videoLessonMediumAnimationDuration,
        switchInCurve: _videoLessonEntranceCurve,
        switchOutCurve: _videoLessonExitCurve,
        layoutBuilder: (currentChild, previousChildren) {
          final children = <Widget>[...previousChildren];
          if (currentChild != null) children.add(currentChild);
          return Stack(
            fit: StackFit.expand,
            children: children,
          );
        },
        transitionBuilder: _buildNotesModeTransition,
        child: isEditor
            ? KeyedSubtree(
                key: const ValueKey('video-lesson-note-editor-view'),
                child: _VideoLessonNoteEditorView(
                  state: widget.state,
                  controller: _noteController,
                  focusNode: _focusNode,
                  scrollController: _scrollController,
                  onSave: widget.onSave,
                ),
              )
            : KeyedSubtree(
                key: const ValueKey('video-lesson-note-list-view'),
                child: _VideoLessonNoteListView(
                  state: widget.state,
                  onRetry: widget.onRetry,
                  onLoadMore: widget.onLoadMore,
                  onAddNote: widget.onAddNote,
                  onEditNote: widget.onEditNote,
                  onDeleteNote: widget.onDeleteNote,
                ),
              ),
      ),
    );
  }
}

Widget _buildNotesModeTransition(Widget child, Animation<double> animation) {
  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: _videoLessonEntranceCurve,
    reverseCurve: _videoLessonExitCurve,
  );

  return FadeTransition(
    opacity: curvedAnimation,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.08, 0),
        end: Offset.zero,
      ).animate(curvedAnimation),
      child: child,
    ),
  );
}
