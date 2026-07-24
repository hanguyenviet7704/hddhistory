part of '../../../lesson.dart';

/// Overflow button (grid icon) shown at the top-right of the keypoint/lesson
/// shell header. Opens the mode-aware [KeypointSettingsSheet]: Change theme +
/// Report a problem always, plus Text display (Read) or Speed + Background
/// music (Listen) depending on [mode].
class LessonHeaderMenu extends StatelessWidget {
  const LessonHeaderMenu({
    super.key,
    required this.mode,
    required this.onReportProblem,
    required this.onOpenSpeedSheet,
  });

  /// Current Read/Listen mode — drives which mode-specific card (and the
  /// Background music row) the sheet shows.
  final LessonEntryMode mode;

  /// Opens the report-issue flow. The current keypoint / lesson id is resolved
  /// by the caller (see [LessonPage]), which this widget doesn't have access to.
  final VoidCallback onReportProblem;

  /// Opens the existing audio Speed sheet (Listen mode only) — reuses
  /// [LessonPage]'s established pause/resume + tracking flow around
  /// [LessonAudioCubit] rather than reimplementing it here.
  final VoidCallback onOpenSpeedSheet;

  @override
  Widget build(BuildContext context) {
    final iconColor = studyThemeOnBg(context, AppCustomColor.textQuaternary);

    return GestureDetector(
      key: const ValueKey('lesson-shell-overflow-menu-button'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AppHaptic.select();
        AppService.instance.appTrackingService.trackEvent(TrackingKey.keypointReadMenuOpen);
        // Spec event (sheet "3. Learning" menu block): mode-aware menu open.
        AppService.instance.appTrackingService.trackEvent(
          TrackingKey.keypointMenuOpen,
          parameters: {'mode': mode.isRead ? 'read' : 'listen'},
        );
        KeypointSettingsSheet.show(
          context,
          mode: mode,
          onReportProblem: onReportProblem,
          onOpenSpeedSheet: onOpenSpeedSheet,
        );
      },
      child: SizedBox(
        width: 36.w,
        height: 36.w,
        child: Center(
          child: SvgPicture.asset(
            AppAsset.svg.app.icGridMenu,
            width: 20.w,
            height: 20.w,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
