part of '../../learning_import.dart';

/// The import's progress bar, on both surfaces that draw one.
///
/// Shared rather than duplicated because the two are the SAME bar to the reader:
/// minimising the waiting screen replaces the full-width one with the shell
/// toast's, and they must not disagree — nor restart. Both read
/// [LearningImportCubit.progress], which is one continuous value for the life of
/// the job; see [ImportProgressCreep] for why the server's percent cannot be
/// drawn directly.
class ImportProgressBar extends StatelessWidget {
  const ImportProgressBar({
    super.key,
    required this.minHeight,
    this.showLabel = false,
  });

  final double minHeight;

  /// The "42%" line under the bar. On the waiting screen, where the number is
  /// the only thing to look at; not in the toast, which has a title instead.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: AppDI.injector.get<LearningImportCubit>().progress,
      builder: (context, progress, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(99.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: minHeight,
                backgroundColor: const Color(0xFFEDF0F5),
                valueColor: const AlwaysStoppedAnimation(
                  AppCustomColor.brandPrimary,
                ),
              ),
            ),
            if (showLabel) ...[
              12.verticalSpace,
              AppText(
                context.l10n.learningImport.generatingPercent(
                  // Floored, not rounded: a bar drawn at 99.6% that says 100%
                  // is claiming to be finished while it visibly is not.
                  percent: (progress * 100).floor(),
                ),
                style: AppStyle.textBold12.copyWith(
                  fontSize: 13.sp,
                  color: AppCustomColor.brandPrimary,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
