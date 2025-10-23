part of '../../exercise.dart';

class ExercisePage extends StatelessWidget {
  const ExercisePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ExerciseLayout(
      body: ChatInformationWidget(),
    );
  }
}
