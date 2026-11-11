part of '../routes.dart';

class OutputPracticeRoute extends BaseTransitionRouteData with $OutputPracticeRoute {
  const OutputPracticeRoute({required this.sectionId});

  final String sectionId;

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.fade;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<OutputPracticeCubit>()),
      BlocProvider.value(value: AppDI.injector.get<OutputPracticeSocketCubit>()),
      BlocProvider.value(value: AppDI.injector.get<HomeCubit>()),
      BlocProvider.value(value: AppDI.injector.get<CourseRoadmapCubit>()),
    ],
    child: OutputPracticePage(sectionId: sectionId),
  );
}
