part of '../../../exercise.dart';

enum ExerciseLayoutType {
  knowledge,
  practice;

  String get title {
    switch (this) {
      case ExerciseLayoutType.knowledge:
        return 'Knowledge';
      case ExerciseLayoutType.practice:
        return 'Practice';
    }
  }

  String get icon {
    return switch (this) {
      ExerciseLayoutType.knowledge => AppAsset.svg.app.icAim,
      ExerciseLayoutType.practice => AppAsset.svg.app.icLayer,
    };
  }
}

class ExerciseLayout extends StatelessWidget {
  final Widget body;
  final Widget? bottom;

  const ExerciseLayout({
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
            ExerciseProgressBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    12.verticalSpace,
                    ExerciseBadge(),
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
