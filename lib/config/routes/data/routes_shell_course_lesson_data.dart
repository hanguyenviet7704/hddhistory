part of '../routes.dart';

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

class KeypointCompleteRoute extends BaseTransitionRouteData with $KeypointCompleteRoute {
  const KeypointCompleteRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => const KeypointCompletePage();
}

class LessonCompleteRoute extends BaseTransitionRouteData with $LessonCompleteRoute {
  const LessonCompleteRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) {
    return const LessonCompletePage();
  }
}
