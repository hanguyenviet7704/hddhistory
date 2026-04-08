part of '../../video_lesson.dart';

class _VideoLessonNoteEditorView extends StatelessWidget {
  const _VideoLessonNoteEditorView({
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
    final bottomPadding = max(bottomInset, MediaQuery.viewPaddingOf(context).bottom);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(12.w, 14.h, 12.w, 8.h),
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
          child: Padding(
            padding: EdgeInsets.fromLTRB(22.w, 8.h, 22.w, 8.h),
            child: TextField(
              controller: controller,
              onChanged: onDraftChanged,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              expands: true,
              minLines: null,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              style: AppStyle.text16.copyWith(
                color: AppCustomColor.textPrimary,
                height: 1.6,
              ),
              decoration: InputDecoration(
                hintText: context.l10n.videoLesson.noteEditorHint,
                hintStyle: AppStyle.text16.copyWith(
                  color: AppCustomColor.textSecondary,
                  height: 1.6,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, bottomPadding + 12.h),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppCustomColor.borderDefault),
            ),
          ),
          child: Column(
            children: [
              const _VideoLessonNoteEditorToolbar(),
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
              16.verticalSpace,
              AppButton.primary(
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
            ],
          ),
        ),
      ],
    );
  }
}

class _VideoLessonNoteEditorToolbar extends StatelessWidget {
  const _VideoLessonNoteEditorToolbar();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const _VideoLessonToolbarIcon(icon: Icons.format_bold_rounded),
          8.horizontalSpace,
          const _VideoLessonToolbarIcon(icon: Icons.format_italic_rounded),
          12.horizontalSpace,
          const _VideoLessonToolbarChip(label: 'Text', selected: true),
          8.horizontalSpace,
          const _VideoLessonToolbarChip(label: 'Bullets', selected: false),
          8.horizontalSpace,
          const _VideoLessonToolbarChip(label: 'Numbers', selected: false),
        ],
      ),
    );
  }
}

class _VideoLessonToolbarIcon extends StatelessWidget {
  const _VideoLessonToolbarIcon({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36.r,
      height: 36.r,
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundGray,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(
        icon,
        size: 18.r,
        color: AppCustomColor.textSecondary,
      ),
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
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: selected ? AppCustomColor.backgroundBrandSoft : Colors.transparent,
        border: Border.all(
          color: selected ? AppCustomColor.borderBrand : AppCustomColor.borderDefault,
        ),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Center(
        child: AppText(
          label,
          style: AppStyle.text14.copyWith(
            color: selected ? AppCustomColor.streakActive : AppCustomColor.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
