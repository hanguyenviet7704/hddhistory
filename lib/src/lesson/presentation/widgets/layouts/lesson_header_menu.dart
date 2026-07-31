part of '../../../lesson.dart';

/// Overflow button (grid icon) shown at the top-right of the keypoint shell
/// header. Opens [KeypointSettingsSheet]: Change theme, Text display, Report a
/// problem, plus reading-speed and background-music rows — all always shown now
/// (the unified screen has no Read/Listen mode split left to branch on).
class LessonHeaderMenu extends StatelessWidget {
  const LessonHeaderMenu({
    super.key,
    required this.onReportProblem,
  });

  /// Opens the report-issue flow. The current keypoint / lesson id is resolved
  /// by the caller (see [LessonPage]), which this widget doesn't have access to.
  final VoidCallback onReportProblem;

  @override
  Widget build(BuildContext context) {
    // Theme-independent, like the rest of the header chrome — see
    // [KeypointHeaderChrome]. It used to be `studyThemeOnBg(...)`, which returns
    // WHITE over a dark study background: once the button circle became
    // permanently white, that painted a white icon on a white circle and the
    // button looked empty.
    const iconColor = KeypointHeaderChrome.icon;

    return GestureDetector(
      key: const ValueKey('lesson-shell-overflow-menu-button'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AppHaptic.select();
        AppService.instance.appTrackingService.trackEvent(TrackingKey.keypointReadMenuOpen);
        AppService.instance.appTrackingService.trackEvent(TrackingKey.keypointMenuOpen);
        KeypointSettingsSheet.show(context, onReportProblem: onReportProblem);
      },
      child: SizedBox(
        // Slightly larger than the circle so the tap target stays comfortable
        // without changing the header's spacing.
        width: 36.w,
        height: 36.w,
        child: Center(
          child: KeypointHeaderButtonChrome(
            child: SvgPicture.asset(
              // The design's 2x2 outline grid, not the old solid-square glyph.
              AppAsset.svg.app.icKpGrid,
              width: 18.w,
              height: 18.w,
              colorFilter: const ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}
