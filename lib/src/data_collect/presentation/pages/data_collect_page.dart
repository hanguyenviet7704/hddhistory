part of '../../data_collect.dart';

class DataCollectPage extends StatelessWidget {
  const DataCollectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = AppDI.injector.get<DataCollectCubit>();
        // Initialize with the age step for testing
        cubit.goToStep(DataCollectStep.age);
        return cubit;
      },
      child: BlocBuilder<DataCollectCubit, DataCollectState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Column(
                children: [
                  // Progress Bar
                  ProgressBar(
                    currentStep: _getStepNumber(state.currentStep),
                    totalSteps: DataCollectStep.values.length,
                  ),

                  // Content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(20.w),
                      child: _getBodyForStep(state),
                    ),
                  ),

                  // Bottom CTA Button
                  Container(
                    padding: EdgeInsets.all(20.w),
                    child: BlocBuilder<DataCollectCubit, DataCollectState>(
                      builder: (context, state) {
                        return AppButton.primary(
                          onPressed: _canContinue(state)
                              ? () {
                                  context.read<DataCollectCubit>().goToNextStep();
                                }
                              : null,
                          fullWidthBtn: true,
                          height: 54.h,
                          decoration: BoxDecoration(
                            color: _canContinue(state)
                                ? const Color(0xFF554FF0) // Brand/Primary
                                : const Color(0xFFE3E8EF), // Neutral/200
                            borderRadius: BorderRadius.circular(1000.r),
                          ),
                          child: AppText(
                            'Continue',
                            style: AppStyle.textBold16.copyWith(
                              color: _canContinue(state)
                                  ? Colors
                                        .white // Text/White
                                  : const Color(0xFF7F8EA4), // Text/Tertiary
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _getStepNumber(DataCollectStep step) {
    return DataCollectStep.values.indexOf(step) + 1;
  }

  Widget _getBodyForStep(DataCollectState state) {
    switch (state.currentStep) {
      case DataCollectStep.name:
        return NameCollectBody(
          state: state,
          currentStep: _getStepNumber(state.currentStep),
        );
      case DataCollectStep.age:
        return AgeCollectBody(
          state: state,
          currentStep: _getStepNumber(state.currentStep),
        );
      case DataCollectStep.gender:
        // TODO: Implement GenderCollectBody
        return _placeholderWidget('Gender');
      case DataCollectStep.englishIsYourNativeLanguage:
        // TODO: Implement EnglishNativeLanguageCollectBody
        return _placeholderWidget('English Native Language');
      case DataCollectStep.chooseTopic:
        // TODO: Implement ChooseTopicCollectBody
        return _placeholderWidget('Choose Topic');
      case DataCollectStep.doesThisDescribeYou:
        // TODO: Implement DoesThisDescribeYouCollectBody
        return _placeholderWidget('Does This Describe You');
      case DataCollectStep.whatDoYouUsuallyStruggleWithWhenSpeaking:
        // TODO: Implement StruggleWhenSpeakingCollectBody
        return _placeholderWidget('Struggle When Speaking');
      case DataCollectStep.bestTimeOfDayToLearn:
        // TODO: Implement BestTimeToLearnCollectBody
        return _placeholderWidget('Best Time To Learn');
      case DataCollectStep.dailyLearningGoal:
        // TODO: Implement DailyLearningGoalCollectBody
        return _placeholderWidget('Daily Learning Goal');
      case DataCollectStep.howMuchTimeYouWantToBecomeSkilled:
        // TODO: Implement TimeToBecomeSkilledCollectBody
        return _placeholderWidget('Time To Become Skilled');
    }
  }

  Widget _placeholderWidget(String title) {
    return Center(
      child: AppText(
        '$title step not implemented yet',
        style: AppStyle.text16,
      ),
    );
  }

  bool _canContinue(DataCollectState state) {
    switch (state.currentStep) {
      case DataCollectStep.name:
        // TODO: Check if name is entered
        return false;
      case DataCollectStep.age:
        return state.selectedAgeRange != null;
      case DataCollectStep.gender:
        // TODO: Check if gender is selected
        return false;
      case DataCollectStep.englishIsYourNativeLanguage:
        // TODO: Check if answer is selected
        return false;
      case DataCollectStep.chooseTopic:
        // TODO: Check if topic is selected
        return false;
      case DataCollectStep.doesThisDescribeYou:
        // TODO: Check if option is selected
        return false;
      case DataCollectStep.whatDoYouUsuallyStruggleWithWhenSpeaking:
        // TODO: Check if struggle is selected
        return false;
      case DataCollectStep.bestTimeOfDayToLearn:
        // TODO: Check if time is selected
        return false;
      case DataCollectStep.dailyLearningGoal:
        // TODO: Check if goal is selected
        return false;
      case DataCollectStep.howMuchTimeYouWantToBecomeSkilled:
        // TODO: Check if time is selected
        return false;
    }
  }
}
