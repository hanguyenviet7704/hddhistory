part of '../../roadmap.dart';

class RoadmapPage extends StatefulWidget {
  const RoadmapPage({super.key});

  @override
  State<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends State<RoadmapPage> {
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
    context.read<RoadmapCubit>().loadAllRoadmaps();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppDI.injector.get<RoadmapCubit>()
        ..loadAllRoadmaps(isInit: true),
      child: BlocBuilder<RoadmapCubit, RoadmapState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Roadmap'),
            ),
            body: _buildBody(context, state),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                // TODO: Navigate to create page or show create dialog
                // Example:
                // context.read<RoadmapCubit>().createRoadmap(entity);
              },
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, RoadmapState state) {
    // Show loading on initial load
    if (state.status == RoadmapStatus.loading && state.pageData.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error if no items loaded yet
    if (state.status == RoadmapStatus.failure && state.pageData.items.isEmpty) {
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
                context.read<RoadmapCubit>().loadAllRoadmaps(isInit: true);
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
        context.read<RoadmapCubit>().loadAllRoadmaps(isInit: true);
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
            title: Text('Roadmap ${item.courseId}'),
            subtitle: Text('Created: ${item.createdAt}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // TODO: Navigate to edit page or show edit dialog
                    // Example:
                    // context.read<RoadmapCubit>().updateRoadmap(updatedEntity);
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
              // context.read<RoadmapCubit>().loadRoadmap(item.id);
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, RoadmapEntity item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "Roadmap ${item.courseId}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<RoadmapCubit>().deleteRoadmap(item.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
