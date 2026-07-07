part of '../../habit.dart';

/// Tracker empty state (PRD §9.5 FR5.6): habits are created from lessons, so a
/// user with none is nudged to browse courses (→ Explore), not to a picker.
class HabitEmptyState extends StatelessWidget {
  final VoidCallback onGoToCourse;

  const HabitEmptyState({super.key, required this.onGoToCourse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              context.l10n.habit.emptyStateTitle,
              textAlign: TextAlign.center,
              style: AppStyle.textBold16.copyWith(color: AppCustomColor.textPrimary),
            ),
            8.verticalSpace,
            AppText(
              context.l10n.habit.emptyStateSubtitle,
              textAlign: TextAlign.center,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary),
            ),
            20.verticalSpace,
            DButton(
              text: context.l10n.habit.emptyGoToCourseButton,
              onPressed: onGoToCourse,
            ),
          ],
        ),
      ),
    );
  }
}
