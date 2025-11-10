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
  const CourseRoute();

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
    child: const CoursePage(),
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
    ],
    child: const CourseRoadmapPage(),
  );
}

//? Course - Lesson
class LessonListRoute extends BaseTransitionRouteData with $LessonListRoute {
  const LessonListRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<CourseLessonCubit>()),
      BlocProvider.value(value: AppDI.injector.get<LessonCubit>()),
    ],
    child: const LessonListPage(),
  );
}

class LessonRoute extends BaseTransitionRouteData with $LessonRoute {
  const LessonRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<LessonCubit>()),
      BlocProvider.value(value: AppDI.injector.get<ExerciseCubit>()),
      BlocProvider.value(value: AppDI.injector.get<TheoryCubit>()),
      BlocProvider.value(value: AppDI.injector.get<ChoiceCubit>()),
      BlocProvider.value(value: AppDI.injector.get<DragAndDropCubit>()),
      BlocProvider.value(value: AppDI.injector.get<ArrangeTheSequenceCubit>()),
      BlocProvider.value(value: AppDI.injector.get<CuesPlacementCubit>()),
      BlocProvider.value(value: AppDI.injector.get<MarkStressWordCubit>()),
      BlocProvider.value(value: AppDI.injector.get<SpeakingCubit>()),
    ],
    child: const LessonPage(),
  );
}

class ReviewTimeRoute extends BaseTransitionRouteData with $ReviewTimeRoute {
  const ReviewTimeRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => BlocProvider.value(
    value: AppDI.injector.get<LessonCubit>(),
    child: const ReviewTimePage(),
  );
}

class LessonCompleteRoute extends BaseTransitionRouteData with $LessonCompleteRoute {
  final String? type;
  final String? keypointTitle;
  final double? progress;

  const LessonCompleteRoute({
    this.type,
    this.keypointTitle,
    this.progress,
  });

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) {
    final lessonType = type == 'lesson' ? LessonCompleteType.lesson : LessonCompleteType.keypoint;
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: AppDI.injector.get<LessonCubit>()),
        BlocProvider.value(value: AppDI.injector.get<ProgressCubit>()),
      ],
      child: LessonCompletePage(
        type: lessonType,
        keypointTitle: keypointTitle,
        progress: progress,
      ),
    );
  }
}

//? Course - Roleplay
class RoleplayIntroRoute extends BaseTransitionRouteData with $RoleplayIntroRoute {
  const RoleplayIntroRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => BlocProvider.value(
    value: AppDI.injector.get<RoleplayCubit>(),
    child: const RoleplayIntroPage(),
  );
}

class RoleplayRoute extends BaseTransitionRouteData with $RoleplayRoute {
  const RoleplayRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => BlocProvider.value(
    value: AppDI.injector.get<RoleplayCubit>(),
    child: const RoleplayPage(),
  );
}

class RoleplayCompleteRoute extends BaseTransitionRouteData with $RoleplayCompleteRoute {
  const RoleplayCompleteRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => BlocProvider.value(
    value: AppDI.injector.get<RoleplayCubit>(),
    child: const RoleplayCompletePage(),
  );
}

class RoleplayFeedbackRoute extends BaseTransitionRouteData with $RoleplayFeedbackRoute {
  const RoleplayFeedbackRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => BlocProvider.value(
    value: AppDI.injector.get<RoleplayCubit>(),
    child: const RoleplayFeedbackPage(),
  );
}
