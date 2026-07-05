part of '../routes.dart';

//* Shell routes - Course
class CourseShellBranchData extends StatefulShellBranchData {
  const CourseShellBranchData();
  // static final GlobalKey<NavigatorState> $navigatorKey = AppConfig.rootNaviKey;
  static final List<NavigatorObserver> $observers = [AppConfig.instance.courseRouterObserver];
}

//* Shell routes - Explore (course grid). Its own branch so the "Khám phá" tab
//* shows the explore grid (CoursePage) independently of the "Khoá học" roadmap.
class ExploreShellBranchData extends StatefulShellBranchData {
  const ExploreShellBranchData();
  static final List<NavigatorObserver> $observers = [AppConfig.instance.exploreRouterObserver];
}

//* Course Route — registered inside the Course shell branch (see routes_shell.dart)
//* so CoursePage renders within the shell and keeps the bottom navigation bar.
class CourseRoute extends BaseTransitionRouteData with $CourseRoute {
  final int? selectedTabIndex;
  const CourseRoute({this.selectedTabIndex});

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<HomeCubit>()),
      BlocProvider.value(value: AppDI.injector.get<CourseCubit>()),
      BlocProvider.value(value: AppDI.injector.get<ProgressCubit>()),
      BlocProvider.value(value: AppDI.injector.get<CourseRoadmapCubit>()),
      BlocProvider.value(value: AppDI.injector.get<UserCubit>()),
      BlocProvider.value(value: AppDI.injector.get<ProfileCubit>()),
      BlocProvider.value(value: AppDI.injector.get<IapCubit>()),
    ],
    child: CoursePage(selectedTabIndex: selectedTabIndex),
  );
}

class ChangeCourseRoute extends BaseTransitionRouteData with $ChangeCourseRoute {
  const ChangeCourseRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<HomeCubit>()),
      BlocProvider.value(value: AppDI.injector.get<CourseRoadmapCubit>()),
    ],
    child: const ChangeCoursePage(),
  );
}

class SkillsetCoursesRoute extends BaseTransitionRouteData with $SkillsetCoursesRoute {
  const SkillsetCoursesRoute({required this.skillsetId});

  final String skillsetId;

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.slideFromRight;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<HomeCubit>()),
      BlocProvider.value(value: AppDI.injector.get<ProgressCubit>()),
      BlocProvider.value(value: AppDI.injector.get<CourseRoadmapCubit>()),
      BlocProvider.value(value: AppDI.injector.get<CourseLessonCubit>()),
      BlocProvider.value(value: AppDI.injector.get<PageCubit>()),
    ],
    child: SkillsetCoursesPage(skillsetId: skillsetId),
  );
}

class CourseRoadmapRoute extends BaseTransitionRouteData with $CourseRoadmapRoute {
  const CourseRoadmapRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<CourseRoadmapCubit>()),
      BlocProvider.value(value: AppDI.injector.get<CourseLessonCubit>()),
      BlocProvider.value(value: AppDI.injector.get<ProgressCubit>()),
      BlocProvider.value(value: AppDI.injector.get<HomeCubit>()),
      BlocProvider.value(value: AppDI.injector.get<ProfileCubit>()),
      BlocProvider.value(value: AppDI.injector.get<RoleplayPointCubit>()),
      BlocProvider.value(value: AppDI.injector.get<FeedbackCubit>()),
      BlocProvider.value(value: AppDI.injector.get<PageCubit>()),
      BlocProvider.value(value: AppDI.injector.get<WarmUpCubit>()),
    ],
    child: const CourseRoadmapPage(),
  );
}

/// The warm-up routes render on the ROOT navigator (above the shell), so they
/// inherit NOTHING from CourseRoadmapRoute's provider tree. The start-lesson
/// handoff (paywall check, tracking, roleplay/output launch) reads several of
/// those cubits via context, so mirror the roadmap's provider set here — all
/// DI singletons, same instances.
Widget _warmUpProviders(Widget child) => MultiBlocProvider(
  providers: [
    BlocProvider.value(value: AppDI.injector.get<WarmUpCubit>()),
    BlocProvider.value(value: AppDI.injector.get<CourseRoadmapCubit>()),
    BlocProvider.value(value: AppDI.injector.get<CourseLessonCubit>()),
    BlocProvider.value(value: AppDI.injector.get<ProgressCubit>()),
    BlocProvider.value(value: AppDI.injector.get<HomeCubit>()),
    BlocProvider.value(value: AppDI.injector.get<ProfileCubit>()),
    BlocProvider.value(value: AppDI.injector.get<RoleplayPointCubit>()),
    BlocProvider.value(value: AppDI.injector.get<FeedbackCubit>()),
    BlocProvider.value(value: AppDI.injector.get<PageCubit>()),
  ],
  child: child,
);

class WarmUpIntroRoute extends BaseTransitionRouteData with $WarmUpIntroRoute {
  const WarmUpIntroRoute();

  // Render on the ROOT navigator (above the shell) so the full-screen warm-up
  // flow covers the bottom nav instead of sitting inside a shell branch.
  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppConfig.instance.rootNaviKey;

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.slideFromBottom;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) {
    return _warmUpProviders(const WarmUpIntroPage());
  }
}

class WarmUpQuestionRoute extends BaseTransitionRouteData with $WarmUpQuestionRoute {
  const WarmUpQuestionRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppConfig.instance.rootNaviKey;

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.slideFromRight;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) {
    return _warmUpProviders(const WarmUpQuestionPage());
  }
}

class WarmUpCompletionRoute extends BaseTransitionRouteData with $WarmUpCompletionRoute {
  const WarmUpCompletionRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppConfig.instance.rootNaviKey;

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.slideFromRight;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) {
    return _warmUpProviders(const WarmUpCompletionPage());
  }
}
