part of '../../in_app_survey.dart';

class InAppSurveyPage extends StatelessWidget {
  const InAppSurveyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppDI.injector.get<InAppSurveyCubit>(),
      child: _BlankFeatureView(
        builder: (context) => BlocBuilder<InAppSurveyCubit, InAppSurveyState>(
          builder: (context, state) => _buildPlaceholder(context, state),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, InAppSurveyState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.dashboard_customize, size: 56, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          context.l10n.home.inAppSurveyPlaceholderTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.home.inAppSurveyPlaceholderDescription,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _BlankFeatureView extends StatelessWidget {
  const _BlankFeatureView({required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.home.inAppSurveyPageTitle),
      ),
      body: Center(child: builder(context)),
    );
  }
}
