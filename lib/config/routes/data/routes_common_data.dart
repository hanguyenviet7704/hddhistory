part of '../routes.dart';

//* General Route
@TypedGoRoute<NoInternetConnectionRoute>(path: RoutePath.noInternetConnection, name: RouteNamed.noInternetConnection)
class NoInternetConnectionRoute extends BaseTransitionRouteData with $NoInternetConnectionRoute {
  const NoInternetConnectionRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.slideFromBottom;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => const NoInternetConnectionPage();
}

@TypedGoRoute<CommingSoonRoute>(path: RoutePath.commingSoon, name: RouteNamed.commingSoon)
class CommingSoonRoute extends GoRouteData with $CommingSoonRoute {
  const CommingSoonRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const CommingSoonPage();
}

//* Splash Page
@TypedGoRoute<SplashRoute>(path: RoutePath.splash, name: RouteNamed.splash)
class SplashRoute extends GoRouteData with $SplashRoute {
  const SplashRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider.value(
    value: AppDI.injector.get<IapCubit>(),
    child: const SplashPage(),
  );
}

//* Intro Page
@TypedGoRoute<OnboardIntroduceRoute>(path: RoutePath.onboardIntroduce, name: RouteNamed.onboardIntroduce)
class OnboardIntroduceRoute extends GoRouteData with $OnboardIntroduceRoute {
  const OnboardIntroduceRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<IntroCubit>()),
      BlocProvider.value(value: AppDI.injector.get<OnboardCubit>()),
    ],
    child: const OnboardIntroducePage(),
  );
}

//* Paywall Page
@TypedGoRoute<PaywallRoute>(path: RoutePath.paywall, name: RouteNamed.paywall)
class PaywallRoute extends BaseTransitionRouteData with $PaywallRoute {
  const PaywallRoute();

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<IapCubit>()),
    ],
    child: const PaywallPage(),
  );
}
