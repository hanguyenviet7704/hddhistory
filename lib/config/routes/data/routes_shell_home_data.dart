part of '../routes.dart';

//* Shell routes - Home
class HomeShellBranchData extends StatefulShellBranchData {
  const HomeShellBranchData();
  // static final GlobalKey<NavigatorState> $navigatorKey = AppConfig.rootNaviKey;
  static final List<NavigatorObserver> $observers = [AppConfig.instance.homeRouterObserver];
}

//? Home Route
class HomeRoute extends BaseTransitionRouteData with $HomeRoute {
  const HomeRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) {
    return BlocListener<ConnectivityCubit, ConnectivityState>(
      listener: (context, state) {
        String location = context.read<PageCubit>().state.currentRouteName;

        if (!state.isInternetConnected) {
          if (location != RouteNamed.noInternetConnection) {
            NoInternetConnectionRoute().push(context);
          }
          return;
        }

        if (location == RouteNamed.noInternetConnection) {
          context.pop();
        }
      },
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: AppDI.injector.get<HomeCubit>()),
          BlocProvider.value(value: AppDI.injector.get<CourseRoadmapCubit>()),
          BlocProvider.value(value: AppDI.injector.get<ProgressCubit>()),
          BlocProvider.value(value: AppDI.injector.get<CourseCubit>()),
          BlocProvider.value(value: AppDI.injector.get<IapCubit>()),
          BlocProvider.value(value: AppDI.injector.get<LearningStreakCubit>()),
          BlocProvider.value(value: AppDI.injector.get<ProfileCubit>()),
          BlocProvider.value(value: AppDI.injector.get<InAppSurveyCubit>()),
          BlocProvider.value(value: AppDI.injector.get<DailyWarmUpCubit>()),
          BlocProvider.value(value: AppDI.injector.get<SpacedReviewCubit>()),
          // Feeds Home's "Tiến độ học tập" grid, which moved here from the
          // Profile tab (design note 2026-09-04) along with the cubit it reads.
          BlocProvider.value(value: AppDI.injector.get<AchievenmentProgressCubit>()),
        ],
        child: const HomePage(),
      ),
    );
  }
}

class HomeLearningStreakRoute extends BaseTransitionRouteData with $HomeLearningStreakRoute {
  const HomeLearningStreakRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.slideFromBottom;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) {
    return BlocProvider.value(
      value: AppDI.injector.get<LearningStreakCubit>(),
      child: const LearningStreakPage(),
    );
  }
}

class DailyWarmUpRoute extends BaseTransitionRouteData with $DailyWarmUpRoute {
  const DailyWarmUpRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.slideFromBottom;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) {
    return BlocProvider.value(
      value: AppDI.injector.get<DailyWarmUpCubit>(),
      child: const DailyWarmUpPage(),
    );
  }
}

/// The spaced-review pages render on the ROOT navigator so the full-screen
/// player covers the bottom nav, and so inherit nothing from Home's providers.
class SpacedReviewQuestionRoute extends BaseTransitionRouteData with $SpacedReviewQuestionRoute {
  const SpacedReviewQuestionRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppConfig.instance.rootNaviKey;

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.slideFromBottom;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) {
    return BlocProvider.value(
      value: AppDI.injector.get<SpacedReviewCubit>(),
      child: const SpacedReviewQuestionPage(),
    );
  }
}

class SpacedReviewCompletionRoute extends BaseTransitionRouteData with $SpacedReviewCompletionRoute {
  const SpacedReviewCompletionRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey = AppConfig.instance.rootNaviKey;

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.slideFromRight;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) {
    return BlocProvider.value(
      value: AppDI.injector.get<SpacedReviewCubit>(),
      child: const SpacedReviewCompletionPage(),
    );
  }
}
