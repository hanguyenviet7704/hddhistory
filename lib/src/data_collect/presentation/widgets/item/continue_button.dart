part of '../../../data_collect.dart';

class ContinueButton extends StatelessWidget {
  const ContinueButton({super.key});

  void _onPressed(BuildContext context, DataCollectState state) {
    if (!state.canContinue) return;

    if (state.isLastStep) {
      context.read<DataCollectCubit>()
        ..startAnalysis()
        ..loginAnonymous();
      DataCollectSummaryRoute().go(context);
      return;
    }

    if (state.currentStep == DataCollectStep.collectName) {
      DataCollectMotivationStepRoute(step: 0).push(context); // Welcome
      return;
    }

    if (state.currentStep == DataCollectStep.collectSkillsetsWantToMaster) {
      DataCollectMotivationStepRoute(step: 1).push(context); // Motivation 01
      return;
    }

    if (state.currentStep == DataCollectStep.collectLearningStrugger) {
      DataCollectMotivationStepRoute(step: 2).push(context); // Motivation 02
      return;
    }

    if (state.currentStep == DataCollectStep.collectComfortableLearningTime) {
      DataCollectMotivationStepRoute(step: 3).push(context); // Motivation 03
      return;
    }

    context.read<DataCollectCubit>().goToNextStep();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DataCollectCubit, DataCollectState>(
      buildWhen: (previous, current) => previous.canContinue != current.canContinue || previous.currentStep != current.currentStep,
      builder: (context, state) {
        return Container(
          margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
          width: double.infinity,
          height: 54.h,
          decoration: BoxDecoration(
            color: state.canContinue ? const Color(0xFF554FF0) : const Color(0xFFE3E8EF),
            borderRadius: BorderRadius.circular(1000.r),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onPressed(context, state),
              borderRadius: BorderRadius.circular(1000.r),
              child: Center(
                child: AppText(
                  context.text.onboarding.onboardingSkipGreetingButton,
                  style: AppStyle.text16.copyWith(
                    fontWeight: FontWeight.w600,
                    color: state.canContinue ? Colors.white : const Color(0xFF7F8EA4),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
