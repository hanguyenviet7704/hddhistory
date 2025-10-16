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
                padding: EdgeInsets.all(20.w),
                child: StepBody(),
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
      DataCollectStep.name => const NameCollectBody(),
      DataCollectStep.age => const AgeCollectBody(),
      DataCollectStep.gender => const GenderCollectBody(),
      DataCollectStep.englishIsYourNativeLanguage => const NativeLanguageBody(),
      DataCollectStep.chooseTopic => const ChooseTopicBody(),
      DataCollectStep.doesThisDescribeYou => const ThisDescribeYouBody(),
      DataCollectStep.whatDoYouUsuallyStruggleWithWhenSpeaking => const StruggleWhenSpeakingBody(),
      DataCollectStep.bestTimeOfDayToLearn => const BestTimeToLearnBody(),
      DataCollectStep.dailyLearningGoal => const LearningGoalBody(),
      DataCollectStep.howMuchTimeYouWantToBecomeSkilled => const BestTimeToSkilledBody(),
    };
  }
}
