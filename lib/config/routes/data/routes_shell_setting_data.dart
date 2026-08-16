part of '../routes.dart';

//* Shell routes - Setting
class SettingShellBranchData extends StatefulShellBranchData {
  const SettingShellBranchData();
  // static final GlobalKey<NavigatorState> $navigatorKey = AppConfig.rootNaviKey;
  static final List<NavigatorObserver> $observers = [AppConfig.instance.settingRouterObserver];
}

//? Setting Route
class SettingRoute extends BaseTransitionRouteData with $SettingRoute {
  const SettingRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<ProfileCubit>()),
      BlocProvider.value(value: AppDI.injector.get<IapCubit>()),
      BlocProvider.value(value: AppDI.injector.get<AuthBloc>()),
      BlocProvider.value(value: AppDI.injector.get<NotificationCubit>()),
    ],
    child: const SettingPage(),
  );
}

class ProfileRoute extends BaseTransitionRouteData with $ProfileRoute {
  const ProfileRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<AuthBloc>()),
      BlocProvider.value(value: AppDI.injector.get<ProfileCubit>()),
      BlocProvider.value(value: AppDI.injector.get<IapCubit>()),
      BlocProvider.value(value: AppDI.injector.get<AchievenmentProgressCubit>()),
    ],
    child: const ProfilePage(),
  );
}

class ProfileInfoRoute extends BaseTransitionRouteData with $ProfileInfoRoute {
  const ProfileInfoRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<AuthBloc>()),
      BlocProvider.value(value: AppDI.injector.get<ProfileCubit>()),
      BlocProvider.value(value: AppDI.injector.get<IapCubit>()),
    ],
    child: const ProfileInfoPage(),
  );
}

class NotificationRoute extends BaseTransitionRouteData with $NotificationRoute {
  const NotificationRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => const SizedBox();
}

class ChangeLanguageRoute extends GoRouteData with $ChangeLanguageRoute {
  const ChangeLanguageRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return ModalSheetPage<void>(
      key: state.pageKey,
      name: state.name,
      barrierColor: AppCustomColor.bottomSheetScrim,
      bounce: true,
      backgroundColor: AppCustomColor.backgroundWhite,
      topRadius: const Radius.circular(24),
      builder: (_) => const ChangeLanguagePage(),
    );
  }
}

class ManageSubscriptionRoute extends BaseTransitionRouteData with $ManageSubscriptionRoute {
  const ManageSubscriptionRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<ProfileCubit>()),
    ],
    child: const UserSubcriptionPage(),
  );
}

/// "Make your own lesson" — reached from the Import pill on Explore.
///
/// Both cubits are provided here rather than in the page: the import flow's
/// polling outlives the screen that started it (the user is explicitly allowed
/// to walk away mid-generation), so its cubit must not be scoped to a widget.
class ImportLessonRoute extends BaseTransitionRouteData with $ImportLessonRoute {
  const ImportLessonRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.slideFromBottom;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<LearningImportCubit>()),
      BlocProvider.value(value: AppDI.injector.get<UserLessonCubit>()),
    ],
    child: const ImportLessonPage(),
  );
}

/// The wait. Its own route so minimising is an ordinary pop rather than a
/// state flag the form screen has to carry.
class ImportGeneratingRoute extends BaseTransitionRouteData with $ImportGeneratingRoute {
  const ImportGeneratingRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.fade;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<LearningImportCubit>()),
      BlocProvider.value(value: AppDI.injector.get<UserLessonCubit>()),
    ],
    child: const ImportGeneratingPage(),
  );
}
