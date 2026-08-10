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

/// The user's shelf of self-generated lessons, reached from a Profile row.
///
/// Both cubits are provided here rather than in the page: the import flow's
/// polling outlives the sheet that started it (the user is explicitly allowed
/// to walk away mid-generation), so its cubit must not be scoped to a widget.
class MyLessonsRoute extends BaseTransitionRouteData with $MyLessonsRoute {
  const MyLessonsRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<UserLessonCubit>()),
      BlocProvider.value(value: AppDI.injector.get<LearningImportCubit>()),
    ],
    child: const MyLessonsPage(),
  );
}

class LessonReaderRoute extends BaseTransitionRouteData with $LessonReaderRoute {
  const LessonReaderRoute(this.lessonId);

  final String lessonId;

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.slideFromRight;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<UserLessonCubit>()),
    ],
    child: LessonReaderPage(lessonId: lessonId),
  );
}
