part of '../../course.dart';

class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
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
    context.read<CourseCubit>().loadAllCourses();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppDI.injector.get<CourseCubit>()
        ..loadAllCourses(isInit: true),
      child: BlocBuilder<CourseCubit, CourseState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Course'),
            ),
            body: _buildBody(context, state),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                // TODO: Navigate to create page or show create dialog
                // Example:
                // context.read<CourseCubit>().createCourse(entity);
              },
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, CourseState state) {
    // Show loading on initial load
    if (state.status == CourseStatus.loading && state.pageData.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error if no items loaded yet
    if (state.status == CourseStatus.failure && state.pageData.items.isEmpty) {
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
                context.read<CourseCubit>().loadAllCourses(isInit: true);
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

    return SizedBox.shrink();
  }
}
