part of '../../lesson.dart';

/// Mode-aware bottom sheet reachable from the keypoint header's overflow (⊞)
/// menu ([LessonHeaderMenu]). Replaces the earlier 2-item popup with a row of
/// equal action cards — Change theme (always) + a mode-specific control
/// (Text display in Read, Speed in Listen) + Report a problem (always) — and,
/// in Listen mode only, a Background music row underneath.
class KeypointSettingsSheet extends StatelessWidget {
  const KeypointSettingsSheet({
    super.key,
    required this.mode,
    required this.onReportProblem,
    required this.onOpenSpeedSheet,
    required this.onOptionSelected,
  });

  final LessonEntryMode mode;
  final VoidCallback onReportProblem;
  final VoidCallback onOpenSpeedSheet;

  /// Called when the user picks any action card (so `show` can tell an option
  /// tap apart from a swipe/scrim dismiss when logging keypoint_menu_close).
  final VoidCallback onOptionSelected;

  static Future<void> show(
    BuildContext context, {
    required LessonEntryMode mode,
    required VoidCallback onReportProblem,
    required VoidCallback onOpenSpeedSheet,
  }) {
    var optionSelected = false;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppCustomColor.scrimOverlay,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26.r))),
      builder: (_) => KeypointSettingsSheet(
        mode: mode,
        onReportProblem: onReportProblem,
        onOpenSpeedSheet: onOpenSpeedSheet,
        onOptionSelected: () => optionSelected = true,
      ),
    ).whenComplete(() {
      // Spec event (sheet "3. Learning" menu block): only a swipe-down / scrim
      // dismiss counts as a menu close; picking an action card does not.
      if (!optionSelected) {
        AppService.instance.appTrackingService.trackEvent(TrackingKey.keypointMenuClose);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      key: const ValueKey('keypoint-settings-sheet'),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 14.h, 24.w, 36.h + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: const Color(0xFFDADCE4),
                borderRadius: BorderRadius.circular(99.r),
              ),
            ),
          ),
          24.verticalSpace,
          // IntrinsicHeight bounds the Row's cross-axis so CrossAxisAlignment
          // .stretch can size the cards equally. Without it, `stretch` inside
          // this min-height sheet had no definite height to stretch to and the
          // cards' RenderPointerListener failed the `hasSize` layout assertion
          // ("RenderBox was not laid out"), so the sheet rendered blank behind
          // the scrim and the frame crashed. (The card label must NOT use
          // enableFitScaleDown here — its FittedBox can't report the intrinsic
          // height IntrinsicHeight needs.)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Expanded(
                child: _KeypointSettingsCard(
                  key: const ValueKey('keypoint-settings-change-theme'),
                  iconAsset: AppAsset.svg.app.icChangeTheme,
                  label: context.l10n.studyTheme.changeBackground,
                  onTap: () {
                    onOptionSelected();
                    context.back();
                    AppService.instance.appTrackingService.trackEvent(TrackingKey.keypointMenuThemeClick);
                    StudyThemeTracking.track(TrackingKey.themeChangeClick, parameters: {'source': 'keypoint'});
                    ChangeBackgroundSheet.show(context, source: 'keypoint');
                  },
                ),
              ),
              8.horizontalSpace,
              Expanded(
                child: mode.isRead
                    ? _KeypointSettingsCard(
                        key: const ValueKey('keypoint-settings-text-display'),
                        iconAsset: AppAsset.svg.app.icTextDisplay,
                        label: context.l10n.lesson.textDisplayTitle,
                        onTap: () {
                          onOptionSelected();
                          context.back();
                          AppService.instance.appTrackingService.trackEvent(TrackingKey.keypointMenuTextdisplayClick);
                          TextDisplaySheet.show(context);
                        },
                      )
                    : _KeypointSettingsCard(
                        key: const ValueKey('keypoint-settings-speed'),
                        iconAsset: AppAsset.svg.app.icPlaybackSpeed,
                        label: context.l10n.lesson.audioSpeedTitle,
                        onTap: () {
                          onOptionSelected();
                          context.back();
                          onOpenSpeedSheet();
                        },
                      ),
              ),
              8.horizontalSpace,
              Expanded(
                child: _KeypointSettingsCard(
                  key: const ValueKey('keypoint-settings-report'),
                  iconAsset: AppAsset.svg.app.icReportFlag,
                  label: context.l10n.lessonReport.reportAnIssue,
                  onTap: () {
                    onOptionSelected();
                    context.back();
                    AppService.instance.appTrackingService.trackEvent(TrackingKey.keypointMenuReportClick);
                    onReportProblem();
                  },
                ),
              ),
              ],
            ),
          ),
          if (mode.isAudio) ...[
            14.verticalSpace,
            const _BackgroundMusicRow(),
          ],
        ],
      ),
    );
  }
}

class _KeypointSettingsCard extends StatelessWidget {
  const _KeypointSettingsCard({
    super.key,
    required this.iconAsset,
    required this.label,
    required this.onTap,
  });

  final String iconAsset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 18.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FB),
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                iconAsset,
                width: 30.w,
                height: 30.w,
                colorFilter: const ColorFilter.mode(AppCustomColor.brandPrimary, BlendMode.srcIn),
              ),
              10.verticalSpace,
              AppText(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppStyle.textBold12.copyWith(color: AppCustomColor.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Listen-mode-only ambient audio toggle. Wired to [StudyThemeCubit.soundOn]
/// — the study background's own ambient sound layer already plays behind the
/// lesson shell ([ThemedBackground] wraps [LessonShellLayout]'s body), so
/// "Background music" in the keypoint sheet controls that same toggle rather
/// than introducing a second, competing audio layer.
class _BackgroundMusicRow extends StatelessWidget {
  const _BackgroundMusicRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudyThemeCubit, StudyThemeState>(
      builder: (context, state) {
        return Container(
          key: const ValueKey('keypoint-settings-background-music'),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FB),
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                AppAsset.svg.app.icBackgroundMusic,
                width: 22.w,
                height: 22.w,
                colorFilter: const ColorFilter.mode(AppCustomColor.brandPrimary, BlendMode.srcIn),
              ),
              12.horizontalSpace,
              Expanded(
                child: AppText(
                  context.l10n.lesson.backgroundMusicLabel,
                  style: AppStyle.textBold14.copyWith(color: AppCustomColor.textPrimary),
                ),
              ),
              _KeypointToggleSwitch(
                key: const ValueKey('keypoint-settings-background-music-toggle'),
                value: state.soundOn,
                onChanged: (value) {
                  AppService.instance.appTrackingService.trackEvent(
                    TrackingKey.keypointMenuBgmusicToggle,
                    parameters: {'state': value ? 'on' : 'off'},
                  );
                  context.read<StudyThemeCubit>().setSound(value);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Small pill switch matching the design's 50×30 track / 24 knob spec (the
/// existing `HabitSwitch` is sized 40×24 for its own feature and isn't
/// reachable from here as a `part of` file, so this is a local equivalent).
class _KeypointToggleSwitch extends StatelessWidget {
  const _KeypointToggleSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptic.select();
          onChanged(!value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 50.w,
          height: 30.h,
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: value ? AppCustomColor.brandPrimary : AppCustomColor.borderDefault,
            borderRadius: BorderRadius.circular(999.r),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 24.w,
              height: 24.w,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    );
  }
}
