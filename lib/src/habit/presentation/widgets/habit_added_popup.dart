part of '../../habit.dart';

/// Success popup shown right after adopting ("Habit added!", design.md 5.2) or
/// upgrading ("Habit upgraded!", flowchart) a habit. "Go to Habit" routes to
/// the Habit tab (pops `true`); "Continue" just dismisses (pops `false`) and
/// lets the caller keep going (e.g. resume the lesson flow).
class HabitAddedPopup extends StatelessWidget {
  final String title;
  final String subtitle;

  const HabitAddedPopup({super.key, required this.title, required this.subtitle});

  static Future<bool?> show(BuildContext context, {String? title, String? subtitle}) {
    final resolvedTitle = title ?? context.l10n.habit.adoptAddedTitle;
    final resolvedSubtitle = subtitle ?? context.l10n.habit.adoptAddedSubtitle;
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'habitAddedPopup',
      barrierColor: AppCustomColor.scrimOverlay,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, _) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            child: HabitAddedPopup(title: resolvedTitle, subtitle: resolvedSubtitle),
          ),
        );
      },
    );
  }

  /// Convenience for the post-upgrade success popup (flowchart "Habit upgraded!").
  static Future<bool?> showUpgraded(BuildContext context) => show(
        context,
        title: context.l10n.habit.upgradedTitle,
        subtitle: context.l10n.habit.upgradedSubtitle,
      );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 24.w),
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundWhite,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText('🌱', style: AppStyle.text40),
                16.verticalSpace,
                AppText(
                  title,
                  textAlign: TextAlign.center,
                  style: AppStyle.textBold20.copyWith(color: AppCustomColor.textPrimary),
                ),
                8.verticalSpace,
                AppText(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary),
                ),
                24.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: DButton(
                        text: context.l10n.habit.adoptGoToHabitButton,
                        buttonType: DButtonType.outline,
                        textColor: AppCustomColor.brandPrimary,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: DButton(
                        text: context.l10n.common.kContinue,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
