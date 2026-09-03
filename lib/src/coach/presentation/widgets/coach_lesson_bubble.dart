part of '../../coach.dart';

/// ① — the Coach bubble at the end of a lesson.
///
/// A widget of its own rather than [CoachBubbleHost] because this page is a
/// SUB-ROUTE: the floating nav bar is hidden here, so there is no nav height to
/// clear, and the shell's host deliberately renders nothing outside Home and
/// Habit.
///
/// The guards live on the server — two commitments already waiting, or a Coach
/// that has already appeared for this lesson today, and `visible` simply comes
/// back false. Nothing here decides when to stay quiet.
class CoachLessonBubble extends StatelessWidget {
  final String lessonId;

  const CoachLessonBubble({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    if (lessonId.isEmpty) return const SizedBox.shrink();

    return BlocProvider<CoachBubbleCubit>(
      create: (_) => AppDI.injector.get<CoachBubbleCubit>()..refresh(entry: CoachEntry.lesson, lessonId: lessonId),
      child: Builder(
        builder: (context) => BlocBuilder<CoachBubbleCubit, CoachBubbleState>(
          builder: (context, state) {
            if (!state.resolved || !state.visible) return const SizedBox.shrink();

            return CoachBubble(
              // No nav bar on this route, so the device inset plus a gap is the
              // whole clearance — the same figure the import toast uses on a
              // sub-route.
              bottomInset: MediaQuery.paddingOf(context).bottom + 18.h,
              // Never a dot here. The dot means "a commitment is waiting" and
              // lives on Home alone; one at the end of a lesson would be
              // announcing something that has not happened yet.
              dot: false,
              onTap: () async {
                final courseId = await showCoachSheet(
                  context,
                  entry: CoachEntry.lesson,
                  lessonId: lessonId,
                );
                LogDev.data('[CoachDbg] lesson sheet closed: courseId=$courseId mounted=${context.mounted}'); // TEMP-DEBUG

                // Same contract as the Home bubble: the sheet hands back the
                // course the reader tapped, and navigation happens only AFTER
                // the modal is gone — never from under a closing modal. It goes
                // through the app-level context: the lesson surface under the
                // sheet may itself be gone by the time the modal closes, and
                // its dead element was silently eating the navigation.
                if (courseId != null) {
                  final navContext = AppConfig.instance.context ?? (context.mounted ? context : null);
                  if (navContext != null && navContext.mounted) {
                    AppDI.injector.get<DeeplinkCubit>().openCourseRoadmapFromCoach(navContext, courseId);
                  }
                }
                if (!context.mounted) return;

                await context.read<CoachBubbleCubit>().invalidate(entry: CoachEntry.lesson, lessonId: lessonId);
              },
            );
          },
        ),
      ),
    );
  }
}
