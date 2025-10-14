part of '../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

class {{#pascalCase}}{{feature_name}}{{/pascalCase}}Page extends StatelessWidget {
  const {{#pascalCase}}{{feature_name}}{{/pascalCase}}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return {{#use_bloc}}BlocProvider(
      create: (context) => AppDI.injector.get<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc>()
        ..add(const {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.loadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s()),
      child: BlocBuilder<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc, {{#pascalCase}}{{feature_name}}{{/pascalCase}}State>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('{{#titleCase}}{{feature_name}}{{/titleCase}}'),
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
    );{{/use_bloc}}{{^use_bloc}}BlocProvider(
      create: (context) => AppDI.injector.get<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit>()
        ..loadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(),
      child: BlocBuilder<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit, {{#pascalCase}}{{feature_name}}{{/pascalCase}}State>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('{{#titleCase}}{{feature_name}}{{/titleCase}}'),
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
    );{{/use_bloc}}
  }

  Widget _buildBody({{#pascalCase}}{{feature_name}}{{/pascalCase}}State state) {
    switch (state.status) {
      case {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.initial:
        return const Center(child: Text('No data'));
      case {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading:
        return const Center(child: CircularProgressIndicator());
      case {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.failure:
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
      case {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.success:
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
