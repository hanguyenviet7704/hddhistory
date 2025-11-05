part of '../../../course.dart';

@lazySingleton
class CourseLessonCubit extends Cubit<CourseLessonState> with CubitUseCaseHandlerMixin<CourseLessonState> {
  final GetCourseLessonUseCase _getCourseLessonUseCase;

  CourseLessonCubit(
    this._getCourseLessonUseCase,
  ) : super(CourseLessonState.initial());

  void loadLesson(String id) async {
    await runUseCase<LessonEntity>(
      usecase: () => _getCourseLessonUseCase(id),
      buildLoadingState: () => state.copyWith(status: CourseLessonStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: CourseLessonStatus.failure, errorMessage: error));
      },
      onSuccess: (lesson) {
        emit(state.copyWith(status: CourseLessonStatus.success, selectedLesson: lesson));
      },
    );
  }
}
