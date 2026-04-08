part of '../../video_lesson.dart';

class _VideoLessonNoteListView extends StatelessWidget {
  const _VideoLessonNoteListView({
    required this.state,
    required this.onRetry,
    required this.onLoadMore,
    required this.onAddNote,
    required this.onEditNote,
    required this.onDeleteNote,
  });

  final VideoLessonState state;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final VoidCallback onAddNote;
  final ValueChanged<UserVideoLessonNoteEntity> onEditNote;
  final ValueChanged<UserVideoLessonNoteEntity> onDeleteNote;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
                itemCount: state.notes.length + 1,
                separatorBuilder: (_, index) => 10.verticalSpace,
                itemBuilder: (context, index) {
                  if (index == state.notes.length) {
                    if (state.notesReachedEnd) return const SizedBox.shrink();
                    return Padding(
                      padding: EdgeInsets.only(top: 2.h),
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
                    onOpen: () => onEditNote(note),
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
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h + MediaQuery.viewPaddingOf(context).bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: AppCustomColor.borderDefault,
              ),
            ),
          ),
          child: AppButton.secondary(
            onPressed: onAddNote,
            fullWidthBtn: true,
            height: 54.h,
            borderRadius: BorderRadius.circular(1000.r),
            decoration: ShapeDecoration(
              color: AppCustomColor.backgroundBrandSoft,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1000.r)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: AppCustomColor.streakActive, size: 24.r),
                8.horizontalSpace,
                AppText(
                  context.l10n.videoLesson.addNoteButton,
                  style: AppStyle.textBold16.copyWith(
                    color: AppCustomColor.streakActive,
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
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final UserVideoLessonNoteEntity note;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('video-lesson-note-card-${note.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: Container(
        padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 16.h),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundGray,
          border: Border.all(color: AppCustomColor.borderDefault),
          borderRadius: BorderRadius.circular(12.r),
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
                    height: 1.5,
                  ),
                ),
                if (kDebugMode) ...[
                  const Spacer(),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 132.w),
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
              ],
            ),
            10.verticalSpace,
            IgnorePointer(
              child: _VideoLessonFormattedNotePreview(note: note),
            ),
          ],
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
