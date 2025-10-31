part of '../../../lesson.dart';

class LessonLayout extends StatelessWidget {
  final Widget body;
  final Widget? bottom;
  const LessonLayout({
    super.key,
    required this.body,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BlocSelector<LessonCubit, LessonState, LearningItemType>(
              selector: (state) => state.currentLearningItem.type,
              builder: (context, state) {
                return switch (state) {
                  LearningItemType.exercise => ExerciseProgressBar(),
                  LearningItemType.theory => TheoryProgressBar(),
                };
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    12.verticalSpace,
                    LessonBadge(),
                    ChatInformationWidget(),
                    body,
                  ],
                ),
              ),
            ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}
