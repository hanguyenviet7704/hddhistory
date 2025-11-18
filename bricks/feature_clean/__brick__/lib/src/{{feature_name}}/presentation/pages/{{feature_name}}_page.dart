part of '../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

{{#include_state_management}}
{{#is_paged_list}}
{{#has_list}}
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
        builder: (context, state) => _buildScaffold(context, state),
      ),
    );{{/use_bloc}}{{^use_bloc}}BlocProvider(
      create: (context) => AppDI.injector.get<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit>()
        ..loadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(isInit: true),
      child: BlocBuilder<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit, {{#pascalCase}}{{feature_name}}{{/pascalCase}}State>(
        builder: (context, state) => _buildScaffold(context, state),
      ),
    );{{/use_bloc}}
  }

  Widget _buildScaffold(BuildContext context, {{#pascalCase}}{{feature_name}}{{/pascalCase}}State state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{{#titleCase}}{{feature_name}}{{/titleCase}}'),
      ),
      body: _buildBody(context, state),
      floatingActionButton: {{#has_create}}FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create page or show create dialog
          // Example:
          // {{#use_bloc}}context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc>().add(
          //   {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.create{{#pascalCase}}{{entity_name}}{{/pascalCase}}(entity),
          // );{{/use_bloc}}{{^use_bloc}}context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit>().create{{#pascalCase}}{{entity_name}}{{/pascalCase}}(entity);{{/use_bloc}}
        },
        child: const Icon(Icons.add),
      ){{/has_create}}{{^has_create}}null{{/has_create}},
    );
  }

  Widget _buildBody(BuildContext context, {{#pascalCase}}{{feature_name}}{{/pascalCase}}State state) {
    if (state.status == {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading && state.pageData.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

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

    return RefreshIndicator(
      onRefresh: () async {
        {{#use_bloc}}context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc>().add(
          const {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.loadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(isInit: true),
        );{{/use_bloc}}{{^use_bloc}}context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit>().loadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(isInit: true);{{/use_bloc}}
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.pageData.items.length + (state.pageData.isLastPage ? 0 : 1),
        itemBuilder: (context, index) {
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
            trailing: {{#has_item_actions}}Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                {{#has_update}}IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // TODO: Navigate to edit page or show edit dialog
                    // Example:
                    // {{#use_bloc}}context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc>().add(
                    //   {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.update{{#pascalCase}}{{entity_name}}{{/pascalCase}}(updatedEntity),
                    // );{{/use_bloc}}{{^use_bloc}}context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit>().update{{#pascalCase}}{{entity_name}}{{/pascalCase}}(updatedEntity);{{/use_bloc}}
                  },
                ),{{/has_update}}
                {{#has_delete}}IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _showDeleteConfirmation(context, item),
                ),{{/has_delete}}
              ],
            ){{/has_item_actions}}{{^has_item_actions}}null{{/has_item_actions}},
            onTap: {{#has_detail}}() {
              // TODO: Navigate to detail page or load detail inline
              // {{#use_bloc}}context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc>().add(
              //   {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.load{{#pascalCase}}{{entity_name}}{{/pascalCase}}(item.id),
              // );{{/use_bloc}}{{^use_bloc}}context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit>().load{{#pascalCase}}{{entity_name}}{{/pascalCase}}(item.id);{{/use_bloc}}
            }{{/has_detail}}{{^has_detail}}null{{/has_detail}},
          );
        },
      ),
    );
  }

  {{#has_delete}}void _showDeleteConfirmation(BuildContext context, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity item) {
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
  {{/has_delete}}
}
{{/has_list}}
{{#no_list}}
class {{#pascalCase}}{{feature_name}}{{/pascalCase}}Page extends StatelessWidget {
  const {{#pascalCase}}{{feature_name}}{{/pascalCase}}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{{#titleCase}}{{feature_name}}{{/titleCase}}'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'The paged_list presentation profile requires the list operation. Update the CRUD selection or switch to another profile.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
{{/no_list}}
{{/is_paged_list}}

{{#is_single_item}}
class {{#pascalCase}}{{feature_name}}{{/pascalCase}}Page extends StatelessWidget {
  const {{#pascalCase}}{{feature_name}}{{/pascalCase}}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return {{#use_bloc}}BlocProvider(
      create: (context) => AppDI.injector.get<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc>(),
      child: BlocBuilder<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc, {{#pascalCase}}{{feature_name}}{{/pascalCase}}State>(
        builder: (context, state) => _buildScaffold(context, state),
      ),
    );{{/use_bloc}}{{^use_bloc}}BlocProvider(
      create: (context) => AppDI.injector.get<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit>(),
      child: BlocBuilder<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit, {{#pascalCase}}{{feature_name}}{{/pascalCase}}State>(
        builder: (context, state) => _buildScaffold(context, state),
      ),
    );{{/use_bloc}}
  }

  Widget _buildScaffold(BuildContext context, {{#pascalCase}}{{feature_name}}{{/pascalCase}}State state) {
    return Scaffold(
      appBar: AppBar(
        title: Text('{{#titleCase}}{{feature_name}}{{/titleCase}} detail'),
      ),
      body: _buildContent(context, state),
    );
  }

  Widget _buildContent(BuildContext context, {{#pascalCase}}{{feature_name}}{{/pascalCase}}State state) {
    if (state.status == {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.loading) {
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
          {{#has_detail}}Card(
            child: ListTile(
              title: Text(state.selectedItem?.name ?? 'No item selected'),
              subtitle: Text('Tap the Load button to fetch data.'),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              // TODO: Provide an ID and trigger the load detail use case
              // {{#use_bloc}}context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc>().add(
              //   const {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.load{{#pascalCase}}{{entity_name}}{{/pascalCase}}('sample-id'),
              // );{{/use_bloc}}{{^use_bloc}}context.read<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit>().load{{#pascalCase}}{{entity_name}}{{/pascalCase}}('sample-id');{{/use_bloc}}
            },
            child: const Text('Load item'),
          ),
          const SizedBox(height: 24),
          {{/has_detail}}{{#has_create}}FilledButton(
            onPressed: () {
              // TODO: open create form, then call create use case
            },
            child: const Text('Create'),
          ),
          const SizedBox(height: 12),
          {{/has_create}}{{#has_update}}OutlinedButton(
            onPressed: () {
              // TODO: provide updated entity and call update use case
            },
            child: const Text('Update'),
          ),
          const SizedBox(height: 12),
          {{/has_update}}{{#has_delete}}OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              // TODO: supply ID and trigger delete use case
            },
            child: const Text('Delete'),
          ),
          {{/has_delete}}
        ],
      ),
    );
  }
}
{{/is_single_item}}

{{#is_blank_screen}}
class {{#pascalCase}}{{feature_name}}{{/pascalCase}}Page extends StatelessWidget {
  const {{#pascalCase}}{{feature_name}}{{/pascalCase}}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return {{#use_bloc}}BlocProvider(
      create: (context) => AppDI.injector.get<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc>(),
      child: _BlankFeatureView(
        builder: (context) => BlocBuilder<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Bloc, {{#pascalCase}}{{feature_name}}{{/pascalCase}}State>(
          builder: (context, state) => _buildPlaceholder(context, state),
        ),
      ),
    );{{/use_bloc}}{{^use_bloc}}BlocProvider(
      create: (context) => AppDI.injector.get<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit>(),
      child: _BlankFeatureView(
        builder: (context) => BlocBuilder<{{#pascalCase}}{{feature_name}}{{/pascalCase}}Cubit, {{#pascalCase}}{{feature_name}}{{/pascalCase}}State>(
          builder: (context, state) => _buildPlaceholder(context, state),
        ),
      ),
    );{{/use_bloc}}
  }

  Widget _buildPlaceholder(BuildContext context, {{#pascalCase}}{{feature_name}}{{/pascalCase}}State state) {
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
          'Wire any domain logic through the injected {{#use_bloc}}Bloc{{/use_bloc}}{{^use_bloc}}Cubit{{/use_bloc}} or remove it if you want a pure UI screen.',
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
        title: const Text('{{#titleCase}}{{feature_name}}{{/titleCase}}'),
      ),
      body: Center(child: builder(context)),
    );
  }
}
{{/is_blank_screen}}
{{/include_state_management}}

{{^include_state_management}}
class {{#pascalCase}}{{feature_name}}{{/pascalCase}}Page extends StatelessWidget {
  const {{#pascalCase}}{{feature_name}}{{/pascalCase}}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{{#titleCase}}{{feature_name}}{{/titleCase}}'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Presentation-only profile: add your widgets here and pull any dependencies manually when you are ready for domain/data layers.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
{{/include_state_management}}
