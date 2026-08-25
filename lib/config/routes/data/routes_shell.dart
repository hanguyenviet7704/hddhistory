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
            TypedGoRoute<DailyWarmUpRoute>(
              path: RoutePath.dailyWarmUp,
              name: RouteNamed.dailyWarmUp,
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
            //? Skillset Courses (full grid for one skillset)
            TypedGoRoute<SkillsetCoursesRoute>(
              path: RoutePath.skillsetCourses,
              name: RouteNamed.skillsetCourses,
            ),
            //? Warm Up (return-refresher)
            TypedGoRoute<WarmUpIntroRoute>(path: RoutePath.warmUpIntro, name: RouteNamed.warmUpIntro),
            TypedGoRoute<WarmUpQuestionRoute>(path: RoutePath.warmUpQuestion, name: RouteNamed.warmUpQuestion),
            TypedGoRoute<WarmUpCompletionRoute>(path: RoutePath.warmUpCompletion, name: RouteNamed.warmUpCompletion),
            //? Change Course
            TypedGoRoute<ChangeCourseRoute>(
              path: RoutePath.changeCourse,
              name: RouteNamed.changeCourse,
            ),
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
            TypedGoRoute<VideoLessonRoute>(
              path: RoutePath.videoLesson,
              name: RouteNamed.videoLesson,
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
    //? Explore branch — appended last so existing branch indices (home=0,
    //? course=1, setting=2) are unchanged; this branch is index 3.
    TypedStatefulShellBranch<ExploreShellBranchData>(
      routes: [
        TypedGoRoute<CourseRoute>(
          path: RoutePath.course,
          name: RouteNamed.course,
          routes: [
            TypedGoRoute<ImportLessonRoute>(
              path: RoutePath.importLesson,
              name: RouteNamed.importLesson,
              routes: [
                TypedGoRoute<ImportGeneratingRoute>(
                  path: RoutePath.importGenerating,
                  name: RouteNamed.importGenerating,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    //? Habit branch — appended last so existing branch indices are
    //? unchanged; this branch is index 4.
    TypedStatefulShellBranch<HabitShellBranchData>(
      routes: [
        TypedGoRoute<HabitRoute>(
          path: RoutePath.habit,
          name: RouteNamed.habit,
          routes: [
            TypedGoRoute<DailyCheckInRoute>(
              path: RoutePath.dailyCheckIn,
              name: RouteNamed.dailyCheckIn,
            ),
          ],
        ),
      ],
    ),
    //? Library branch — appended last so existing branch indices are unchanged;
    //? this branch is index 5. My Creations (`myLessons`) moved here from the
    //? Setting branch with the Library tab: the row that opens it now lives on
    //? this branch, and a push must stay inside its own branch to be visible.
    TypedStatefulShellBranch<LibraryShellBranchData>(
      routes: [
        TypedGoRoute<LibraryRoute>(
          path: RoutePath.library,
          name: RouteNamed.library,
          routes: [
            TypedGoRoute<LibraryHistoryRoute>(
              path: RoutePath.libraryHistory,
              name: RouteNamed.libraryHistory,
            ),
            TypedGoRoute<SavedCoursesRoute>(
              path: RoutePath.savedCourses,
              name: RouteNamed.savedCourses,
            ),
            TypedGoRoute<SavedCardsRoute>(
              path: RoutePath.savedCards,
              name: RouteNamed.savedCards,
            ),
            TypedGoRoute<MyLessonsRoute>(
              path: RoutePath.myLessons,
              name: RouteNamed.myLessons,
              routes: [
                TypedGoRoute<LessonReaderRoute>(path: RoutePath.lessonReader, name: RouteNamed.lessonReader),
              ],
            ),
          ],
        ),
      ],
    ),
    //? Community branch — appended last so existing branch indices are
    //? unchanged; this branch is index 6. Every community screen is nested
    //? under it: a push from another branch would render in that branch's
    //? navigator, which is off screen.
    TypedStatefulShellBranch<CommunityShellBranchData>(
      routes: [
        TypedGoRoute<CommunityRoute>(
          path: RoutePath.community,
          name: RouteNamed.community,
          routes: [
            TypedGoRoute<CommunityTopicRoute>(
              path: RoutePath.communityTopic,
              name: RouteNamed.communityTopic,
            ),
            TypedGoRoute<CommunityPostRoute>(
              path: RoutePath.communityPost,
              name: RouteNamed.communityPost,
            ),
            TypedGoRoute<CommunityWeeklyRoute>(
              path: RoutePath.communityWeekly,
              name: RouteNamed.communityWeekly,
            ),
            TypedGoRoute<CommunityChatRoute>(
              path: RoutePath.communityChat,
              name: RouteNamed.communityChat,
            ),
            TypedGoRoute<CommunityComposeRoute>(
              path: RoutePath.communityCompose,
              name: RouteNamed.communityCompose,
            ),
            TypedGoRoute<CommunityNotificationRoute>(
              path: RoutePath.communityNotifications,
              name: RouteNamed.communityNotifications,
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
    return CustomTransitionPage(
      name: RouteNamed.shellRoute,
      key: state.pageKey,
      child: ScaffoldLayout(navigationShell: navigationShell),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
          child: child,
        );
      },
    );
  }
}
