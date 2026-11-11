part of '../../home.dart';

mixin _HomeInAppSurveyMixin on State<HomePage> {
  bool _surveyDialogOpen = false;
  bool _surveyEntryViewTracked = false;

  Future<void> _loadInAppSurveyConfig() async {
    final cubit = context.read<InAppSurveyCubit>();
    if (cubit.state.status == InAppSurveyStatus.loading || cubit.state.hasUsableConfig) return;
    await cubit.loadInAppSurveyConfig();
  }

  void _handleSurveyStateChanged(InAppSurveyState state) {
    if (!state.isEntryVisible) {
      _surveyEntryViewTracked = false;
      return;
    }

    if (_surveyEntryViewTracked) return;
    _surveyEntryViewTracked = true;
    // in_app_survey_entry_view tracking removed per request.
  }

  Future<void> _openInAppSurveyDialog() async {
    if (_surveyDialogOpen || !mounted) return;

    final cubit = context.read<InAppSurveyCubit>();

    // The home init may skip loading the survey config (e.g. when the paywall
    // or daily warm-up opens first). Ensure it's loaded on demand so tapping
    // the "Có góp ý?" entry always opens the popup.
    if (!cubit.state.hasUsableConfig) {
      await cubit.loadInAppSurveyConfig();
      if (!mounted) return;
    }

    // in_app_survey entry-click / inapp_survey_click tracking removed per request.
    cubit.openSurvey();
    if (cubit.state.step != InAppSurveyStep.rating) return;

    _surveyDialogOpen = true;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'In app survey',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => BlocProvider.value(
        value: cubit,
        child: const InAppSurveyDialog(),
      ),
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: .96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );

    _surveyDialogOpen = false;
    if (!mounted) return;
    if (cubit.state.step != InAppSurveyStep.entry && cubit.state.step != InAppSurveyStep.hidden) {
      cubit.closeSurvey();
    }
  }
}
