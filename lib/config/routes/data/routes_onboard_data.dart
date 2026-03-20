part of '../routes.dart';

//* Onboard Page
@TypedGoRoute<OnboardRoute>(path: RoutePath.onboard, name: RouteNamed.onboard)
class OnboardRoute extends GoRouteData with $OnboardRoute {
  const OnboardRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider.value(
    value: AppDI.injector.get<OnboardCubit>(),
    child: const OnboardPage(),
  );
}

@TypedGoRoute<OnboardBranchingRoute>(path: RoutePath.onboardBranching, name: RouteNamed.onboardBranching)
class OnboardBranchingRoute extends GoRouteData with $OnboardBranchingRoute {
  const OnboardBranchingRoute({this.userName = ''});

  final String userName;

  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider.value(
    value: AppDI.injector.get<OnboardBranchingCubit>(),
    child: OnboardBranchingPage(userName: userName),
  );
}

//* Data Collect Page
@TypedGoRoute<DataCollectRoute>(path: RoutePath.dataCollect, name: RouteNamed.dataCollect)
class DataCollectRoute extends GoRouteData with $DataCollectRoute {
  const DataCollectRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider.value(
    value: AppDI.injector.get<DataCollectCubit>(),
    child: const DataCollectPage(),
  );
}

@TypedGoRoute<DataCollectMotivationStepRoute>(path: RoutePath.dataCollectMotivationStep, name: RouteNamed.dataCollectMotivationStep)
class DataCollectMotivationStepRoute extends BaseTransitionRouteData with $DataCollectMotivationStepRoute {
  const DataCollectMotivationStepRoute({required this.step});

  final int step;

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<DataCollectCubit>()),
      BlocProvider.value(value: AppDI.injector.get<OnboardCubit>()),
    ],
    child: DataCollectMotivationStepPage(step: step),
  );
}

@TypedGoRoute<DataCollectFeedbackRoute>(path: RoutePath.dataCollectFeedback, name: RouteNamed.dataCollectFeedback)
class DataCollectFeedbackRoute extends BaseTransitionRouteData with $DataCollectFeedbackRoute {
  const DataCollectFeedbackRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => BlocProvider.value(
    value: AppDI.injector.get<DataCollectCubit>(),
    child: const DataCollectFeedbackPage(),
  );
}

@TypedGoRoute<DataCollectSummaryRoute>(path: RoutePath.dataCollectSummary, name: RouteNamed.dataCollectSummary)
class DataCollectSummaryRoute extends GoRouteData with $DataCollectSummaryRoute {
  const DataCollectSummaryRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<DataCollectCubit>()),
      BlocProvider.value(value: AppDI.injector.get<OnboardCubit>()),
    ],
    child: const DataCollectSummaryPage(),
  );
}

@TypedGoRoute<NotificationRequestRoute>(path: RoutePath.notificationRequest, name: RouteNamed.notificationRequest)
class NotificationRequestRoute extends GoRouteData with $NotificationRequestRoute {
  const NotificationRequestRoute({
    this.forceChooseCourseAfterLogin = false,
    this.showPaywallAfterAuth = false,
  }) : assert(
         !(forceChooseCourseAfterLogin && showPaywallAfterAuth),
         'NotificationRequestRoute cannot force course selection and show paywall after auth at the same time.',
       );

  final bool forceChooseCourseAfterLogin;
  final bool showPaywallAfterAuth;

  @override
  Widget build(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<UserCubit>()),
      BlocProvider.value(value: AppDI.injector.get<NotificationCubit>()),
    ],
    child: NotificationRequestPage(
      forceChooseCourseAfterLogin: forceChooseCourseAfterLogin,
      showPaywallAfterAuth: showPaywallAfterAuth,
    ),
  );
}
