part of '../../lesson.dart';

class ReportIssueSheet extends StatelessWidget {
  const ReportIssueSheet({
    super.key,
    required this.lessonId,
    required this.keypointId,
    required this.keypointTitle,
    required this.keypointImage,
  });

  final String lessonId;
  final String keypointId;
  final String keypointTitle;
  final String keypointImage;

  static Future<void> show(
    BuildContext context, {
    required String lessonId,
    required String keypointId,
    required String keypointTitle,
    required String keypointImage,
  }) {
    final reportParams = {'lesson_id': lessonId, 'keypoint_id': keypointId};
    AppService.instance.appTrackingService.trackEvent(
      TrackingKey.keypointReportScrView,
      parameters: reportParams,
    );
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.op(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      routeSettings: const RouteSettings(name: RouteNamed.reportIssueSheet),
      builder: (_) => BlocProvider(
        create: (_) => ReportIssueCubit(AppDI.injector.get<SubmitIssueReportUseCase>()),
        child: ReportIssueSheet(
          lessonId: lessonId,
          keypointId: keypointId,
          keypointTitle: keypointTitle,
          keypointImage: keypointImage,
        ),
      ),
    ).whenComplete(
      () => AppService.instance.appTrackingService.trackEvent(
        TrackingKey.keypointReportClose,
        parameters: reportParams,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: BlocListener<ReportIssueCubit, ReportIssueState>(
      listenWhen: (prev, cur) => prev.status != cur.status,
      listener: (context, state) {
        if (state.status == ReportIssueStatus.success) {
          context.back();
          DMessage.showMessage(type: MessageType.success, message: context.l10n.lessonReport.submitSuccess);
        } else if (state.status == ReportIssueStatus.failure) {
          DMessage.showMessage(type: MessageType.error, message: state.errorMessage ?? '');
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
            return Container(
              decoration: BoxDecoration(
                color: AppCustomColor.backgroundWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: Column(
                children: [
                  _DragHandle(),
                  _SheetTitle(context.l10n.lessonReport.reportAnIssue),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, keyboardHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ReportingSection(
                            label: context.l10n.lessonReport.reporting,
                            keypointTitle: keypointTitle,
                            keypointImage: keypointImage,
                          ),
                          24.verticalSpace,
                          _ReasonSection(
                            lessonId: lessonId,
                            keypointId: keypointId,
                            keypointTitle: keypointTitle,
                            keypointImage: keypointImage,
                          ),
                          24.verticalSpace,
                        ],
                      ),
                    ),
                  ),
                  BlocBuilder<ReportIssueCubit, ReportIssueState>(
                    buildWhen: (prev, cur) =>
                        prev.canSubmit != cur.canSubmit || prev.isLoading != cur.isLoading,
                    builder: (context, state) {
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          24.w,
                          8.h,
                          24.w,
                          MediaQuery.of(context).padding.bottom + 16.h,
                        ),
                        child: _SubmitButton(
                          title: context.l10n.lessonReport.submitReport,
                          enabled: state.canSubmit,
                          isLoading: state.isLoading,
                          onTap: () => context.read<ReportIssueCubit>().submit(
                            lessonId: lessonId,
                            keypointId: keypointId,
                            keypointTitle: keypointTitle,
                            keypointImage: keypointImage,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12.h, bottom: 4.h),
      child: Center(
        child: Container(
          width: 40.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: const Color(0xFFD1D5DC),
            borderRadius: BorderRadius.circular(100.r),
          ),
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 0),
      child: AppText(
        title,
        style: AppStyle.text20.copyWith(
          fontWeight: FontWeight.w600,
          color: AppCustomColor.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ReportingSection extends StatelessWidget {
  const _ReportingSection({
    required this.label,
    required this.keypointTitle,
    required this.keypointImage,
  });

  final String label;
  final String keypointTitle;
  final String keypointImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        16.verticalSpace,
        AppText(
          label.toUpperCase(),
          style: AppStyle.text12.copyWith(
            color: AppCustomColor.textQuaternary,
            letterSpacing: 0.3,
            fontWeight: FontWeight.w400,
          ),
        ),
        12.verticalSpace,
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppCustomColor.neutral100,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: CachedNetworkImage(
                  imageUrl: keypointImage,
                  width: 64.w,
                  height: 64.w,
                  fit: BoxFit.cover,
                  errorWidget: (context, error, stack) => Container(
                    width: 64.w,
                    height: 64.w,
                    color: AppCustomColor.brandPrimary100,
                  ),
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: AppText(
                  keypointTitle,
                  style: AppStyle.text16.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppCustomColor.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReasonSection extends StatelessWidget {
  const _ReasonSection({
    required this.lessonId,
    required this.keypointId,
    required this.keypointTitle,
    required this.keypointImage,
  });

  final String lessonId;
  final String keypointId;
  final String keypointTitle;
  final String keypointImage;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportIssueCubit, ReportIssueState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              context.l10n.lessonReport.whyReporting,
              style: AppStyle.text14.copyWith(
                fontWeight: FontWeight.w600,
                color: AppCustomColor.textPrimary,
              ),
            ),
            8.verticalSpace,
            ...IssueReportReason.values.map(
              (reason) => _ReasonItem(
                label: reason.label(context),
                isSelected: state.selectedReasons.contains(reason),
                onTap: () => context.read<ReportIssueCubit>().toggleReason(reason),
                showDivider: reason != IssueReportReason.values.last,
              ),
            ),
            24.verticalSpace,
            AppText(
              context.l10n.lessonReport.tellUsMore,
              style: AppStyle.text14.copyWith(
                fontWeight: FontWeight.w600,
                color: AppCustomColor.textPrimary,
              ),
            ),
            8.verticalSpace,
            _CommentField(
              hint: context.l10n.lessonReport.describeIssuePlaceholder,
              onChanged: context.read<ReportIssueCubit>().updateComment,
            ),
          ],
        );
      },
    );
  }
}

class _ReasonItem extends StatelessWidget {
  const _ReasonItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.showDivider,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            AppHaptic.select();
            onTap();
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 13.h),
            child: Row(
              children: [
                _CheckBox(isSelected: isSelected),
                12.horizontalSpace,
                Expanded(
                  child: AppText(
                    label,
                    style: AppStyle.text16.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppCustomColor.textPrimary : AppCustomColor.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: const Color(0xFFF3F4F6),
          ),
      ],
    );
  }
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.isSelected});
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(
        color: isSelected ? AppCustomColor.successGreen : Colors.transparent,
        border: isSelected ? null : Border.all(color: const Color(0xFFCDD5DF), width: 2),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: isSelected
          ? Icon(Icons.check_rounded, size: 14.sp, color: Colors.white)
          : null,
    );
  }
}

class _CommentField extends StatelessWidget {
  const _CommentField({required this.hint, required this.onChanged});
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120.h,
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        border: Border.all(color: AppCustomColor.borderDefault),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TextField(
        onChanged: onChanged,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: AppStyle.text16.copyWith(color: AppCustomColor.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppStyle.text16.copyWith(color: AppCustomColor.textTertiary),
          contentPadding: EdgeInsets.all(16.w),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.title,
    required this.enabled,
    required this.isLoading,
    required this.onTap,
  });

  final String title;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled
          ? () {
              AppHaptic.select();
              onTap();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54.h,
        decoration: BoxDecoration(
          color: enabled ? AppCustomColor.brandPrimary : AppCustomColor.borderDefault,
          borderRadius: BorderRadius.circular(1000.r),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : AppText(
                  title,
                  style: AppStyle.text16.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
