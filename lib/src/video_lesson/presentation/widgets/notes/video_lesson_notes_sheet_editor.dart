part of '../../../video_lesson.dart';

class _VideoLessonNoteEditorView extends StatelessWidget {
  const _VideoLessonNoteEditorView({
    required this.state,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.onSave,
  });

  final VideoLessonState state;
  final quill.QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = max(bottomInset, MediaQuery.viewPaddingOf(context).bottom);

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(22.w, 4.h, 22.w, 8.h),
            child: DefaultTextStyle(
              style: AppStyle.text16.copyWith(
                color: AppCustomColor.textPrimary,
                height: 1.6,
              ),
              child: quill.QuillEditor(
                controller: controller,
                focusNode: focusNode,
                scrollController: scrollController,
                config: quill.QuillEditorConfig(
                  autoFocus: true,
                  expands: true,
                  padding: EdgeInsets.zero,
                  placeholder: context.l10n.videoLesson.noteEditorHint,
                  textInputAction: TextInputAction.newline,
                  scrollable: true,
                ),
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
              _VideoLessonNoteEditorToolbar(
                controller: controller,
                focusNode: focusNode,
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
              16.verticalSpace,
              AppButton.primary(
                onPressed: state.noteSaveStatus == VideoLessonCrudStatus.loading ? null : onSave,
                fullWidthBtn: true,
                height: 54.h,
                disabled: state.noteSaveStatus == VideoLessonCrudStatus.loading || videoLessonNoteContentIsBlank(state.noteDraft),
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
