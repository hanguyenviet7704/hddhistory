part of '../../lesson.dart';

/// Bottom sheet reachable from the keypoint header's overflow (⊞) menu
/// ([LessonHeaderMenu]). The unified keypoint screen has no Read/Listen mode
/// split anymore, so every control is always shown: one row of three equal
/// action cards (Change theme, Text display, Report a problem) plus a
/// Background music row underneath.
///
/// Narration speed is deliberately NOT here — it lives on the header's `1x`
/// pill next to play/pause, where the reader is already looking while
/// listening. Two entry points for one setting only invited them to disagree.
class KeypointSettingsSheet extends StatelessWidget {
  const KeypointSettingsSheet({
    super.key,
    required this.onReportProblem,
    required this.onOptionSelected,
  });

  final VoidCallback onReportProblem;

  /// Called when the user picks any action card (so `show` can tell an option
  /// tap apart from a swipe/scrim dismiss when logging keypoint_menu_close).
  final VoidCallback onOptionSelected;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onReportProblem,
  }) {
    var optionSelected = false;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppCustomColor.scrimOverlay,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26.r))),
      builder: (_) => KeypointSettingsSheet(
        onReportProblem: onReportProblem,
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
          18.verticalSpace,
          // Design: ONE row of three equal action cards, then the
          // background-music toggle row.
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
                10.horizontalSpace,
                Expanded(
                  child: _KeypointSettingsCard(
                    key: const ValueKey('keypoint-settings-text-display'),
                    iconAsset: AppAsset.svg.app.icTextDisplay,
                    label: context.l10n.lesson.textDisplayTitle,
                    onTap: () {
                      onOptionSelected();
                      context.back();
                      AppService.instance.appTrackingService.trackEvent(TrackingKey.keypointMenuTextdisplayClick);
                      TextDisplaySheet.show(context);
                    },
                  ),
                ),
                10.horizontalSpace,
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
          14.verticalSpace,
          const _BackgroundMusicRow(),
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
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FB),
            borderRadius: BorderRadius.circular(18.r),
          ),
          // Design stacks the icon above a centered label (three equal cards
          // in one row), rather than icon-beside-label.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconAsset,
                width: 28.w,
                height: 28.w,
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

/// Ambient background-audio toggle, always shown now (previously Listen-mode
/// only). Wired to [StudyThemeCubit]'s sound state — the study background's own
/// ambient sound layer already plays behind the lesson shell ([ThemedBackground]
/// wraps [LessonShellLayout]'s body), so "Background music" in the keypoint
/// sheet controls that same toggle rather than introducing a second,
/// competing audio layer.
///
/// Opening a keypoint silences that ambience so it doesn't talk over the
/// narration, which is why this reads [StudyThemeStateX.soundAudible] and not the
/// stored preference: inside a lesson the switch shows OFF, and flipping it on
/// here is the reader overriding that for the rest of the lesson.
class _BackgroundMusicRow extends StatelessWidget {
  const _BackgroundMusicRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudyThemeCubit, StudyThemeState>(
      builder: (context, state) {
        // Design renders this as a plain row on the sheet surface — no card
        // fill — so only the three action tiles read as tappable cards.
        return Padding(
          key: const ValueKey('keypoint-settings-background-music'),
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Row(
            children: [
              SvgPicture.asset(
                AppAsset.svg.app.icBackgroundMusic,
                width: 22.w,
                height: 22.w,
                colorFilter: const ColorFilter.mode(AppCustomColor.textSecondary, BlendMode.srcIn),
              ),
              14.horizontalSpace,
              Expanded(
                child: AppText(
                  context.l10n.lesson.backgroundMusicLabel,
                  style: AppStyle.textBold14.copyWith(color: AppCustomColor.textPrimary),
                ),
              ),
              _KeypointToggleSwitch(
                key: const ValueKey('keypoint-settings-background-music-toggle'),
                value: state.soundAudible,
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
