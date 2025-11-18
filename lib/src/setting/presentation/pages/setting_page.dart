part of '../../setting.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppDI.injector.get<SettingCubit>(),
      child: BlocBuilder<SettingCubit, SettingState>(
        builder: (context, state) => _buildScaffold(context, state),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, SettingState state) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setting detail'),
      ),
      body: _buildContent(context, state),
    );
  }

  Widget _buildContent(BuildContext context, SettingState state) {
    if (state.status == SettingStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configure your single-item UI.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            state.errorMessage ?? 'Use this screen for forms, detail cards, or any focused workflow.',
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              title: Text(state.selectedItem?.name ?? 'No item selected'),
              subtitle: Text('Tap the Load button to fetch data.'),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              // TODO: Provide an ID and trigger the load detail use case
              // context.read<SettingCubit>().loadSetting('sample-id');
            },
            child: const Text('Load item'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
