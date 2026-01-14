part of '../../course.dart';

class CoursePage extends StatefulWidget {
  final int? selectedTabIndex;
  const CoursePage({super.key, this.selectedTabIndex});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  late final int _initialCategoryIndex;

  @override
  void initState() {
    super.initState();
    _initializeSelection();
  }

  void _initializeSelection() {
    HomeState homeState = context.read<HomeCubit>().state;
    _initialCategoryIndex = widget.selectedTabIndex ?? homeState.selectedSkillsetIndex;
    context.read<CourseCubit>().selectTab(1);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            const CourseHeader(),
            Expanded(
              child: BlocBuilder<CourseCubit, CourseState>(
                buildWhen: (previous, current) => previous.selectedTabIndex != current.selectedTabIndex,
                builder: (context, state) {
                  final selectedIndex = state.selectedTabIndex == 1 ? 1 : 0;
                  return IndexedStack(
                    index: selectedIndex,
                    children: [
                      const MyCourseTab(),
                      AllCourseTab(
                        initialCategoryIndex: _initialCategoryIndex,
                        isVisible: selectedIndex == 1,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
