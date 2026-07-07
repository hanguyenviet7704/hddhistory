part of '../../habit.dart';

/// 7-box weekly grid (Mon..Sun) — filled dot for a done day, empty for not
/// done, matching the Figma "Habit" tab weekly view.
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
          padding: EdgeInsets.only(right: index == 6 ? 0 : 6.w),
          child: Semantics(
            label: done ? 'Done' : 'Not done',
            child: Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                // Figma: done days are the deep streak purple, open days a soft
                // lavender — not gray.
                color: done ? AppCustomColor.streakActive : AppCustomColor.brandPrimary50,
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
          ),
        );
      }),
    );
  }
}
