part of '../routes.dart';

//? Course - Roleplay
class RoleplayIntroRoute extends BaseTransitionRouteData with $RoleplayIntroRoute {
  const RoleplayIntroRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<RoleplayCubit>()),
      BlocProvider.value(value: AppDI.injector.get<RoleplayPointCubit>()),
    ],
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
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<RoleplayCubit>()),
      BlocProvider.value(value: AppDI.injector.get<RoleplayPointCubit>()),
      BlocProvider.value(value: AppDI.injector.get<FeedbackCubit>()),
    ],
    child: const RoleplayFeedbackPage(),
  );
}
