part of '../../../data_collect.dart';

class ContinueButton extends StatelessWidget {
  const ContinueButton({super.key});

  String _trackingLabelValue(OnboardOptionEntity? option) {
    return option?.trackingLabel ?? '';
  }

  List<String> _trackingLabelValues(List<OnboardOptionEntity> options) {
    return options.map((option) => option.trackingLabel).toList();
  }

  String _resolveUserName(DataCollectCubit cubit) {
    final stateName = cubit.state.userName?.trim() ?? '';
    if (stateName.isNotEmpty) return stateName;
    return cubit.nameController.text.trim();
  }

  void _onPressed(BuildContext context) {
    final cubit = context.read<DataCollectCubit>();
    final state = cubit.state;
    if (!state.canContinue) return;

    if (state.isLastStep) {
      AppService.instance.appTrackingService.trackObdLearningTimeContinue(
        _trackingLabelValue(state.selectedComfortableLearningTime),
      );
      cubit.startAnalysis();
      if (state.shouldSkipAnonymousLogin) {
        cubit.setShouldSkipAnonymousLogin(false);
      } else {
        cubit.loginAnonymous();
      }
      DataCollectMotivationStepRoute(step: 3).push(context); // Motivation 03
      return;
    }

    if (state.currentStep == DataCollectStep.collectName) {
      AppService.instance.appTrackingService.trackObdNameContinue();
      final flowConfig = AppService.instance.remoteConfigService.onboardingConfig;
      if (flowConfig.isDisabled) {
        AppDI.injector.get<UserCubit>().startFirstTimeRegisterFlow();
        const NotificationRequestRoute(showPaywallAfterAuth: true).go(context);
        return;
      }

      if (flowConfig.isBranching && !state.shouldSkipBranchingFlow) {
        OnboardBranchingRoute(userName: _resolveUserName(cubit)).go(context);
        return;
      }

      DataCollectMotivationStepRoute(step: 0).push(context); // Welcome
      return;
    }

    if (state.currentStep == DataCollectStep.collectSkillsetsWantToMaster) {
      AppService.instance.appTrackingService.trackObdSkillsetContinue(
        _trackingLabelValues(state.selectedSkillsetsWantToMaster),
      );
      DataCollectMotivationStepRoute(step: 1).push(context); // Motivation 01
      return;
    }

    if (state.currentStep == DataCollectStep.collectLearningStrugger) {
      AppService.instance.appTrackingService.trackObdStrugglesContinue(
        _trackingLabelValues(state.selectedLearningStruggles),
      );
      DataCollectMotivationStepRoute(step: 2).push(context); // Motivation 02
      return;
    }

    if (state.currentStep == DataCollectStep.motivateHowToLearn) {
      AppService.instance.appTrackingService.trackObdHowToLearnContinue();
      DataCollectFeedbackRoute().push(context);
      return;
    }

    if (state.currentStep == DataCollectStep.collectAge) {
      AppService.instance.appTrackingService.trackObdAgeContinue(
        _trackingLabelValue(state.selectedAgeRange),
      );
    } else if (state.currentStep == DataCollectStep.collectGender) {
      AppService.instance.appTrackingService.trackObdGenderContinue(
        _trackingLabelValue(state.selectedGender),
      );
    } else if (state.currentStep == DataCollectStep.collectLearningGoal) {
      AppService.instance.appTrackingService.trackObdLearningGoalContinue(
        _trackingLabelValue(state.selectedLearningGoal),
      );
    } else if (state.currentStep == DataCollectStep.collectDailyLearningGoal) {
      AppService.instance.appTrackingService.trackObdDailyTimeContinue(
        _trackingLabelValue(state.selectedDailyLearningGoal),
      );
    }

    context.read<DataCollectCubit>().goToNextStep();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DataCollectCubit, DataCollectState, bool>(
      selector: (state) => state.canContinue,
      builder: (context, canContinue) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          width: double.infinity,
          height: 54.h,
          decoration: BoxDecoration(
            color: canContinue ? const Color(0xFF554FF0) : const Color(0xFFE3E8EF),
            borderRadius: BorderRadius.circular(1000.r),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onPressed(context),
              borderRadius: BorderRadius.circular(1000.r),
              child: Center(
                child: AppText(
                  context.l10n.onboarding.onboardingSkipGreetingButton,
                  style: AppStyle.text16.copyWith(
                    fontWeight: FontWeight.w600,
                    color: canContinue ? Colors.white : const Color(0xFF7F8EA4),
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
