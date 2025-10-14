part of 'routes.dart';

//* Splash Page
@TypedGoRoute<SplashRoute>(path: RoutePath.splash, name: RouteNamed.splash)
class SplashRoute extends GoRouteData with $SplashRoute {
  const SplashRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const SplashPage();
}

//* Intro Page
@TypedGoRoute<IntroRoute>(path: RoutePath.intro, name: RouteNamed.intro)
class IntroRoute extends GoRouteData with $IntroRoute {
  const IntroRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const IntroPage();
}

//* No Auth Page
@TypedGoRoute<NoAuthRoute>(path: RoutePath.noAuth, name: RouteNamed.noAuth)
class NoAuthRoute extends GoRouteData with $NoAuthRoute {
  const NoAuthRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const NoAuthPage();
}

//* Auth Pages
@TypedGoRoute<LoginRoute>(
  path: RoutePath.login,
  name: RouteNamed.login,
  routes: [
    TypedGoRoute<ForgotPasswordRoute>(path: RoutePath.forgotPassword, name: RouteNamed.forgotPassword),
    TypedGoRoute<OtpRoute>(path: RoutePath.otp, name: RouteNamed.otp),
    TypedGoRoute<SetupPasswordRoute>(path: RoutePath.setupPassword, name: RouteNamed.setupPassword),
    TypedGoRoute<ChangePasswordRoute>(path: RoutePath.changePassword, name: RouteNamed.changePassword),
  ],
)
class LoginRoute extends BaseTransitionRouteData with $LoginRoute {
  final bool isRegister;
  const LoginRoute({this.isRegister = false});

  // Example 1: Using preset slide from right transition
  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.slideFromRight;

  // Example 2: Using preset slide from bottom transition
  // @override
  // RouteTransitionConfig get transitionConfig => RouteTransitionConfig.slideFromBottom;

  // Example 3: Using scale transition with custom duration
  // @override
  // RouteTransitionConfig get transitionConfig => const RouteTransitionConfig(
  //   type: RouteTransitionType.scale,
  //   duration: Duration(milliseconds: 500),
  //   minScale: 0.7,
  // );

  // Example 4: Using rotation transition
  // @override
  // RouteTransitionConfig get transitionConfig => const RouteTransitionConfig(
  //   type: RouteTransitionType.rotation,
  //   rotationAngle: 0.25, // Quarter turn
  //   curve: Curves.elasticOut,
  // );

  // Example 5: Custom slide with bounce effect
  // @override
  // RouteTransitionConfig get transitionConfig => const RouteTransitionConfig(
  //   type: RouteTransitionType.slide,
  //   slideEffect: SlideRouteEffect.leftToRight,
  //   curve: Curves.bounceOut,
  //   duration: Duration(milliseconds: 600),
  // );

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) {
    return LoginPage(isRegister: isRegister);
  }
}

class ForgotPasswordRoute extends GoRouteData with $ForgotPasswordRoute {
  const ForgotPasswordRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const ForgotPassPage();
}

class OtpRoute extends GoRouteData with $OtpRoute {
  const OtpRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const SizedBox();
}

class SetupPasswordRoute extends GoRouteData with $SetupPasswordRoute {
  const SetupPasswordRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const SetupPassPage();
}

class ChangePasswordRoute extends GoRouteData with $ChangePasswordRoute {
  const ChangePasswordRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const ChangePasswordPage();
}

@TypedGoRoute<RegisterRoute>(path: RoutePath.register, name: RouteNamed.register)
class RegisterRoute extends GoRouteData with $RegisterRoute {
  const RegisterRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const RegisterPage();
}

// Example of a route with scale transition
@TypedGoRoute<HomeRoute>(
  path: RoutePath.home,
  name: RouteNamed.home,
  routes: [],
)
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
      child: Container(),
    );
  }
}

//* Draw Route with custom transition

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
