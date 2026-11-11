part of '../../learning_import.dart';

/// Shown when the reader finishes everything that EXISTS of a partially
/// generated lesson and taps Continue into a keypoint the server has not
/// delivered yet (text, or the narration it still owes).
///
/// Exists so that boundary is a sentence instead of a shrug: without it the
/// Continue button silently dropped the reader back on the roadmap, which
/// reads as a bug ("nút không làm gì"), and before the readiness gate it was
/// worse — the deck opened a half-made keypoint with no voice. The popup says
/// what is happening and where they will land; the roadmap they land on shows
/// the same "Đang tạo…" nodes refreshing themselves.
class NextKeypointGeneratingPopup extends StatelessWidget {
  const NextKeypointGeneratingPopup({super.key});

  /// Resolves when the sheet is dismissed (button or swipe) — callers exit to
  /// the lesson's roadmap right after.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => const NextKeypointGeneratingPopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.learningImport;
    // Same sheet anatomy as ClosePopupLesson: white, rounded top, bottom
    // safe-area baked into the padding so the sheet sits flush.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, bottomInset + 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28.w,
            height: 28.w,
            child: CircularProgressIndicator(
              strokeWidth: 2.5.w,
              color: AppCustomColor.brandPrimary,
            ),
          ),
          16.verticalSpace,
          AppText(
            l10n.nextGeneratingTitle,
            style: AppStyle.text20.copyWith(
              color: const Color(0xFF0D121C),
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
          8.verticalSpace,
          AppText(
            l10n.nextGeneratingBody,
            style: AppStyle.text14.copyWith(
              color: const Color(0xFF364152),
              height: 1.75,
            ),
            maxLines: 4,
            textAlign: TextAlign.center,
          ),
          20.verticalSpace,
          Semantics(
            button: true,
            label: l10n.nextGeneratingCta,
            child: AppButton.primary(
              key: const Key('next-keypoint-generating-ok'),
              onPressed: () {
                AppHaptic.select();
                Navigator.of(context).pop();
              },
              padding: EdgeInsets.symmetric(vertical: 12.h),
              borderRadius: BorderRadius.circular(1000.r),
              child: SizedBox(
                width: double.infinity,
                child: AppText(
                  l10n.nextGeneratingCta,
                  style: AppStyle.textBold16.copyWith(
                    color: AppCustomColor.textWhite,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
