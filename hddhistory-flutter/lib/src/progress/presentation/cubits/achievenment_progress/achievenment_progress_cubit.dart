part of '../../../progress.dart';

@lazySingleton
class AchievenmentProgressCubit extends Cubit<AchievenmentProgressState> with CubitUseCaseHandlerMixin<AchievenmentProgressState> {
  final GetAllAchievenmentResponsesUseCase _getAllAchievenmentResponsesUseCase;
  final GetCachedAchievenmentResponsesUseCase _getCachedAchievenmentResponsesUseCase;
  final GetCourseLevelProgressUseCase _getCourseLevelProgressUseCase;

  AchievenmentProgressCubit(
    this._getAllAchievenmentResponsesUseCase,
    this._getCachedAchievenmentResponsesUseCase,
    this._getCourseLevelProgressUseCase,
  ) : super(AchievenmentProgressState.initial());

  void loadAllAchievenmentResponses() async {
    // Cache-first (stale-while-revalidate): surface the last cached achievements
    // immediately so the Profile screen renders without a spinner, then refresh
    // from network in the background. The inline loader only shows when there is
    // genuinely nothing to display yet (achievenments still empty). Skipped once
    // data is already in memory (e.g. pull-to-refresh) so a refresh keeps the
    // current data visible instead of flashing the cache.
    if (state.achievenments.isEmpty) {
      final cached = await _getCachedAchievenmentResponsesUseCase();
      if (cached.isNotEmpty && state.achievenments.isEmpty) {
        emit(
          state.copyWith(
            status: AchievenmentProgressStatus.success,
            achievenments: cached,
          ),
        );
      }
    }

    await runUseCaseList<AchievenmentResponseEntity>(
      usecase: () => _getAllAchievenmentResponsesUseCase(unit),
      buildLoadingState: () => state.copyWith(status: AchievenmentProgressStatus.loading),
      onFailure: (error) {
        // Keep already-shown (cached) data on a background refresh failure;
        // only surface the error state when there is nothing to fall back to.
        if (state.achievenments.isEmpty) {
          emit(
            state.copyWith(
              status: AchievenmentProgressStatus.failure,
              errorMessage: error,
            ),
          );
        }
      },
      onSuccess: (data) {
        emit(
          state.copyWith(
            status: AchievenmentProgressStatus.success,
            achievenments: data,
          ),
        );
      },
    );
  }

  void loadCourseLevelProgress(String courseId) async {
    await runUseCaseList<CourseLevelProgressEntity>(
      usecase: () => _getCourseLevelProgressUseCase(courseId),
      buildLoadingState: () => state.copyWith(status: AchievenmentProgressStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: AchievenmentProgressStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (data) {
        emit(
          state.copyWith(
            status: AchievenmentProgressStatus.success,
            courseLevelProgresses: data,
          ),
        );
        AppDI.injector.get<CourseRoadmapCubit>().setCurrentLevelProgress(data);
      },
    );
  }
}
