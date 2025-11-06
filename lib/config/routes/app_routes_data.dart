part of 'routes.dart';

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
  Widget build(BuildContext context, GoRouterState state) => const SplashPage();
}

//* Choose Language Page
@TypedGoRoute<ChooseLanguageRoute>(path: RoutePath.chooseLanguage, name: RouteNamed.chooseLanguage)
class ChooseLanguageRoute extends GoRouteData with $ChooseLanguageRoute {
  const ChooseLanguageRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const ChooseLanguagePage();
}

//* Intro Page
@TypedGoRoute<IntroRoute>(path: RoutePath.intro, name: RouteNamed.intro)
class IntroRoute extends GoRouteData with $IntroRoute {
  const IntroRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<IntroCubit>()),
      BlocProvider.value(value: AppDI.injector.get<OnboardCubit>()),
    ],
    child: const IntroPage(),
  );
}

//* Onboard Page
@TypedGoRoute<OnboardRoute>(path: RoutePath.onboard, name: RouteNamed.onboard)
class OnboardRoute extends GoRouteData with $OnboardRoute {
  const OnboardRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider.value(
    value: AppDI.injector.get<OnboardCubit>(),
    child: const OnboardPage(),
  );
}

//* Data Collect Page
@TypedGoRoute<DataCollectRoute>(path: RoutePath.dataCollect, name: RouteNamed.dataCollect)
class DataCollectRoute extends GoRouteData with $DataCollectRoute {
  const DataCollectRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider.value(
    value: AppDI.injector.get<DataCollectCubit>(),
    child: const DataCollectPage(),
  );
}

@TypedGoRoute<DataCollectMotivationStepRoute>(path: RoutePath.dataCollectMotivationStep, name: RouteNamed.dataCollectMotivationStep)
class DataCollectMotivationStepRoute extends BaseTransitionRouteData with $DataCollectMotivationStepRoute {
  const DataCollectMotivationStepRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => const DataCollectMotivationStepPage();
}

@TypedGoRoute<DataCollectSummaryRoute>(path: RoutePath.dataCollectSummary, name: RouteNamed.dataCollectSummary)
class DataCollectSummaryRoute extends GoRouteData with $DataCollectSummaryRoute {
  const DataCollectSummaryRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => BlocProvider.value(
    value: AppDI.injector.get<DataCollectCubit>(),
    child: const DataCollectSummaryPage(),
  );
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

//* Home Route
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

//* Course Route
@TypedGoRoute<CourseRoadmapRoute>(
  path: RoutePath.courseRoadmap,
  name: RouteNamed.courseRoadmap,
  routes: [
    TypedGoRoute<CourseRoute>(path: RoutePath.course, name: RouteNamed.course),
    TypedGoRoute<LessonListRoute>(path: RoutePath.lessonList, name: RouteNamed.lessonList),

    //? Lesson Route
    TypedGoRoute<LessonRoute>(path: RoutePath.lesson, name: RouteNamed.lesson),
    TypedGoRoute<ReviewTimeRoute>(path: RoutePath.reviewTime, name: RouteNamed.reviewTime),
    TypedGoRoute<LessonCompleteRoute>(path: RoutePath.lessonComplete, name: RouteNamed.lessonComplete),
  ],
)
class CourseRoadmapRoute extends BaseTransitionRouteData with $CourseRoadmapRoute {
  const CourseRoadmapRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<CourseRoadmapCubit>()),
      BlocProvider.value(value: AppDI.injector.get<CourseLessonCubit>()),
    ],
    child: const CourseRoadmapPage(),
  );
}

class CourseRoute extends BaseTransitionRouteData with $CourseRoute {
  const CourseRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<HomeCubit>()),
      BlocProvider.value(value: AppDI.injector.get<CourseCubit>()),
      BlocProvider.value(value: AppDI.injector.get<ProgressCubit>()),
      BlocProvider.value(value: AppDI.injector.get<CourseRoadmapCubit>()),
    ],
    child: const CoursePage(),
  );
}

class LessonListRoute extends BaseTransitionRouteData with $LessonListRoute {
  const LessonListRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<CourseLessonCubit>()),
      BlocProvider.value(value: AppDI.injector.get<LessonCubit>()),
    ],
    child: const LessonListPage(),
  );
}

class LessonRoute extends BaseTransitionRouteData with $LessonRoute {
  const LessonRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<LessonCubit>()),
      BlocProvider.value(value: AppDI.injector.get<ExerciseCubit>()),
      BlocProvider.value(value: AppDI.injector.get<TheoryCubit>()),
      BlocProvider.value(value: AppDI.injector.get<ChoiceCubit>()),
      BlocProvider.value(value: AppDI.injector.get<DragAndDropCubit>()),
      BlocProvider.value(value: AppDI.injector.get<ArrangeTheSequenceCubit>()),
      BlocProvider.value(value: AppDI.injector.get<CuesPlacementCubit>()),
      BlocProvider.value(value: AppDI.injector.get<MarkStressWordCubit>()),
      BlocProvider.value(value: AppDI.injector.get<SpeakingCubit>()),
    ],
    child: const LessonPage(),
  );
}

class ReviewTimeRoute extends BaseTransitionRouteData with $ReviewTimeRoute {
  const ReviewTimeRoute();

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => BlocProvider.value(
    value: AppDI.injector.get<LessonCubit>(),
    child: const ReviewTimePage(),
  );
}

class LessonCompleteRoute extends BaseTransitionRouteData with $LessonCompleteRoute {
  final String? type;
  final String? keypointTitle;
  final double? progress;

  const LessonCompleteRoute({
    this.type,
    this.keypointTitle,
    this.progress,
  });

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.scale;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) {
    final lessonType = type == 'lesson' ? LessonCompleteType.lesson : LessonCompleteType.keypoint;
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: AppDI.injector.get<LessonCubit>()),
        BlocProvider.value(value: AppDI.injector.get<ProgressCubit>()),
      ],
      child: LessonCompletePage(
        type: lessonType,
        keypointTitle: keypointTitle,
        progress: progress,
      ),
    );
  }
}
