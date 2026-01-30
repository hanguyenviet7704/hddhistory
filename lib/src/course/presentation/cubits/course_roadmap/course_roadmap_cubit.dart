part of '../../../course.dart';

@lazySingleton
class CourseRoadmapCubit extends HydratedCubit<CourseRoadmapState> with CubitUseCaseHandlerMixin<CourseRoadmapState> {
  final GetRoadmapUseCase _getRoadmapUseCase;
  LessonEntity? _cachedLessonAction;

  CourseRoadmapCubit(
    this._getRoadmapUseCase,
  ) : super(CourseRoadmapState.initial());

  @override
  CourseRoadmapState fromJson(Map<String, dynamic> json) => CourseRoadmapState.fromJson(json);

  @override
  Map<String, dynamic> toJson(CourseRoadmapState state) => state.toJson();

  void reset() => emit(CourseRoadmapState.initial());

  void setRoadmapSource(String source) => emit(state.copyWith(roadmapSource: source));

  void setCurrentLevelProgress(List<CourseLevelProgressEntity> courseLevelProgresses) async {
    if (state.roadmap.levels.isEmpty) return;
    final CourseLevelProgressEntity currentLevelProgress = courseLevelProgresses.firstWhere(
      (progress) => progress.level == state.currentCourseLevel && progress.courseId == state.roadmap.courseId,
      orElse: () => CourseLevelProgressEntity(),
    );
    emit(state.copyWith(currentLevelProgress: currentLevelProgress));
  }

  void setCurrentCourseLevel(CourseLevel level) => emit(state.copyWith(currentCourseLevel: level));

  void setCurrentLesson(LessonEntity lesson) {
    _cachedLessonAction = lesson;
    emit(state.copyWith(currentLesson: lesson));
  }

  LessonEntity? get cachedLessonAction => _cachedLessonAction;

  bool _isSameLesson(LessonEntity a, LessonEntity b) {
    if (a.id.isEmpty || b.id.isEmpty) return false;
    final aKeypointId = a.firstKeypoint.id;
    final bKeypointId = b.firstKeypoint.id;
    if (aKeypointId.isNotEmpty && bKeypointId.isNotEmpty) {
      return aKeypointId == bKeypointId;
    }
    return a.id == b.id;
  }

  List<LessonEntity> _buildDisplayLessons(RoadmapEntity roadmap) {
    final levels = roadmap.levels;
    if (levels.isEmpty) return [];
    final levelFlags = roadmap.levelSequentialUnlockFlags;
    final displayLessons = <LessonEntity>[];
    for (var levelIndex = 0; levelIndex < levels.length; levelIndex++) {
      final level = levels[levelIndex];
      final enableSequentialUnlock = levelIndex < levelFlags.length ? levelFlags[levelIndex] : false;
      final nodeFlags = enableSequentialUnlock ? level.sequentialUnlockFlags : List<bool>.filled(level.nodes.length, false);
      for (var nodeIndex = 0; nodeIndex < level.nodes.length; nodeIndex++) {
        final node = level.nodes[nodeIndex];
        final enableNodeUnlock = nodeIndex < nodeFlags.length ? nodeFlags[nodeIndex] : false;
        final items = node.lessonsList.applySequentialUnlock(enableAutoUnlock: enableNodeUnlock);
        displayLessons.addAll(items);
      }
    }
    return displayLessons;
  }

  MapEntry<LessonEntity, CourseLevel> _resolveAutoSelectedLesson(RoadmapEntity roadmap) {
    final levels = roadmap.levels;
    if (levels.isEmpty) return MapEntry(LessonEntity(), state.currentCourseLevel);

    final displayLessons = _buildDisplayLessons(roadmap);
    if (displayLessons.isEmpty) return MapEntry(LessonEntity(), state.currentCourseLevel);

    final hasProgress = displayLessons.any((lesson) => lesson.roadmapProgress != ProcessEnum.notStarted);
    LessonEntity selectedLesson;
    if (!hasProgress) {
      selectedLesson = displayLessons.first;
    } else {
      final inProgressLessons = displayLessons.where((lesson) => lesson.roadmapProgress == ProcessEnum.inProgress).toList();
      if (inProgressLessons.isNotEmpty) {
        selectedLesson = inProgressLessons.last;
      } else {
        selectedLesson = displayLessons.lastWhere(
          (lesson) => lesson.roadmapProgress != ProcessEnum.notStarted,
          orElse: () => displayLessons.first,
        );
      }
    }

    CourseLevel selectedLevel = state.currentCourseLevel;
    for (final level in levels) {
      final levelLessons = level.roadmapLessonsList;
      if (levelLessons.any((lesson) => _isSameLesson(lesson, selectedLesson))) {
        selectedLevel = level.level;
        break;
      }
    }

    return MapEntry(selectedLesson, selectedLevel);
  }

  void loadRoadmap({String courseId = ''}) async {
    if (courseId.isEmpty) {
      courseId = state.roadmap.courseId;
    }
    if (courseId.isEmpty) return;

    await runUseCase<RoadmapEntity>(
      usecase: () => _getRoadmapUseCase(courseId),
      buildLoadingState: () => state.copyWith(status: CourseRoadmapStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: CourseRoadmapStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (roadmap) {
        final selection = _resolveAutoSelectedLesson(roadmap);
        final selectedLesson = selection.key;
        final selectedLevel = selection.value;
        _cachedLessonAction = selectedLesson.id.isEmpty ? null : selectedLesson;
        emit(
          state.copyWith(
            status: CourseRoadmapStatus.success,
            roadmap: roadmap,
            currentLesson: selectedLesson,
            currentCourseLevel: selectedLevel,
          ),
        );
      },
    );
  }
}
