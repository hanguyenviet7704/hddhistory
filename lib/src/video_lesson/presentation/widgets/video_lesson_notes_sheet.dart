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
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        ),
        child: Column(
          children: [
            6.verticalSpace,
            Container(
              width: 50.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.r),
              ),
            ),
            Expanded(
              child: widget.state.notesMode == VideoLessonNotesMode.editor
                  ? _VideoLessonNoteEditor(
                      state: widget.state,
                      controller: _controller,
                      onClose: widget.onClose,
                      onBack: widget.onBack,
                      onSave: widget.onSave,
                      onDraftChanged: widget.onDraftChanged,
                    )
                  : _VideoLessonNoteList(
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

class _VideoLessonNoteList extends StatelessWidget {
  const _VideoLessonNoteList({
    required this.state,
    required this.onClose,
    required this.onRetry,
    required this.onLoadMore,
    required this.onAddNote,
    required this.onEditNote,
    required this.onDeleteNote,
  });

  final VideoLessonState state;
  final VoidCallback onClose;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final VoidCallback onAddNote;
  final ValueChanged<UserVideoLessonNoteEntity> onEditNote;
  final ValueChanged<UserVideoLessonNoteEntity> onDeleteNote;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.h),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    AppText(
                      context.l10n.videoLesson.notesTitle,
                      style: AppStyle.textBold18.copyWith(
                        color: AppCustomColor.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    if (state.notes.isNotEmpty) ...[
                      8.horizontalSpace,
                      AppText(
                        state.notes.length.toString(),
                        style: AppStyle.textBold18.copyWith(
                          color: AppCustomColor.textTertiary,
                          height: 1.5,
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
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if (state.notesStatus == VideoLessonNotesStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.notesStatus == VideoLessonNotesStatus.failure) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText(
                          state.notesErrorMessage ?? context.l10n.videoLesson.retryNotesLoadButton,
                          maxLines: 4,
                          textAlign: TextAlign.center,
                          style: AppStyle.text14.copyWith(
                            color: AppCustomColor.textSecondary,
                            height: 1.75,
                          ),
                        ),
                        16.verticalSpace,
                        AppButton.secondary(
                          onPressed: onRetry,
                          borderRadius: BorderRadius.circular(1000.r),
                          child: AppText(
                            context.l10n.videoLesson.retryNotesLoadButton,
                            style: AppStyle.textBold16.copyWith(color: AppCustomColor.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state.notes.isEmpty) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      12.verticalSpace,
                      AppAsset.images.app.note.image(
                        width: 144.w,
                        height: 144.w,
                        fit: BoxFit.contain,
                      ),
                      12.verticalSpace,
                      AppText(
                        context.l10n.videoLesson.notesEmptyMessage,
                        maxLines: 4,
                        textAlign: TextAlign.center,
                        style: AppStyle.text16.copyWith(
                          color: AppCustomColor.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                itemCount: state.notes.length + 1,
                separatorBuilder: (_, index) => 8.verticalSpace,
                itemBuilder: (context, index) {
                  if (index == state.notes.length) {
                    if (state.notesReachedEnd) return const SizedBox.shrink();
                    return Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Column(
                        children: [
                          AppButton.secondary(
                            onPressed: state.notesLoadMoreStatus == VideoLessonNotesStatus.loadingMore ? null : onLoadMore,
                            fullWidthBtn: true,
                            borderRadius: BorderRadius.circular(1000.r),
                            height: 44.h,
                            child: state.notesLoadMoreStatus == VideoLessonNotesStatus.loadingMore
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : AppText(
                                    context.l10n.videoLesson.loadMoreNotesButton,
                                    style: AppStyle.textBold16.copyWith(
                                      color: AppCustomColor.textSecondary,
                                    ),
                                  ),
                          ),
                          if ((state.notesLoadMoreErrorMessage ?? '').isNotEmpty) ...[
                            8.verticalSpace,
                            AppText(
                              state.notesLoadMoreErrorMessage!,
                              style: AppStyle.text12.copyWith(
                                color: AppCustomColor.errorRed,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  final note = state.notes[index];
                  return _VideoLessonNoteCard(
                    note: note,
                    onEdit: () => onEditNote(note),
                    onDelete: () => onDeleteNote(note),
                  );
                },
              );
            },
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h + MediaQuery.viewPaddingOf(context).bottom),
          color: Colors.white,
          child: AppButton.secondary(
            onPressed: onAddNote,
            fullWidthBtn: true,
            height: 54.h,
            borderRadius: BorderRadius.circular(1000.r),
            decoration: ShapeDecoration(
              color: const Color(0xFFF2F1FE),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1000.r)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: const Color(0xFF4B44CA), size: 24.r),
                8.horizontalSpace,
                AppText(
                  context.l10n.videoLesson.addNoteButton,
                  style: AppStyle.textBold16.copyWith(
                    color: const Color(0xFF4B44CA),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VideoLessonNoteCard extends StatelessWidget {
  const _VideoLessonNoteCard({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  final UserVideoLessonNoteEntity note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        border: Border.all(color: const Color(0xFFEBF0F7)),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppText(
                _formatNoteTime(note.atSecond),
                style: AppStyle.text14.copyWith(
                  color: AppCustomColor.textTertiary,
                  height: 1.75,
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.more_horiz_rounded,
                  size: 20.r,
                  color: AppCustomColor.textTertiary,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                    return;
                  }
                  onDelete();
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: AppText(
                      context.l10n.videoLesson.editNoteButton,
                      style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: AppText(
                      context.l10n.videoLesson.deleteNoteButton,
                      style: AppStyle.text14.copyWith(color: AppCustomColor.errorRed),
                    ),
                  ),
                ],
              ),
            ],
          ),
          8.verticalSpace,
          AppText(
            note.content,
            maxLines: 4,
            style: AppStyle.text16.copyWith(
              color: AppCustomColor.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoLessonNoteEditor extends StatelessWidget {
  const _VideoLessonNoteEditor({
    required this.state,
    required this.controller,
    required this.onClose,
    required this.onBack,
    required this.onSave,
    required this.onDraftChanged,
  });

  final VideoLessonState state;
  final TextEditingController controller;
  final VoidCallback onClose;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final ValueChanged<String> onDraftChanged;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
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
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  onChanged: onDraftChanged,
                  keyboardType: TextInputType.multiline,
                  minLines: 12,
                  maxLines: null,
                  style: AppStyle.text16.copyWith(
                    color: AppCustomColor.textPrimary,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: context.l10n.videoLesson.noteEditorHint,
                    hintStyle: AppStyle.text16.copyWith(
                      color: AppCustomColor.textSecondary,
                      height: 1.5,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                16.verticalSpace,
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: const [
                    _VideoLessonToolbarChip(label: 'B', selected: false),
                    _VideoLessonToolbarChip(label: 'I', selected: false),
                    _VideoLessonToolbarChip(label: 'Text', selected: true),
                    _VideoLessonToolbarChip(label: 'Bullets', selected: false),
                    _VideoLessonToolbarChip(label: 'Numbers', selected: false),
                  ],
                ),
                if ((state.notesActionErrorMessage ?? '').isNotEmpty) ...[
                  12.verticalSpace,
                  AppText(
                    state.notesActionErrorMessage!,
                    maxLines: 4,
                    style: AppStyle.text12.copyWith(
                      color: AppCustomColor.errorRed,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, max(bottomInset, MediaQuery.viewPaddingOf(context).bottom) + 12.h),
          color: Colors.white,
          child: AppButton.primary(
            onPressed: state.noteSaveStatus == VideoLessonCrudStatus.loading ? null : onSave,
            fullWidthBtn: true,
            height: 54.h,
            disabled: state.noteSaveStatus == VideoLessonCrudStatus.loading || state.noteDraft.trim().isEmpty,
            borderRadius: BorderRadius.circular(1000.r),
            child: state.noteSaveStatus == VideoLessonCrudStatus.loading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : AppText(
                    context.l10n.videoLesson.saveNoteButton,
                    style: AppStyle.textBold16.copyWith(color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }
}

class _VideoLessonToolbarChip extends StatelessWidget {
  const _VideoLessonToolbarChip({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF2F1FE) : Colors.transparent,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Center(
        child: AppText(
          label,
          style: AppStyle.text14.copyWith(
            color: selected ? const Color(0xFF4B44CA) : const Color(0xFF364153),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

String _formatNoteTime(int? atSecond) {
  final totalSeconds = (atSecond ?? 0).clamp(0, 359999);
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
