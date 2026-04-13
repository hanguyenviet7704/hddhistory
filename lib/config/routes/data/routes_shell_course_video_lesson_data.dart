part of '../routes.dart';

class VideoLessonRoute extends BaseTransitionRouteData with $VideoLessonRoute {
  const VideoLessonRoute({
    required this.courseId,
    required this.nodeId,
    required this.lessonId,
  });

  final String courseId;
  final String nodeId;
  final String lessonId;

  @override
  RouteTransitionConfig get transitionConfig => RouteTransitionConfig.fade;

  @override
  Widget buildPageWidget(BuildContext context, GoRouterState state) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: AppDI.injector.get<VideoLessonCubit>()..reset()),
      BlocProvider.value(value: AppDI.injector.get<HomeCubit>()),
      BlocProvider.value(value: AppDI.injector.get<CourseRoadmapCubit>()),
    ],
    child: VideoLessonPage(
      courseId: courseId,
      nodeId: nodeId,
      lessonId: lessonId,
    ),
  );
}
