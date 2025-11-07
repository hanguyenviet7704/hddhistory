part of '../../roleplay.dart';

class RoleplayPage extends StatefulWidget {
  const RoleplayPage({super.key});

  @override
  State<RoleplayPage> createState() => _RoleplayPageState();
}

class _RoleplayPageState extends State<RoleplayPage> {
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
      _loadMore(context);
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _loadMore(BuildContext context) {
    context.read<RoleplayBloc>().add(
      const RoleplayEvent.loadAllSections(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppDI.injector.get<RoleplayBloc>()..add(const RoleplayEvent.loadAllSections(isInit: true)),
      child: BlocBuilder<RoleplayBloc, RoleplayState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Roleplay'),
            ),
            body: _buildBody(context, state),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                // TODO: Navigate to create page or show create dialog
                // Example:
                // context.read<RoleplayBloc>().add(
                //   RoleplayEvent.createSection(entity),
                // );
              },
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, RoleplayState state) {
    // Show loading on initial load
    if (state.status == RoleplayStatus.loading && state.pageData.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error if no items loaded yet
    if (state.status == RoleplayStatus.failure && state.pageData.items.isEmpty) {
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
                context.read<RoleplayBloc>().add(
                  const RoleplayEvent.loadAllSections(isInit: true),
                );
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
        context.read<RoleplayBloc>().add(
          const RoleplayEvent.loadAllSections(isInit: true),
        );
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
            title: Text(item.title),
            subtitle: Text('ID: ${item.id}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // TODO: Navigate to edit page or show edit dialog
                    // Example:
                    // context.read<RoleplayBloc>().add(
                    //   RoleplayEvent.updateSection(updatedEntity),
                    // );
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
              // context.read<RoleplayBloc>().add(
              //   RoleplayEvent.loadSection(item.id),
              // );
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, SectionEntity item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<RoleplayBloc>().add(
                RoleplayEvent.deleteSection(item.id),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
