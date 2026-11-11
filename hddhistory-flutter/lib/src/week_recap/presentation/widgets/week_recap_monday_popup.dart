part of '../../week_recap.dart';

/// "Tuần NN đã sẵn sàng" — offered on the first open of every day, Monday
/// through Sunday, until the week is viewed.
///
/// The two buttons promise different things: "Xem hành trình" opens the poster
/// and ends the offers for good; "Để sau" mutes them for the rest of today and
/// the popup returns tomorrow morning. That split is the product rule the
/// pasted spec spells out — "hiển thị khi user vào app lần đầu trong tất cả
/// các ngày từ Thứ 2 đến chủ nhật".
class WeekRecapMondayPopup extends StatelessWidget {
  const WeekRecapMondayPopup._({required this.recap});

  final WeekRecapEntity recap;

  /// Resolves true for "Xem hành trình", false for "Để sau".
  ///
  /// It reports the choice rather than acting on it: this dialog is raised by
  /// [WeekRecapPopupHost] from the shell, so it sits OUTSIDE the route's
  /// providers and its own context is defunct the moment it pops. Both the cubit
  /// call and the navigation belong to the caller.
  static Future<bool?> show(BuildContext context, WeekRecapEntity recap) {
    return showDialog<bool>(
      context: context,
      barrierColor: AppCustomColor.textPrimary.withValues(alpha: 0.55),
      // Not dismissible by tapping outside: the two buttons mean different
      // things to the server, and a barrier tap would be a third answer with
      // nowhere to record it.
      barrierDismissible: false,
      builder: (_) => WeekRecapMondayPopup._(recap: recap),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.weekRecap;
    final week = l10n.weekLabel(number: recap.weekNumber.toString().padLeft(2, '0'));

    return WeekRecapDialogShell(
      artwork: WeekRecapPosterPreview(recap: recap, height: 196.h),
      title: l10n.mondayTitle(week: week),
      body: l10n.mondayBody,
      primaryLabel: l10n.mondayPrimary,
      secondaryLabel: l10n.mondaySecondary,
      onPrimary: () => Navigator.of(context).pop(true),
      onSecondary: () => Navigator.of(context).pop(false),
    );
  }
}

/// The two popups share one frame so they cannot drift apart: same card width,
/// radius, artwork slot, and button stack.
class WeekRecapDialogShell extends StatelessWidget {
  const WeekRecapDialogShell({
    super.key,
    required this.artwork,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final Widget artwork;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final secondary = secondaryLabel;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 26.w),
      child: Container(
        constraints: BoxConstraints(maxWidth: 330.w),
        // 10 at the bottom, not 22: the text button below carries its own
        // tap-height, and the re-exported design tightened the card around it.
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 10.h),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(26.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(18.r), child: artwork),
            SizedBox(height: 18.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFont.mulish,
                fontWeight: FontWeight.w800,
                fontSize: 20.sp,
                letterSpacing: -0.3,
                color: AppCustomColor.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFont.mulish,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
                height: 1.5,
                color: AppCustomColor.weekRecapPopupBody,
              ),
            ),
            SizedBox(height: 18.h),
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: onPrimary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppCustomColor.brandPrimary,
                  foregroundColor: AppCustomColor.textWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99.r)),
                ),
                child: Text(
                  primaryLabel,
                  style: TextStyle(
                    fontFamily: AppFont.mulish,
                    fontWeight: FontWeight.w800,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ),
            if (secondary != null) ...[
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                height: 38.h,
                child: TextButton(
                  onPressed: onSecondary,
                  child: Text(
                    secondary,
                    style: TextStyle(
                      fontFamily: AppFont.mulish,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                      color: AppCustomColor.weekRecapMutedAction,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The top of the poster, cropped to a banner — what the popups show.
///
/// The real poster, not a stock illustration: the reader is being invited to
/// look at THEIR week, and a generic picture would make the invitation feel
/// like an ad.
class WeekRecapPosterPreview extends StatelessWidget {
  const WeekRecapPosterPreview({
    super.key,
    required this.recap,
    required this.height,
    this.blurred = false,
  });

  final WeekRecapEntity recap;
  final double height;

  /// Frosts the preview for the locked popup, where the week is not ready yet.
  final bool blurred;

  @override
  Widget build(BuildContext context) {
    final poster = SizedBox(
      height: height,
      width: double.infinity,
      child: OverflowBox(
        alignment: Alignment.topCenter,
        maxHeight: double.infinity,
        child: WeekRecapPoster(recap: recap),
      ),
    );

    if (!blurred) return poster;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6), child: poster),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppCustomColor.backgroundWhite.withValues(alpha: 0.05),
                  AppCustomColor.backgroundWhite.withValues(alpha: 0.72),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
