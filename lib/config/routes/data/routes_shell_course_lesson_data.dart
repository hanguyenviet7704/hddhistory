part of '../routes.dart';

//? Course - Lesson
// class LessonListRoute extends BaseTransitionRouteData with $LessonListRoute {
//   const LessonListRoute();

//   @override
//   RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

//   @override
//   Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
//     providers: [
//       BlocProvider.value(value: AppDI.injector.get<CourseLessonCubit>()),
//       BlocProvider.value(value: AppDI.injector.get<LessonCubit>()),
//       BlocProvider.value(value: AppDI.injector.get<ProgressCubit>()),
//       BlocProvider.value(value: AppDI.injector.get<HomeCubit>()),
//     ],
//     child: const LessonListPage(),
//   );
// }

Widget _buildLessonFlowPage(Widget child) {
  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<CourseLessonCubit>()),
      BlocProvider.value(value: AppDI.injector.get<LessonCubit>()),
      BlocProvider(create: (_) => LessonAudioCubit()),
      BlocProvider.value(value: AppDI.injector.get<ExerciseCubit>()),
      BlocProvider.value(value: AppDI.injector.get<TheoryCubit>()),
      // Not `@lazySingleton`/`@injectable` (see its own doc comment) — needs a
      // fresh instance per route entry, wired to THIS route's freshly-created
      // `LessonAudioCubit`/`LessonCubit`/`TheoryCubit` above, not a
      // process-lifetime singleton holding a stale sibling.
      BlocProvider(
        create: (context) => KeypointCardCubit(
          lessonCubit: context.read<LessonCubit>(),
          theoryCubit: context.read<TheoryCubit>(),
          audioCubit: context.read<LessonAudioCubit>(),
        ),
      ),
      BlocProvider.value(value: AppDI.injector.get<ChoiceCubit>()),
      BlocProvider.value(value: AppDI.injector.get<DragAndDropCubit>()),
      BlocProvider.value(value: AppDI.injector.get<ArrangeTheSequenceCubit>()),
      BlocProvider.value(value: AppDI.injector.get<CuesPlacementCubit>()),
      BlocProvider.value(value: AppDI.injector.get<MarkStressWordCubit>()),
      BlocProvider.value(value: AppDI.injector.get<SpeakingCubit>()),
      BlocProvider.value(value: AppDI.injector.get<ProgressCubit>()),
      BlocProvider.value(value: AppDI.injector.get<PageCubit>()),
      BlocProvider.value(value: AppDI.injector.get<FeedbackCubit>()),
    ],
    child: child,
  );
}

class LessonRoute extends BaseTransitionRouteData with $LessonRoute {
  /// Repurposed from "which mode tab (Read/Listen) to open into" (the old
  /// dual-mode split) to "should the FIRST keypoint's narration autoplay the
  /// instant this page mounts" — the unified screen has no mode tabs left.
  /// Kept as the same `'read'`/`'audio'` wire values so existing/legacy deep
  /// links keep resolving without crashing.
  ///
  /// Defaults to `'audio'`: opening a keypoint starts reading it out. It used to
  /// default to `'read'` and every call site had to remember to opt in, which is
  /// how entries like the lesson list ended up silent. Opting OUT is now the
  /// thing a caller has to say explicitly, and only a link does.
  final String initialMode;

  const LessonRoute({
    this.initialMode = 'audio',
  });

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => _buildLessonFlowPage(
    LessonPage(
      autoplayOnEntry: LessonEntryMode.fromRouteValue(initialMode).isAudio,
    ),
  );
}

class NoCorrectAnswerDocumentRoute extends BaseTransitionRouteData with $NoCorrectAnswerDocumentRoute {
  final String groupId;

  const NoCorrectAnswerDocumentRoute({required this.groupId});

  @override
  CustomTransitionPage<void> buildPage(BuildContext context, GoRouterState state) {
    return CustomTransitionPage<void>(
      name: state.name,
      key: state.pageKey,
      opaque: false,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 140),
      child: buildPageWidget(context, state),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) {
    return _buildLessonFlowPage(NoCorrectAnswerDocumentPage(groupId: groupId));
  }
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

  // Fade, matching the rest of the completion flow (recap → habit → here →
  // practice) — the scale-in read as a shove next to the overlays' fades.
  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.fade;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<CourseRoadmapCubit>()),
      BlocProvider.value(value: AppDI.injector.get<CourseLessonCubit>()),
      BlocProvider.value(value: AppDI.injector.get<LessonCubit>()),
      BlocProvider.value(value: AppDI.injector.get<FeedbackCubit>()),
      BlocProvider.value(value: AppDI.injector.get<HomeCubit>()),
    ],
    child: const KeypointCompletePage(),
  );
}

class BadgeProgressRoute extends BaseTransitionRouteData with $BadgeProgressRoute {
  const BadgeProgressRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<LessonCubit>()),
      BlocProvider.value(value: AppDI.injector.get<CourseRoadmapCubit>()),
      BlocProvider.value(value: AppDI.injector.get<CourseLessonCubit>()),
    ],
    child: const BadgeProgressPage(),
  );
}
