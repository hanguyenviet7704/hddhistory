part of '../../onboard.dart';

class OnboardPage extends StatelessWidget {
  const OnboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppDI.injector.get<OnboardCubit>()
        ..loadAllOnboards(),
      child: BlocBuilder<OnboardCubit, OnboardState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Onboard'),
            ),
            body: _buildBody(state),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                // Add create item logic here
              },
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(OnboardState state) {
    switch (state.status) {
      case OnboardStatus.initial:
        return const Center(child: Text('No data'));
      case OnboardStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case OnboardStatus.failure:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                state.errorMessage ?? 'An error occurred',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      case OnboardStatus.success:
        if (state.items.isEmpty) {
          return const Center(child: Text('No items found'));
        }
        return ListView.builder(
          itemCount: state.items.length,
          itemBuilder: (context, index) {
            final item = state.items[index];
            return ListTile(
              title: Text(item.name),
              subtitle: Text('Created: ${item.createdAt}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  // Add delete logic here
                },
              ),
              onTap: () {
                // Add navigation or detail view logic here
              },
            );
          },
        );
    }
  }
}
