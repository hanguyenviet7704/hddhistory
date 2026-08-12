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

  /// A plain fade — neither a right-hand push nor a zoom.
  ///
  /// This screen is arrived at from four places (the progress toast, the done
  /// popup, the generating screen, the shelf) and left by two more, none of
  /// which is a forward step in a flow. A slide says "deeper in", and `scale`
  /// — the catalogue roadmap's choice — reads as the screen zooming up at you.
  /// A fade says the thing it should: you are looking at it now.
  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.fade;

  /// Lands on the lesson's ROADMAP, not in the deck. It used to hand straight
  /// off to the reader, which left a generated lesson with no page of its own —
  /// nothing to come back to, nowhere to hang practice off. The roadmap's CTA
  /// does what this route used to do on arrival.
  ///
  /// Only [UserLessonCubit] is needed now. The route used to also create a
  /// per-entry audio cubit for a reader this feature owned; the lesson is read
  /// by the catalogue's own screen these days, and that screen brings its own
  /// player (see `_buildLessonFlowPage`).
  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => BlocProvider.value(
    value: AppDI.injector.get<UserLessonCubit>(),
    child: UserLessonRoadmapPage(lessonId: lessonId),
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
