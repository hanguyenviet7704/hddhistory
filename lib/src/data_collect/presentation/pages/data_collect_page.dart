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
            ProgressBar(
              totalSteps: DataCollectStep.values.length,
            ),

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
      DataCollectStep.gender => _placeholderWidget('Gender'),
      DataCollectStep.englishIsYourNativeLanguage => _placeholderWidget('English Is Your Native Language'),
      DataCollectStep.chooseTopic => _placeholderWidget('Choose Topic'),
      DataCollectStep.doesThisDescribeYou => _placeholderWidget('Does This Describe You'),
      DataCollectStep.whatDoYouUsuallyStruggleWithWhenSpeaking => _placeholderWidget('What Do You Usually Struggle With When Speaking'),
      _ => _placeholderWidget('Step not implemented yet'),
    };
  }

  Widget _placeholderWidget(String title) {
    return Center(
      child: AppText(
        '$title step not implemented yet',
        style: AppStyle.text16,
      ),
    );
  }
}
