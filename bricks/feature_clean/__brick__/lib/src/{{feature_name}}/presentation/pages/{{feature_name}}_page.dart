part of '../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

class {{#pascalCase}}{{feature_name}}{{/pascalCase}}Page extends StatefulWidget {
  const {{#pascalCase}}{{feature_name}}{{/pascalCase}}Page({super.key});

  @override
  State<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Page> createState() => _{{#pascalCase}}{{feature_name}}{{/pascalCase}}PageState();
}

class _{{#pascalCase}}{{feature_name}}{{/pascalCase}}PageState extends State<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Page> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      {{#use_bloc}}_loadMore(context);{{/use_bloc}}{{^use_bloc}}_loadMore(context);{{/use_bloc}}
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _loadMore(BuildContext context) {
    {{#use_bloc}}context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc>().add(
      const {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.loadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(),
    );{{/use_bloc}}{{^use_bloc}}context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit>().loadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s();{{/use_bloc}}
  }

  @override
  Widget build(BuildContext context) {
    return {{#use_bloc}}BlocProvider(
      create: (context) => AppDI.injector.get<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc>()
        ..add(const {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.loadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(isInit: true)),
      child: BlocBuilder<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc, {{#pascalCase}}{{feature_name}}{{/pascalCase}}State>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('{{#titleCase}}{{feature_name}}{{/titleCase}}'),
            ),
            body: _buildBody(context, state),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                // TODO: Navigate to create page or show create dialog
                // Example:
                // context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc>().add(
                //   {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.create{{#pascalCase}}{{entity_name}}{{/pascalCase}}(entity),
                // );
              },
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );{{/use_bloc}}{{^use_bloc}}BlocProvider(
      create: (context) => AppDI.injector.get<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit>()
        ..loadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(isInit: true),
      child: BlocBuilder<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit, {{#pascalCase}}{{feature_name}}{{/pascalCase}}State>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('{{#titleCase}}{{feature_name}}{{/titleCase}}'),
            ),
            body: _buildBody(context, state),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                // TODO: Navigate to create page or show create dialog
                // Example:
                // context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit>().create{{#pascalCase}}{{entity_name}}{{/pascalCase}}(entity);
              },
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );{{/use_bloc}}
  }

  Widget _buildBody(BuildContext context, {{#pascalCase}}{{feature_name}}{{/pascalCase}}State state) {
    // Show loading on initial load
    if (state.status == {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading && state.pageData.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error if no items loaded yet
    if (state.status == {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.failure && state.pageData.items.isEmpty) {
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                {{#use_bloc}}context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc>().add(
                  const {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.loadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(isInit: true),
                );{{/use_bloc}}{{^use_bloc}}context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit>().loadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(isInit: true);{{/use_bloc}}
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show empty state
    if (state.pageData.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No items found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Show list with items
    return RefreshIndicator(
      onRefresh: () async {
        {{#use_bloc}}context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc>().add(
          const {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.loadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(isInit: true),
        );{{/use_bloc}}{{^use_bloc}}context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit>().loadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(isInit: true);{{/use_bloc}}
        // Wait for the request to complete
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.pageData.items.length + (state.pageData.isLastPage ? 0 : 1),
        itemBuilder: (context, index) {
          // Show loading indicator at bottom when loading more
          if (index >= state.pageData.items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final item = state.pageData.items[index];
          return ListTile(
            title: Text(item.name),
            subtitle: Text('Created: ${item.createdAt}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // TODO: Navigate to edit page or show edit dialog
                    // Example:
                    // {{#use_bloc}}context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc>().add(
                    //   {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.update{{#pascalCase}}{{entity_name}}{{/pascalCase}}(updatedEntity),
                    // );{{/use_bloc}}{{^use_bloc}}context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit>().update{{#pascalCase}}{{entity_name}}{{/pascalCase}}(updatedEntity);{{/use_bloc}}
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _showDeleteConfirmation(context, item);
                  },
                ),
              ],
            ),
            onTap: () {
              // TODO: Navigate to detail page
              // Example:
              // {{#use_bloc}}context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc>().add(
              //   {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.load{{#pascalCase}}{{entity_name}}{{/pascalCase}}(item.id),
              // );{{/use_bloc}}{{^use_bloc}}context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit>().load{{#pascalCase}}{{entity_name}}{{/pascalCase}}(item.id);{{/use_bloc}}
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              {{#use_bloc}}context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc>().add(
                {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}(item.id),
              );{{/use_bloc}}{{^use_bloc}}context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit>().delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}(item.id);{{/use_bloc}}
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
