part of '../../../video_lesson.dart';

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
    return _VideoLessonPressableScale(
      onTap: onOpen,
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: ValueKey('video-lesson-note-card-${note.id}'),
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
