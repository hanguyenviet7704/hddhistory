part of '../routes.dart';

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
  Widget build(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<CourseRoadmapCubit>()),
      BlocProvider.value(value: AppDI.injector.get<PageCubit>()),
      BlocProvider.value(value: AppDI.injector.get<AuthBloc>()),
    ],
    child: const RegisterPage(),
  );
}
