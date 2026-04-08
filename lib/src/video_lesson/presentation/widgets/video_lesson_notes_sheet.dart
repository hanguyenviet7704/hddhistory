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
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.noteDraft);
  }

  @override
  void didUpdateWidget(covariant VideoLessonNotesSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.noteDraft == widget.state.noteDraft) return;
    if (_controller.text == widget.state.noteDraft) return;
    _controller.value = TextEditingValue(
      text: widget.state.noteDraft,
      selection: TextSelection.collapsed(offset: widget.state.noteDraft.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                      controller: _controller,
                      onClose: widget.onClose,
                      onBack: widget.onBack,
                      onSave: widget.onSave,
                      onDraftChanged: widget.onDraftChanged,
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
