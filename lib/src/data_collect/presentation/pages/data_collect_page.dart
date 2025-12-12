part of '../../data_collect.dart';

class DataCollectPage extends StatelessWidget {
  const DataCollectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            ProgressBar(),

            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: const StepBody(),
              ),
            ),

            // Bottom CTA Button
            const ContinueButton(),
          ],
        ),
      ),
    );
  }
}

class StepBody extends StatelessWidget {
  const StepBody({super.key});

  @override
  Widget build(BuildContext context) {
    final currentStep = context.select((DataCollectCubit cubit) => cubit.state.currentStep);
    return switch (currentStep) {
      DataCollectStep.collectName => const NameCollectBody(),
      DataCollectStep.collectAge => const AgeCollectBody(),
      DataCollectStep.collectGender => const GenderCollectBody(),
      DataCollectStep.collectLearningGoal => const LearningGoalBody(),
      DataCollectStep.collectSkillsetsWantToMaster => const SkillsetsWantToMasterBody(),
      DataCollectStep.collectLearningStrugger => const LearningStruggerBody(),
      DataCollectStep.motivateHowToLearn => const HowToLearnBody(),
      DataCollectStep.collectDailyLearningGoal => const DailyLearningGoalBody(),
      DataCollectStep.collectComfortableLearningTime => ComfortableLearningTimeBody(),
    };
  }
}
