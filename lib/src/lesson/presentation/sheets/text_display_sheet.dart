part of '../../lesson.dart';

/// "Text display" sheet (Size + Font), opened from the Read-mode "Text
/// display" card in [KeypointSettingsSheet]. Drives [KeypointDisplayCubit];
/// the theory reading content (not any chrome) consumes the result — see
/// [DocumentContentWidget].
class TextDisplaySheet extends StatefulWidget {
  const TextDisplaySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppCustomColor.scrimOverlay,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26.r))),
      builder: (_) => const TextDisplaySheet(),
    );
  }

  @override
  State<TextDisplaySheet> createState() => _TextDisplaySheetState();
}

/// Maps the reading font enum to the spec's short token (default/serif/courier).
String _readingFontToken(ReadingFontFamily f) => switch (f) {
      ReadingFontFamily.defaultFamily => 'default',
      ReadingFontFamily.serif => 'serif',
      ReadingFontFamily.courier => 'courier',
    };

class _TextDisplaySheetState extends State<TextDisplaySheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = context.read<KeypointDisplayCubit>().state;
      AppService.instance.appTrackingService.trackEvent(
        TrackingKey.menuTextdisplayScrView,
        parameters: {'font': _readingFontToken(s.fontFamily), 'size': s.displayFontSizePx},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      key: const ValueKey('text-display-sheet'),
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
          20.verticalSpace,
          Row(
            children: [
              Expanded(
                child: AppText(
                  context.l10n.lesson.textDisplayTitle,
                  style: AppStyle.textBold20.copyWith(color: const Color(0xFF171735)),
                ),
              ),
              GestureDetector(
                key: const ValueKey('text-display-sheet-close-button'),
                onTap: () {
                  AppHaptic.select();
                  AppService.instance.appTrackingService.trackEvent(TrackingKey.menuTextdisplayClose);
                  context.back();
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: const BoxDecoration(color: Color(0xFFF0F1F6), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Icon(Icons.close_rounded, size: 18.w, color: const Color(0xFF6B6B86)),
                ),
              ),
            ],
          ),
          24.verticalSpace,
          AppText(
            context.l10n.lesson.fontSizeLabel,
            style: AppStyle.text13.copyWith(color: const Color(0xFF8A94A6), fontWeight: FontWeight.w600),
          ),
          10.verticalSpace,
          BlocBuilder<KeypointDisplayCubit, KeypointDisplayState>(
            builder: (context, state) {
              final cubit = context.read<KeypointDisplayCubit>();
              return Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FB),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _FontSizeStepButton(
                      key: const ValueKey('text-display-sheet-decrease-size'),
                      label: 'A−',
                      enabled: state.canDecreaseFontScale,
                      onTap: () {
                        cubit.decreaseFontScale();
                        AppService.instance.appTrackingService.trackEvent(
                          TrackingKey.menuTextdisplaySizeClick,
                          parameters: {'direction': 'decrease', 'size': cubit.state.displayFontSizePx},
                        );
                      },
                    ),
                    AppText(
                      '${state.displayFontSizePx}',
                      key: const ValueKey('text-display-sheet-size-value'),
                      style: AppStyle.textBold16.copyWith(color: AppCustomColor.brandPrimary),
                    ),
                    _FontSizeStepButton(
                      key: const ValueKey('text-display-sheet-increase-size'),
                      label: 'A+',
                      enabled: state.canIncreaseFontScale,
                      onTap: () {
                        cubit.increaseFontScale();
                        AppService.instance.appTrackingService.trackEvent(
                          TrackingKey.menuTextdisplaySizeClick,
                          parameters: {'direction': 'increase', 'size': cubit.state.displayFontSizePx},
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          24.verticalSpace,
          AppText(
            context.l10n.lesson.fontFamilyLabel,
            style: AppStyle.text13.copyWith(color: const Color(0xFF8A94A6), fontWeight: FontWeight.w600),
          ),
          10.verticalSpace,
          BlocBuilder<KeypointDisplayCubit, KeypointDisplayState>(
            builder: (context, state) {
              final cubit = context.read<KeypointDisplayCubit>();
              return Row(
                children: [
                  Expanded(
                    child: _FontOptionButton(
                      key: const ValueKey('text-display-sheet-font-default'),
                      family: ReadingFontFamily.defaultFamily,
                      label: context.l10n.lesson.fontDefaultLabel,
                      isSelected: state.fontFamily == ReadingFontFamily.defaultFamily,
                      onTap: () {
                        cubit.setFontFamily(ReadingFontFamily.defaultFamily);
                        AppService.instance.appTrackingService.trackEvent(
                          TrackingKey.menuTextdisplayFontClick,
                          parameters: {'font': 'default'},
                        );
                      },
                    ),
                  ),
                  10.horizontalSpace,
                  Expanded(
                    child: _FontOptionButton(
                      key: const ValueKey('text-display-sheet-font-serif'),
                      family: ReadingFontFamily.serif,
                      label: context.l10n.lesson.fontSerifLabel,
                      isSelected: state.fontFamily == ReadingFontFamily.serif,
                      onTap: () {
                        cubit.setFontFamily(ReadingFontFamily.serif);
                        AppService.instance.appTrackingService.trackEvent(
                          TrackingKey.menuTextdisplayFontClick,
                          parameters: {'font': 'serif'},
                        );
                      },
                    ),
                  ),
                  10.horizontalSpace,
                  Expanded(
                    child: _FontOptionButton(
                      key: const ValueKey('text-display-sheet-font-courier'),
                      family: ReadingFontFamily.courier,
                      label: context.l10n.lesson.fontCourierLabel,
                      isSelected: state.fontFamily == ReadingFontFamily.courier,
                      onTap: () {
                        cubit.setFontFamily(ReadingFontFamily.courier);
                        AppService.instance.appTrackingService.trackEvent(
                          TrackingKey.menuTextdisplayFontClick,
                          parameters: {'font': 'courier'},
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FontSizeStepButton extends StatelessWidget {
  const _FontSizeStepButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled
            ? () {
                AppHaptic.select();
                onTap();
              }
            : null,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundWhite,
              border: Border.all(color: const Color(0xFFE6E9F2), width: 1.5),
              borderRadius: BorderRadius.circular(13.r),
            ),
            alignment: Alignment.center,
            child: AppText(
              label,
              style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _FontOptionButton extends StatelessWidget {
  const _FontOptionButton({
    super.key,
    required this.family,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final ReadingFontFamily family;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Reuse the family→(name, fallback) mapping the theory text uses so the
    // "Ag" preview renders in exactly the font this option applies.
    final preview = KeypointDisplayState(fontFamily: family);
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isSelected ? AppCustomColor.brandPrimary50 : AppCustomColor.backgroundWhite,
            border: Border.all(
              color: isSelected ? AppCustomColor.brandPrimary : const Color(0xFFE6E9F2),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                'Ag',
                style: AppStyle.text20.copyWith(
                  fontFamily: preview.fontFamilyName,
                  fontFamilyFallback: preview.fontFamilyFallback,
                  color: AppCustomColor.textPrimary,
                ),
              ),
              4.verticalSpace,
              AppText(
                label,
                maxLines: 1,
                style: AppStyle.text12.copyWith(color: AppCustomColor.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
