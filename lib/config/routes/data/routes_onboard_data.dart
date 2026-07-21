part of '../routes.dart';

@TypedGoRoute<OnboardV2Route>(path: RoutePath.onboardV2, name: RouteNamed.onboardV2)
class OnboardV2Route extends GoRouteData with $OnboardV2Route {
  const OnboardV2Route();

  @override
  Widget build(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<OnboardV2Cubit>()..initialize()),
      BlocProvider.value(value: AppDI.injector.get<UserCubit>()),
      BlocProvider.value(value: AppDI.injector.get<NotificationCubit>()),
    ],
    child: const OnboardV2Page(),
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
    this.courseEntryMode = false,
    this.showPaywallAfterAuth = false,
  }) : assert(
         !(courseEntryMode && showPaywallAfterAuth),
         'NotificationRequestRoute cannot enter course mode and show paywall after auth at the same time.',
       );

  final bool courseEntryMode;
  final bool showPaywallAfterAuth;

  @override
  Widget build(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<AuthBloc>()),
      BlocProvider.value(value: AppDI.injector.get<UserCubit>()),
      BlocProvider.value(value: AppDI.injector.get<NotificationCubit>()),
    ],
    child: NotificationRequestPage(
      courseEntryMode: courseEntryMode,
      showPaywallAfterAuth: showPaywallAfterAuth,
    ),
  );
}
