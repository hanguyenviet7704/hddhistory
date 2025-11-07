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
    context.read<RoleplayCubit>().loadAllLearningItems();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppDI.injector.get<RoleplayCubit>()..loadAllLearningItems(isInit: true),
      child: BlocBuilder<RoleplayCubit, RoleplayState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Roleplay Learning Items'),
            ),
            body: _buildBody(context, state),
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
                context.read<RoleplayCubit>().loadAllLearningItems(isInit: true);
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
              'No learning items found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Show list with items
    return RefreshIndicator(
      onRefresh: () async {
        context.read<RoleplayCubit>().loadAllLearningItems(isInit: true);
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
          return _buildLearningItemTile(context, item);
        },
      ),
    );
  }

  Widget _buildLearningItemTile(BuildContext context, LearningItemEntity item) {
    return ExpansionTile(
      title: Text(item.title.text.isNotEmpty ? item.title.text : 'Untitled'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type: ${item.type.name}'),
          Text('ID: ${item.id}'),
          if (item.sections.isNotEmpty) 
            Text('Sections: ${item.sections.length}'),
        ],
      ),
      children: [
        if (item.sections.isNotEmpty)
          ...item.sections.map((section) => _buildSectionTile(section)),
        if (item.questions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Questions: ${item.questions.length}'),
          ),
        if (item.documents.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Documents: ${item.documents.length}'),
          ),
      ],
      onExpansionChanged: (expanded) {
        if (expanded) {
          // Load detailed item data if needed
          context.read<RoleplayCubit>().loadLearningItem(item.id);
        }
      },
    );
  }

  Widget _buildSectionTile(SectionEntity section) {
    return ListTile(
      leading: const Icon(Icons.play_circle_outline),
      title: Text(section.title),
      subtitle: Text('Contents: ${section.contents.length}'),
      contentPadding: const EdgeInsets.only(left: 32.0, right: 16.0),
      onTap: () {
        // TODO: Navigate to section detail or play section
        // This could open a roleplay dialog/page for this specific section
      },
    );
  }
}