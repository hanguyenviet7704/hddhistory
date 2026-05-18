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
    AppService.instance.appTrackingService.trackInAppSurveyEntryView(source: 'home');
  }

  Future<void> _openInAppSurveyDialog() async {
    if (_surveyDialogOpen || !mounted) return;

    final cubit = context.read<InAppSurveyCubit>();
    AppService.instance.appTrackingService.trackInAppSurveyEntryClick(source: 'home');
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
