part of '../routes.dart';

//* Shell routes - Habit
class HabitShellBranchData extends StatefulShellBranchData {
  const HabitShellBranchData();
  static final List<NavigatorObserver> $observers = [AppConfig.instance.habitRouterObserver];
}

//* Habit Route — registered inside the Habit shell branch so HabitPage
//* renders within the shell and keeps the bottom navigation bar.
class HabitRoute extends BaseTransitionRouteData with $HabitRoute {
  /// Analytics entry source for the `habit_scr_view` event
  /// (nav_habit / home_habit / home_banner / habit_added_scr). Passed as a
  /// query param so each entry point is distinguishable; defaults to
  /// `nav_habit` (bottom-nav tap).
  final String? source;

  const HabitRoute({this.source});

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<HabitCubit>()),
      BlocProvider.value(value: AppDI.injector.get<PageCubit>()),
    ],
    child: HabitPage(source: source ?? 'nav_habit'),
  );
}

class DailyCheckInRoute extends BaseTransitionRouteData with $DailyCheckInRoute {
  const DailyCheckInRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.slideFromBottom;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => BlocProvider.value(
    value: AppDI.injector.get<HabitCubit>(),
    child: const DailyCheckInPage(),
  );
}
