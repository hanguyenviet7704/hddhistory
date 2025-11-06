part of '../routes.dart';

@TypedStatefulShellRoute<MainShellRouteData>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    TypedStatefulShellBranch<HomeShellBranchData>(
      routes: [
        TypedGoRoute<HomeRoute>(
          path: RoutePath.home,
          name: RouteNamed.home,
        ),
      ],
    ),
    TypedStatefulShellBranch<CourseShellBranchData>(
      routes: [
        TypedGoRoute<CourseRoadmapRoute>(
          path: RoutePath.courseRoadmap,
          name: RouteNamed.courseRoadmap,
          routes: [
            TypedGoRoute<LessonListRoute>(
              path: RoutePath.lessonList,
              name: RouteNamed.lessonList,
              routes: [
                TypedGoRoute<LessonRoute>(path: RoutePath.lesson, name: RouteNamed.lesson),
                TypedGoRoute<ReviewTimeRoute>(path: RoutePath.reviewTime, name: RouteNamed.reviewTime),
                TypedGoRoute<LessonCompleteRoute>(path: RoutePath.lessonComplete, name: RouteNamed.lessonComplete),
              ],
            ),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<SettingShellBranchData>(
      routes: [TypedGoRoute<SettingRoute>(path: RoutePath.setting, name: RouteNamed.setting)],
    ),
  ],
)
class MainShellRouteData extends StatefulShellRouteData {
  const MainShellRouteData();

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppConfig.instance.rootNaviKey;

  @override
  Page<void> pageBuilder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    final PageState pageState = context.watch<PageCubit>().state;
    Widget child = navigationShell;

    if (pageState.isPrimaryRoute) {
      child = ScaffoldLayout(navigationShell: navigationShell);
    }

    return CustomTransitionPage(
      name: RouteNamed.shellRoute,
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
          child: child,
        );
      },
    );
  }
}
