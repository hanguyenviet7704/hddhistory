part of '../../week_recap.dart';

/// "Hành trình đang tiếp diễn" — what the banner says when the week it would
/// wrap has not finished yet.
///
/// Its secondary button appears only for a reader who already has recaps. For
/// anyone else there is nothing earlier to look at, and offering it would open
/// an empty Sổ tay.
class WeekRecapLockedPopup extends StatelessWidget {
  const WeekRecapLockedPopup._({required this.hasArchive});

  final bool hasArchive;

  /// Resolves true when the reader asked for "Xem lại các tuần trước".
  ///
  /// Navigation is the caller's, for the reason [WeekRecapMondayPopup.show]
  /// gives: a popped dialog's context can no longer route.
  static Future<bool?> show(BuildContext context, {required bool hasArchive}) {
    return showDialog<bool>(
      context: context,
      barrierColor: AppCustomColor.textPrimary.withValues(alpha: 0.5),
      builder: (_) => WeekRecapLockedPopup._(hasArchive: hasArchive),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.weekRecap;

    return WeekRecapDialogShell(
      artwork: SizedBox(
        height: 168.h,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The week's own artwork, out of focus — a frosted glimpse of the
            // poster being wrapped, not a plain placeholder. Scaled a hair past
            // the frame so the blur cannot bleed the edges in as transparency;
            // the shell's ClipRRect crops the overhang.
            const ColoredBox(color: AppCustomColor.weekRecapPaper),
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Transform.scale(
                scale: 1.06,
                child: Image.asset(
                  weekRecapArtworkAsset(),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
            DecoratedBox(
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
            Center(
              child: Container(
                width: 54.w,
                height: 54.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppCustomColor.weekRecapBannerStart.withValues(alpha: 0.94),
                  boxShadow: [
                    BoxShadow(
                      color: AppCustomColor.weekRecapBannerStart.withValues(alpha: 0.35),
                      offset: Offset(0, 8.h),
                      blurRadius: 20.r,
                    ),
                  ],
                ),
                child: Icon(Icons.lock_outline, size: 26.w, color: AppCustomColor.textWhite),
              ),
            ),
          ],
        ),
      ),
      title: l10n.lockedTitle,
      body: l10n.lockedBody,
      primaryLabel: l10n.lockedPrimary,
      onPrimary: () => Navigator.of(context).pop(false),
      secondaryLabel: hasArchive ? l10n.lockedSecondary : null,
      onSecondary: hasArchive ? () => Navigator.of(context).pop(true) : null,
    );
  }
}
