part of '../../course.dart';

class CoursePage extends StatefulWidget {
  final int? selectedTabIndex;
  const CoursePage({super.key, this.selectedTabIndex});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _initializeTabController();
  }

  void _initializeTabController() {
    HomeState homeState = context.read<HomeCubit>().state;
    int skillsetCount = homeState.skillsets.length;
    int selectedTabIndex = widget.selectedTabIndex ?? homeState.selectedSkillsetIndex;
    _tabController = TabController(length: skillsetCount + 1, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _tabController.animateTo(selectedTabIndex + 1);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
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
