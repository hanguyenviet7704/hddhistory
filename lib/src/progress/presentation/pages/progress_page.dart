part of '../../progress.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
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
    context.read<ProgressCubit>().loadAllUserProgresss();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppDI.injector.get<ProgressCubit>()..loadAllUserProgresss(isInit: true),
      child: BlocBuilder<ProgressCubit, ProgressState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Progress'),
            ),
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProgressState state) {
    // Show loading on initial load
    if (state.status == ProgressStatus.loading && state.pageData.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error if no items loaded yet
    if (state.status == ProgressStatus.failure && state.pageData.items.isEmpty) {
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
                context.read<ProgressCubit>().loadAllUserProgresss(isInit: true);
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
        context.read<ProgressCubit>().loadAllUserProgresss(isInit: true);
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
            title: Text('Course: ${item.courseId}'),
            subtitle: Text('User: ${item.userId} | Lessons: ${item.lessonsResult.length}'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Navigate to detail page to view progress details
            },
          );
        },
      ),
    );
  }
}
