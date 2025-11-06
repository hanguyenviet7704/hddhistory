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
        String location = context.read<DeeplinkCubit>().state.currentRouteName;

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
          BlocProvider.value(value: AppDI.injector.get<HomeCubit>()..initializeData()),
          BlocProvider.value(value: AppDI.injector.get<CourseRoadmapCubit>()),
          BlocProvider.value(value: AppDI.injector.get<ProgressCubit>()),
          BlocProvider.value(value: AppDI.injector.get<CourseCubit>()),
        ],
        child: const HomePage(),
      ),
    );
  }
}
