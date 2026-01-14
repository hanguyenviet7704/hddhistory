part of '../../course.dart';

class CourseRoadmapPage extends StatefulWidget {
  const CourseRoadmapPage({super.key});

  @override
  State<CourseRoadmapPage> createState() => _CourseRoadmapPageState();
}

class _CourseRoadmapPageState extends State<CourseRoadmapPage> {
  bool _hasTrackedForVisibility = false;
  String _lastTrackedCourseId = '';

  void _trackRoadmapScrView() {
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    if (context.read<PageCubit>().state.currentRouteName != RouteNamed.courseRoadmap) return;
    final homeState = context.read<HomeCubit>().state;
    final roadmapState = context.read<CourseRoadmapCubit>().state;
    final courseId = roadmapState.roadmap.courseId;
    if (courseId.isEmpty) return;
    if (_hasTrackedForVisibility && _lastTrackedCourseId == courseId) return;
    final skillset = homeState.skillsets.resolveSkillsetByCourseId(
      courseId,
      fallback: homeState.currentSkillset,
    );
    final course = homeState.skillsets.resolveCourseByCourseId(
      courseId,
      fallback: homeState.currentCourse,
      skillsetFallback: homeState.currentSkillset,
    );

    AppService.instance.appTrackingService.trackRoadmapScrView(
      skillset: skillset,
      course: course,
      roadmapSource: roadmapState.roadmapSource,
    );
    _lastTrackedCourseId = courseId;
    _hasTrackedForVisibility = true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<PageCubit>().state.currentRouteName == RouteNamed.courseRoadmap) {
        _trackRoadmapScrView();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PageCubit, PageState>(
      listenWhen: (previous, current) => previous.currentRouteName != current.currentRouteName,
      listener: (context, state) {
        if (state.currentRouteName == RouteNamed.courseRoadmap) {
          _trackRoadmapScrView();
          return;
        }
        _hasTrackedForVisibility = false;
      },
      child: BlocListener<CourseRoadmapCubit, CourseRoadmapState>(
        listenWhen: (previous, current) => previous.roadmap.courseId != current.roadmap.courseId,
        listener: (context, state) {
          _hasTrackedForVisibility = false;
          _trackRoadmapScrView();
        },
        child: Scaffold(
          backgroundColor: AppCustomColor.backgroundGray,
          body: BlocSelector<CourseRoadmapCubit, CourseRoadmapState, bool>(
            selector: (state) => state.status == CourseRoadmapStatus.loading && state.roadmap.levels.isEmpty,
            builder: (context, isLoading) {
              if (isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppCustomColor.brandPrimary,
                  ),
                );
              }
              return SafeBody(
                child: Column(
                  children: [
                    TopProgressBar(),
                    CourseRoadmapContent(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
