part of '../../lesson.dart';

/// Bottom sheet reachable from the keypoint header's overflow (⊞) menu
/// ([LessonHeaderMenu]). The unified keypoint screen has no Read/Listen mode
/// split anymore, so every control is always shown: a 2x2 grid of equal
/// action cards (Change theme, Text display, Speed, Report a problem) plus a
/// Background music row underneath — a real layout pass from the old
/// mode-branched single row of exactly 3 cards, not just removing an `if`
/// (see `narration_timing_estimator`/`keypoint_card_cubit` plan notes: a 4th
/// card crammed into one row read too cramped, especially in Vietnamese,
/// where every label runs longer).
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
          // Design: ONE row of three equal action cards, then reading speed
          // as an inline stepper row, then the background-music toggle row.
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
          const _ReadingSpeedRow(),
          10.verticalSpace,
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

/// Narration speed as an INLINE stepper row (design) — icon · label · a
/// pill-shaped −/value/+ control — instead of pushing the user into a separate
/// speed sheet. Backed by [KeypointDisplayCubit.readingSpeed], which persists
/// across sessions and is applied to the player by [LessonAudioCubit].
class _ReadingSpeedRow extends StatelessWidget {
  const _ReadingSpeedRow();

  static const _speeds = LessonAudioStateX.supportedSpeeds;

  @override
  Widget build(BuildContext context) {
    final speed = context.select((KeypointDisplayCubit cubit) => cubit.state.readingSpeed);
    final index = _speeds.indexOf(speed);
    final canSlower = index > 0;
    final canFaster = index >= 0 && index < _speeds.length - 1;

    return Padding(
      key: const ValueKey('keypoint-settings-reading-speed'),
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          SvgPicture.asset(
            AppAsset.svg.app.icPlaybackSpeed,
            width: 22.w,
            height: 22.w,
            colorFilter: const ColorFilter.mode(AppCustomColor.textSecondary, BlendMode.srcIn),
          ),
          14.horizontalSpace,
          Expanded(
            child: AppText(
              context.l10n.lesson.audioSpeedTitle,
              style: AppStyle.textBold14.copyWith(color: AppCustomColor.textPrimary),
            ),
          ),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FB),
              borderRadius: BorderRadius.circular(99.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SpeedStepButton(
                  key: const ValueKey('keypoint-settings-speed-slower'),
                  icon: Icons.remove_rounded,
                  isEnabled: canSlower,
                  onTap: () => _setSpeed(context, _speeds[index - 1]),
                ),
                SizedBox(
                  width: 44.w,
                  child: AppText(
                    // Same "1x / 1.25x" formatting the speed sheet already
                    // used, so the value reads identically wherever it shows.
                    _lessonAudioSpeedLabel(speed),
                    textAlign: TextAlign.center,
                    style: AppStyle.textBold14.copyWith(color: AppCustomColor.brandPrimary),
                  ),
                ),
                _SpeedStepButton(
                  key: const ValueKey('keypoint-settings-speed-faster'),
                  icon: Icons.add_rounded,
                  isEnabled: canFaster,
                  onTap: () => _setSpeed(context, _speeds[index + 1]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setSpeed(BuildContext context, double speed) {
    final trackingData = KeypointTrackingData.fromContext();
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackKeypointAudioSpeedSelect(trackingData, speed: speed);
    }
    context.read<KeypointDisplayCubit>().setReadingSpeed(speed);
  }
}

class _SpeedStepButton extends StatelessWidget {
  const _SpeedStepButton({super.key, required this.icon, required this.isEnabled, required this.onTap});

  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isEnabled
          ? () {
              AppHaptic.select();
              onTap();
            }
          : null,
      child: Container(
        width: 32.w,
        height: 32.w,
        decoration: const BoxDecoration(color: AppCustomColor.backgroundWhite, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18.sp,
          color: isEnabled ? AppCustomColor.textPrimary : AppCustomColor.borderDefault,
        ),
      ),
    );
  }
}

/// Ambient background-audio toggle, always shown now (previously Listen-mode
/// only). Wired to [StudyThemeCubit.soundOn] — the study background's own
/// ambient sound layer already plays behind the lesson shell ([ThemedBackground]
/// wraps [LessonShellLayout]'s body), so "Background music" in the keypoint
/// sheet controls that same toggle rather than introducing a second,
/// competing audio layer.
class _BackgroundMusicRow extends StatelessWidget {
  const _BackgroundMusicRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudyThemeCubit, StudyThemeState>(
      builder: (context, state) {
        // Design renders this (and the speed row above) as a plain row on the
        // sheet surface — no card fill — so only the three action tiles read
        // as tappable cards.
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
