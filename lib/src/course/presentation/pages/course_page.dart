part of '../../course.dart';

class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    int skillsetCount = context.read<HomeCubit>().state.skillsets.length;
    _tabController = TabController(length: skillsetCount + 1, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      // Update CourseCubit when user swipes or taps tabs
      context.read<CourseCubit>().selectTab(_tabController.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CourseCubit, CourseState>(
      listenWhen: (previous, current) => previous.selectedTabIndex != current.selectedTabIndex,
      listener: (context, state) {
        if (_tabController.index != state.selectedTabIndex) {
          _tabController.animateTo(state.selectedTabIndex);
        }
      },
      child: Scaffold(
        backgroundColor: AppCustomColor.backgroundWhite,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              const CourseHeader(),
              // Tab bar
              CourseTabBar(tabController: _tabController),
              // Course list with TabBarView
              Expanded(
                child: CourseTabBarView(tabController: _tabController),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
