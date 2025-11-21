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
          padding: EdgeInsets.all(20.w),
          child: AppButton.primary(
            onPressed: () => _onPressed(context, state),
            fullWidthBtn: true,
            height: 54.h,
            decoration: BoxDecoration(
              color: state.canContinue
                  ? const Color(0xFF554FF0) // Brand/Primary
                  : const Color(0xFFE3E8EF), // Neutral/200
              borderRadius: BorderRadius.circular(1000.r),
            ),
            child: AppText(
              context.text.onboarding.onboardingSkipGreetingButton,
              style: AppStyle.textBold16.copyWith(
                color: state.canContinue
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
}
