part of '../../../exercise.dart';

class ExerciseLayout extends StatelessWidget {
  final Widget body;
  final Widget? bottom;
  final LearningItemType type;
  const ExerciseLayout({
    super.key,
    required this.body,
    this.bottom,
    this.type = LearningItemType.exercise,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (type == LearningItemType.exercise) ExerciseProgressBar(),
            if (type == LearningItemType.theory) TheoryProgressBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    12.verticalSpace,
                    if (type == LearningItemType.exercise) ExerciseBadge(),
                    if (type == LearningItemType.theory) TheoryBadge(),
                    ChatInformationWidget(type: type),
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
