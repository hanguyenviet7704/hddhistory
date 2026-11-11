part of '../../learning_import.dart';

/// The minimised import, riding above the bottom nav wherever the reader goes.
///
/// This is what makes "you can leave this screen" true rather than merely
/// stated. Before it, walking away from generation meant losing sight of it
/// entirely until a popup fired minutes later — the run was still going, but
/// nothing on screen said so, which reads exactly like the run was abandoned.
///
/// Deliberately NOT a `SnackBar`: those are owned by a `ScaffoldMessenger`,
/// dismiss themselves on a timer, and vanish on navigation. This has to survive
/// tab switches and stay until the job actually ends, so it lives on the shell
/// beside [ImportDonePopupHost].
class ImportProgressToast extends StatelessWidget {
  const ImportProgressToast({super.key, required this.bottomInset});

  /// How far above the bottom edge to sit — the caller knows about the nav bar,
  /// this widget should not.
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LearningImportCubit, LearningImportState>(
      bloc: AppDI.injector.get<LearningImportCubit>(),
      buildWhen: (previous, current) =>
          previous.job?.id != current.job?.id ||
          previous.job?.percent != current.job?.percent ||
          previous.isFinished != current.isFinished ||
          previous.toastDismissed != current.toastDismissed,
      builder: (context, state) {
        final job = state.job;
        // Nothing running and nothing just finished — the shell should be
        // exactly as it was before this widget existed.
        if (job == null || state.toastDismissed) return const SizedBox.shrink();
        if (!job.isRunning && !state.isFinished) return const SizedBox.shrink();

        return Positioned(
          left: 14.w,
          right: 14.w,
          bottom: bottomInset,
          child: _ToastCard(state: state),
        );
      },
    );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({required this.state});

  final LearningImportState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.learningImport;
    final done = state.isFinished;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0x2E0D121C),
              blurRadius: 34.r,
              offset: Offset(0, 14.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: const Color(0xFFFBF7ED),
                borderRadius: BorderRadius.circular(12.r),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.description_outlined,
                size: 20.w,
                color: AppCustomColor.brandPrimary,
              ),
            ),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    done ? l10n.toastDone : l10n.toastTitle,
                    style: AppStyle.textBold14.copyWith(fontSize: 13.5.sp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  6.verticalSpace,
                  ImportProgressBar(minHeight: 6.h),
                ],
              ),
            ),
            if (done) ...[
              10.horizontalSpace,
              _ViewButton(lessonId: state.finishedLessonId ?? ''),
            ],
            8.horizontalSpace,
            _DismissButton(),
          ],
        ),
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  const _ViewButton({required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.learningImport.toastView,
      child: GestureDetector(
        onTap: () {
          if (lessonId.isEmpty) return;
          AppHaptic.select();
          // Dismiss first: the reader is about to be looking at the lesson, and
          // a toast still announcing it would be talking over itself.
          AppDI.injector.get<LearningImportCubit>().dismissToast();
          LessonReaderRoute(lessonId).push(context);
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppCustomColor.brandPrimary,
            borderRadius: BorderRadius.circular(99.r),
          ),
          child: AppText(
            context.l10n.learningImport.toastView,
            style: AppStyle.textBold12.copyWith(
              fontSize: 13.sp,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _DismissButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.common.close,
      child: GestureDetector(
        onTap: () {
          AppHaptic.select();
          AppDI.injector.get<LearningImportCubit>().dismissToast();
        },
        child: Container(
          width: 24.w,
          height: 24.w,
          decoration: const BoxDecoration(
            color: Color(0xFFEDF0F5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close_rounded,
            size: 12.w,
            color: AppCustomColor.textTertiary,
          ),
        ),
      ),
    );
  }
}
