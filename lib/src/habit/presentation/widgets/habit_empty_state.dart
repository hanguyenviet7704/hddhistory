part of '../../habit.dart';

// Figma 11418:15157 "image 794 [Vectorized]" — pulled from the design file.
const String _kHabitEmptyIllustration = 'assets/svg/common/habit_empty_illustration.svg';

/// Tracker empty state (PRD §9.5 FR5.6): habits are created from lessons, so a
/// user with none is nudged to browse courses (→ Explore), not to a picker.
class HabitEmptyState extends StatelessWidget {
  final VoidCallback onGoToCourse;

  const HabitEmptyState({super.key, required this.onGoToCourse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(_kHabitEmptyIllustration, width: 176.w, height: 109.h),
            8.verticalSpace,
            AppText(
              context.l10n.habit.emptyStateTitle,
              textAlign: TextAlign.center,
              style: AppStyle.textBold24.copyWith(color: AppCustomColor.textPrimary),
            ),
            8.verticalSpace,
            AppText(
              context.l10n.habit.emptyStateSubtitle,
              textAlign: TextAlign.center,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
            ),
            24.verticalSpace,
            // Figma: a compact pill sized to its label (36px h-padding, 54px
            // tall) — unlike the other CTAs here, it does NOT stretch full-width.
            DButton(
              text: context.l10n.habit.emptyGoToCourseButton,
              backgroundColor: AppCustomColor.brandPrimary,
              size: Size(0, 54.h),
              padding: EdgeInsets.symmetric(horizontal: 36.w),
              style: AppStyle.text16.copyWith(color: AppCustomColor.textWhite, fontWeight: FontWeight.w600),
              onPressed: onGoToCourse,
            ),
          ],
        ),
      ),
    );
  }
}
