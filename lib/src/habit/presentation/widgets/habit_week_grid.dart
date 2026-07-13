part of '../../habit.dart';

// Figma "Component45" unfilled-day tint (background/brand-2) — doesn't have
// its own app-wide token yet (mirrors edit_habit_sheet.dart's same literal).
const Color _kHabitWeekGridOpenDay = Color(0xFFE0DEFD);

/// 7-box weekly grid (Mon..Sun) — filled dot for a done day, empty for not
/// done, matching the Figma "Component45" weekly chip row.
class HabitWeekGrid extends StatelessWidget {
  final List<bool> weekGrid;

  const HabitWeekGrid({super.key, required this.weekGrid});

  @override
  Widget build(BuildContext context) {
    final days = weekGrid.length == 7 ? weekGrid : List<bool>.filled(7, false);
    return Row(
      children: List.generate(7, (index) {
        final done = days[index];
        return Padding(
          padding: EdgeInsets.only(right: index == 6 ? 0 : 4.w),
          child: Semantics(
            label: done ? 'Done' : 'Not done',
            child: Container(
              width: 16.w,
              height: 16.w,
              decoration: BoxDecoration(
                // Figma: done days are the deep streak purple, open days a soft
                // lavender — not gray.
                color: done ? AppCustomColor.streakActive : _kHabitWeekGridOpenDay,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
        );
      }),
    );
  }
}
