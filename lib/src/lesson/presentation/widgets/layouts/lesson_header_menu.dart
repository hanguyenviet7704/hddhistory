part of '../../../lesson.dart';

/// Actions offered by the keypoint/lesson header overflow menu.
enum _LessonHeaderMenuAction { changeTheme, reportProblem }

/// Overflow menu (grid icon) shown at the top-right of the keypoint/lesson
/// shell header. Consolidates "Change theme" and "Report a problem" into a
/// single dropdown (keypoint design) — replacing the earlier standalone
/// change-theme icon next to the close button plus a separate flag button.
class LessonHeaderMenu extends StatelessWidget {
  const LessonHeaderMenu({super.key, required this.onReportProblem});

  /// Opens the report-issue flow. The current keypoint / lesson id is resolved
  /// by the caller (see [LessonPage]), which this widget doesn't have access to.
  final VoidCallback onReportProblem;

  @override
  Widget build(BuildContext context) {
    final iconColor = studyThemeOnBg(context, AppCustomColor.textQuaternary);
    return PopupMenuButton<_LessonHeaderMenuAction>(
      key: const ValueKey('lesson-shell-overflow-menu-button'),
      tooltip: '',
      padding: EdgeInsets.zero,
      splashRadius: 20.w,
      // Drop the sheet just below the 36px header row, right-aligned under the
      // grid icon (mirrors the design's anchored dropdown).
      offset: Offset(0, 40.h),
      color: AppCustomColor.backgroundWhite,
      elevation: 8,
      shadowColor: AppCustomColor.scrimOverlay,
      constraints: BoxConstraints(minWidth: 200.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      onOpened: () => AppService.instance.appTrackingService.trackEvent(TrackingKey.keypointReadMenuOpen),
      icon: SizedBox(
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
      onSelected: (action) {
        AppHaptic.select();
        if (action == _LessonHeaderMenuAction.changeTheme) {
          StudyThemeTracking.track(TrackingKey.themeChangeClick, parameters: {'source': 'keypoint'});
          ChangeBackgroundSheet.show(context, source: 'keypoint');
        } else {
          onReportProblem();
        }
      },
      itemBuilder: (context) => [
        _menuItem(
          context,
          action: _LessonHeaderMenuAction.changeTheme,
          iconAsset: AppAsset.svg.app.icChangeTheme,
          label: context.l10n.studyTheme.changeBackground,
        ),
        _menuItem(
          context,
          action: _LessonHeaderMenuAction.reportProblem,
          iconAsset: AppAsset.svg.app.icReportFlag,
          label: context.l10n.lessonReport.reportAnIssue,
        ),
      ],
    );
  }

  PopupMenuItem<_LessonHeaderMenuAction> _menuItem(
    BuildContext context, {
    required _LessonHeaderMenuAction action,
    required String iconAsset,
    required String label,
  }) {
    return PopupMenuItem<_LessonHeaderMenuAction>(
      value: action,
      height: 48.h,
      child: Row(
        children: [
          SvgPicture.asset(
            iconAsset,
            width: 20.w,
            height: 20.w,
            colorFilter: const ColorFilter.mode(AppCustomColor.brandPrimary, BlendMode.srcIn),
          ),
          12.horizontalSpace,
          Expanded(
            child: AppText(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.text14.copyWith(
                color: AppCustomColor.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
