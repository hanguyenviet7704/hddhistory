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
