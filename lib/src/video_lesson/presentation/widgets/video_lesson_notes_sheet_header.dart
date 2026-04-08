part of '../../video_lesson.dart';

class _VideoLessonNotesSheetHeader extends StatelessWidget {
  const _VideoLessonNotesSheetHeader({
    super.key,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: AppText(
                    context.l10n.videoLesson.notesTitle,
                    maxLines: 1,
                    style: AppStyle.textBold18.copyWith(
                      color: AppCustomColor.textPrimary,
                      height: 1.4,
                    ),
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
