part of '../../../progress.dart';

@lazySingleton
class AchievenmentProgressCubit extends Cubit<AchievenmentProgressState> with CubitUseCaseHandlerMixin<AchievenmentProgressState> {
  final GetAllAchievenmentResponsesUseCase _getAllAchievenmentResponsesUseCase;
  final GetCourseLevelProgressUseCase _getCourseLevelProgressUseCase;

  AchievenmentProgressCubit(
    this._getAllAchievenmentResponsesUseCase,
    this._getCourseLevelProgressUseCase,
  ) : super(AchievenmentProgressState.initial());

  void loadAllAchievenmentResponses(UserProgressFilter filter) async {
    await runUseCaseList<AchievenmentResponseEntity>(
      usecase: () => _getAllAchievenmentResponsesUseCase(filter),
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
            achievenmentResponses: data,
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
      },
    );
  }
}
