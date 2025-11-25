part of '../routes.dart';

//* Shell routes - Course
class CourseShellBranchData extends StatefulShellBranchData {
  const CourseShellBranchData();
  // static final GlobalKey<NavigatorState> $navigatorKey = AppConfig.rootNaviKey;
  static final List<NavigatorObserver> $observers = [AppConfig.instance.courseRouterObserver];
}

//* Course Route
@TypedGoRoute<CourseRoute>(path: RoutePath.course, name: RouteNamed.course)
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
    ],
    child: CoursePage(selectedTabIndex: selectedTabIndex),
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
    ],
    child: const CourseRoadmapPage(),
  );
}
