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

    if (state.currentStep == DataCollectStep.whatDoYouUsuallyStruggleWithWhenSpeaking) {
      context.read<DataCollectCubit>().goToNextStep();
      DataCollectMotivationStepRoute().push(context);
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
