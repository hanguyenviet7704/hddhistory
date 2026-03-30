part of '../routes.dart';

@TypedStatefulShellRoute<MainShellRouteData>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    TypedStatefulShellBranch<HomeShellBranchData>(
      routes: [
        TypedGoRoute<HomeRoute>(
          path: RoutePath.home,
          name: RouteNamed.home,
          routes: [
            TypedGoRoute<HomeLearningStreakRoute>(
              path: RoutePath.homeLearningStreak,
              name: RouteNamed.homeLearningStreak,
            ),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<CourseShellBranchData>(
      routes: [
        TypedGoRoute<CourseRoadmapRoute>(
          path: RoutePath.courseRoadmap,
          name: RouteNamed.courseRoadmap,
          routes: [
            //? Course - Lesson
            TypedGoRoute<LessonRoute>(path: RoutePath.lesson, name: RouteNamed.lesson),
            TypedGoRoute<NoCorrectAnswerDocumentRoute>(
              path: RoutePath.noCorrectAnswerDocument,
              name: RouteNamed.noCorrectAnswerDocument,
            ),
            TypedGoRoute<ReviewTimeRoute>(path: RoutePath.reviewTime, name: RouteNamed.reviewTime),
            TypedGoRoute<KeypointCompleteRoute>(path: RoutePath.keypointComplete, name: RouteNamed.keypointComplete),
            TypedGoRoute<BadgeProgressRoute>(path: RoutePath.badgeProgress, name: RouteNamed.badgeProgress),

            //? Course - Roleplay
            TypedGoRoute<RoleplayIntroRoute>(
              path: RoutePath.roleplayIntro,
              name: RouteNamed.roleplayIntro,
              routes: [
                TypedGoRoute<RoleplayRoute>(path: RoutePath.roleplay, name: RouteNamed.roleplay),
                TypedGoRoute<RoleplayCompleteRoute>(path: RoutePath.roleplayComplete, name: RouteNamed.roleplayComplete),
                TypedGoRoute<RoleplayFeedbackRoute>(path: RoutePath.roleplayFeedback, name: RouteNamed.roleplayFeedback),
              ],
            ),
            TypedGoRoute<OutputPracticeRoute>(
              path: RoutePath.outputPractice,
              name: RouteNamed.outputPractice,
            ),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<SettingShellBranchData>(
      routes: [
        TypedGoRoute<ProfileRoute>(
          path: RoutePath.profile,
          name: RouteNamed.profile,
          routes: [
            TypedGoRoute<ProfileInfoRoute>(path: RoutePath.profileInfo, name: RouteNamed.profileInfo),
            TypedGoRoute<SettingRoute>(
              path: RoutePath.setting,
              name: RouteNamed.setting,
              routes: [
                TypedGoRoute<NotificationRoute>(path: RoutePath.notification, name: RouteNamed.notification),
                TypedGoRoute<ChangeLanguageRoute>(path: RoutePath.changeLanguage, name: RouteNamed.changeLanguage),
                TypedGoRoute<ManageSubscriptionRoute>(path: RoutePath.manageSubscription, name: RouteNamed.manageSubscription),
              ],
            ),
          ],
        ),
      ],
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
