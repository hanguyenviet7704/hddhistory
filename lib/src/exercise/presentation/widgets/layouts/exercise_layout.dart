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
  final ExerciseLayoutType type;
  final List<Widget> children;
  final Widget? bottom;
  const ExerciseLayout({
    super.key,
    this.type = ExerciseLayoutType.practice,
    this.children = const [],
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ExerciseHeader(type: type),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: children,
                ),
              ),
            ),
            bottom ?? ExerciseContinueButton(onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
