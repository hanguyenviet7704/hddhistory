part of '../../../data_collect.dart';

class ContinueButton extends StatelessWidget {
  const ContinueButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.all(20.w),
          child: AppButton.primary(
            onPressed: _canContinue(state)
                ? () {
                    // Navigate to summary page when completing data collection
                    if (state.currentStep == DataCollectStep.howMuchTimeYouWantToBecomeSkilled) {
                      DataCollectSummaryRoute().go(context);
                    } else {
                      context.read<DataCollectCubit>().goToNextStep();
                    }
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
          ),
        );
      },
    );
  }

  bool _canContinue(DataCollectState state) {
    switch (state.currentStep) {
      case DataCollectStep.name:
        return state.userName != null && state.userName!.isNotEmpty;
      case DataCollectStep.age:
        return state.selectedAgeRange != null;
      case DataCollectStep.gender:
        return state.selectedGender != null;
      case DataCollectStep.englishIsYourNativeLanguage:
        return state.isNativeEnglishSpeaker != null;
      case DataCollectStep.chooseTopic:
        return state.selectedTopics.isNotEmpty;
      case DataCollectStep.doesThisDescribeYou:
        return state.selectedThisDescribeYouOptions.isNotEmpty;
      case DataCollectStep.whatDoYouUsuallyStruggleWithWhenSpeaking:
        return state.selectedStruggles.isNotEmpty;
      case DataCollectStep.bestTimeOfDayToLearn:
        return state.selectedBestTimeToLearn != null;
      case DataCollectStep.dailyLearningGoal:
        return state.selectedDailyLearningGoal != null;
      case DataCollectStep.howMuchTimeYouWantToBecomeSkilled:
        return state.selectedTimeToBecomeSkilled != null;
    }
  }
}
