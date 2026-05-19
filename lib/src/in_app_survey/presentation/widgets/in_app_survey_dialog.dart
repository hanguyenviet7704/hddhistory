part of '../../in_app_survey.dart';

class InAppSurveyDialog extends StatelessWidget {
  const InAppSurveyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<InAppSurveyCubit, InAppSurveyState>(
      listenWhen: (previous, current) => previous.isSubmitting && !current.isSubmitting && current.step == InAppSurveyStep.entry,
      listener: (context, state) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      },
      child: Material(
        color: Colors.transparent,
        child: PopScope(
          canPop: false,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              color: const Color(0x99121212),
              child: SafeArea(
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(
                    left: 0,
                    right: 0,
                    top: 12.h,
                    bottom: MediaQuery.viewInsetsOf(context).bottom + 12.h,
                  ),
                  child: BlocBuilder<InAppSurveyCubit, InAppSurveyState>(
                    builder: (context, state) => _DialogContent(state: state),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogContent extends StatelessWidget {
  const _DialogContent({required this.state});

  final InAppSurveyState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InAppSurveyCubit>();
    final branch = state.selectedBranch;

    return switch (state.step) {
      InAppSurveyStep.rating => InAppSurveyModalShell(
        onClose: () => _close(context),
        child: InAppSurveyRatingStep(
          config: state.config!,
          onSelectBranch: cubit.selectBranch,
        ),
      ),
      InAppSurveyStep.closedQuestion when branch != null => InAppSurveyModalShell(
        onClose: () => _close(context),
        bottom: _InAppSurveyPrimaryButton(
          text: context.l10n.common.kContinue,
          enabled: state.canContinueClosedQuestion,
          onPressed: cubit.continueToOpenFeedback,
        ),
        child: InAppSurveyClosedQuestionStep(
          branch: branch,
          selectedOptionIds: state.selectedOptionIds,
          onToggleOption: cubit.toggleOption,
        ),
      ),
      InAppSurveyStep.openFeedback when branch != null => InAppSurveyModalShell(
        onClose: () => _close(context),
        bottom: _InAppSurveyPrimaryButton(
          text: state.trimmedFeedback.isEmpty ? context.l10n.home.inAppSurveySendWithoutFeedback : context.l10n.home.inAppSurveySendFeedback,
          enabled: state.canSubmit,
          isLoading: state.isSubmitting,
          onPressed: () => cubit.submitSurveyResponse(),
        ),
        child: InAppSurveyOpenFeedbackStep(
          branch: branch,
          feedback: state.feedback,
          onFeedbackChanged: cubit.updateFeedback,
        ),
      ),
      _ => const SizedBox.shrink(),
    };
  }

  void _close(BuildContext context) {
    context.read<InAppSurveyCubit>().closeSurvey();
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }
}
