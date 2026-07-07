part of '../routes.dart';

//* Shell routes - Habit
class HabitShellBranchData extends StatefulShellBranchData {
  const HabitShellBranchData();
  static final List<NavigatorObserver> $observers = [AppConfig.instance.habitRouterObserver];
}

//* Habit Route — registered inside the Habit shell branch so HabitPage
//* renders within the shell and keeps the bottom navigation bar.
class HabitRoute extends BaseTransitionRouteData with $HabitRoute {
  const HabitRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<HabitCubit>()),
      BlocProvider.value(value: AppDI.injector.get<PageCubit>()),
    ],
    child: const HabitPage(),
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

//* Habit Summary Page — root-level route (not part of the Habit shell branch)
//* so it can be pushed on top of the Course branch right after a lesson
//* finishes, without switching the bottom-nav tab (design.md 5.4).
@TypedGoRoute<HabitSummaryRoute>(path: RoutePath.habitSummary, name: RouteNamed.habitSummary)
class HabitSummaryRoute extends BaseTransitionRouteData with $HabitSummaryRoute {
  const HabitSummaryRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.slideFromBottom;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => BlocProvider.value(
    value: AppDI.injector.get<HabitCubit>(),
    child: const HabitSummaryPage(),
  );
}
