part of '../../onboard_branching.dart';







class OnboardBranchingPage extends StatelessWidget {
  const OnboardBranchingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppDI.injector.get<OnboardBranchingCubit>(),
      child: _BlankFeatureView(
        builder: (context) => BlocBuilder<OnboardBranchingCubit, OnboardBranchingState>(
          builder: (context, state) => _buildPlaceholder(context, state),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, OnboardBranchingState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.dashboard_customize, size: 56, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        const Text(
          'Blank canvas ready!',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Wire any domain logic through the injected Cubit or remove it if you want a pure UI screen.',
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
        title: const Text('Onboard Branching'),
      ),
      body: Center(child: builder(context)),
    );
  }
}




