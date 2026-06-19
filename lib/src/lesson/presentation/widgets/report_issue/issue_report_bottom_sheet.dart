part of '../../../lesson.dart';

/// Opens the "Report an issue" bottom sheet for the current lesson/keypoint.
Future<void> showIssueReportBottomSheet(
  BuildContext context, {
  required String lessonId,
  required String courseId,
  required KeypointEntity keypoint,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.op(0.6),
    builder: (_) => BlocProvider(
      create: (_) => IssueReportCubit(
        reportIssueUseCase: AppDI.injector.get<ReportIssueUseCase>(),
        lessonId: lessonId,
        courseId: courseId,
      ),
      child: IssueReportSheet(keypoint: keypoint),
    ),
  );
}

class IssueReportSheet extends StatefulWidget {
  const IssueReportSheet({super.key, required this.keypoint});

  final KeypointEntity keypoint;

  @override
  State<IssueReportSheet> createState() => _IssueReportSheetState();
}

class _IssueReportSheetState extends State<IssueReportSheet> {
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<IssueReportCubit, IssueReportState>(
      listenWhen: (previous, current) =>
          previous.isSuccess != current.isSuccess || previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.isSuccess) {
          Navigator.of(context).pop();
          DMessage.showMessage(
            type: MessageType.success,
            // TODO(l10n): localize when keys are added to the pipeline.
            message: 'Thanks! Your report has been submitted.',
          );
          return;
        }
        if (state.errorMessage != null) {
          DMessage.showMessage(type: MessageType.error, message: state.errorMessage!);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: 0.9.sh),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(),
              _buildTitle(),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReportingTarget(),
                      24.verticalSpace,
                      AppText(
                        // TODO(l10n)
                        'Why are you reporting this lesson?',
                        style: AppStyle.text16.copyWith(fontWeight: FontWeight.w600, color: AppCustomColor.textPrimary),
                        maxLines: 2,
                      ),
                      8.verticalSpace,
                      ...IssueReportReason.values.map(_buildReasonTile),
                      24.verticalSpace,
                      AppText(
                        // TODO(l10n)
                        'Tell us more',
                        style: AppStyle.text16.copyWith(fontWeight: FontWeight.w600, color: AppCustomColor.textPrimary),
                      ),
                      12.verticalSpace,
                      _buildCommentField(),
                      24.verticalSpace,
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: EdgeInsets.only(top: 12.h, bottom: 4.h),
      width: 40.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: AppCustomColor.borderSecondary,
        borderRadius: BorderRadius.circular(100.r),
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: AppText(
        // TODO(l10n)
        'Report an issue',
        style: AppStyle.text20.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.textPrimary),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildReportingTarget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          // TODO(l10n)
          'REPORTING',
          style: AppStyle.text12.copyWith(fontWeight: FontWeight.w600, color: AppCustomColor.textTertiary),
        ),
        12.verticalSpace,
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppCustomColor.borderSecondary),
          ),
          child: Row(
            children: [
              if (widget.keypoint.image.trim().isNotEmpty)
                DCachedImage(
                  url: widget.keypoint.image,
                  width: 48.w,
                  height: 48.w,
                  borderRadius: BorderRadius.circular(12.r),
                )
              else
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: AppCustomColor.brandPrimary50,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              12.horizontalSpace,
              Expanded(
                child: AppText(
                  widget.keypoint.title.text,
                  style: AppStyle.text16.copyWith(fontWeight: FontWeight.w600, color: AppCustomColor.textPrimary),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReasonTile(IssueReportReason reason) {
    return BlocBuilder<IssueReportCubit, IssueReportState>(
      buildWhen: (previous, current) =>
          previous.selectedReasons.contains(reason) != current.selectedReasons.contains(reason),
      builder: (context, state) {
        final isSelected = state.selectedReasons.contains(reason);
        return InkWell(
          onTap: () => context.read<IssueReportCubit>().toggleReason(reason),
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Row(
              children: [
                _buildCheckbox(isSelected),
                12.horizontalSpace,
                Expanded(
                  child: AppText(
                    reason.label,
                    style: AppStyle.text16.copyWith(color: AppCustomColor.textPrimary),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckbox(bool isSelected) {
    return Container(
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(
        color: isSelected ? AppCustomColor.successGreen : AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: isSelected ? AppCustomColor.successGreen : AppCustomColor.borderSecondary,
          width: 1.5,
        ),
      ),
      child: isSelected ? Icon(Icons.check_rounded, size: 14.w, color: Colors.white) : null,
    );
  }

  Widget _buildCommentField() {
    return TextField(
      controller: _commentController,
      onChanged: (value) => context.read<IssueReportCubit>().updateComment(value),
      maxLines: 4,
      minLines: 4,
      style: AppStyle.text16.copyWith(color: AppCustomColor.textPrimary),
      decoration: InputDecoration(
        // TODO(l10n)
        hintText: 'Describe the issue so we can fix it faster',
        hintStyle: AppStyle.text16.copyWith(color: AppCustomColor.textTertiary),
        contentPadding: EdgeInsets.all(16.w),
        filled: true,
        fillColor: AppCustomColor.backgroundWhite,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppCustomColor.borderSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppCustomColor.brandPrimary),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<IssueReportCubit, IssueReportState>(
      builder: (context, state) {
        return AppButton.primary(
          fullWidthBtn: true,
          disabled: !state.canSubmit,
          onPressed: state.canSubmit ? () => context.read<IssueReportCubit>().submit() : null,
          child: state.isSubmitting
              ? SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : AppText(
                  // TODO(l10n)
                  'Submit report',
                  style: AppStyle.text16.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                ),
        );
      },
    );
  }
}
