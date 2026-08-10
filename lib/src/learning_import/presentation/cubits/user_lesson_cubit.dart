part of '../../learning_import.dart';

const _kLessonsPageSize = 20;

/// Owns the lessons the user already has: the list, the reader, and the two
/// writes against them (bookmark, delete).
@lazySingleton
class UserLessonCubit extends Cubit<UserLessonState>
    with CubitUseCaseHandlerMixin<UserLessonState> {
  final GetUserLessonsUseCase _getUserLessonsUseCase;
  final GetUserLessonUseCase _getUserLessonUseCase;
  final UpdateUserLessonProgressUseCase _updateProgressUseCase;
  final DeleteUserLessonUseCase _deleteUserLessonUseCase;

  UserLessonCubit(
    this._getUserLessonsUseCase,
    this._getUserLessonUseCase,
    this._updateProgressUseCase,
    this._deleteUserLessonUseCase,
  ) : super(UserLessonState.initial());

  Future<void> loadLessons({bool isInit = true}) async {
    final nextPage = isInit ? 1 : state.pageData.nextPage;
    if (!isInit && state.pageData.isLastPage) return;

    await runUseCasePageBreak<UserLessonEntity>(
      usecase: () =>
          _getUserLessonsUseCase(page: nextPage, take: _kLessonsPageSize),
      currentPageData: state.pageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: UserLessonStatus.loading),
      onFailure: (error) => emit(state.copyWith(
        status: UserLessonStatus.failure,
        errorMessage: error,
      )),
      onSuccess: (pageData) => emit(state.copyWith(
        status: UserLessonStatus.success,
        pageData: pageData,
      )),
    );
  }

  /// Loads one lesson in full. Always refetched rather than reused from the
  /// list, because the card in [pageData] has no sections.
  Future<void> openLesson(String id) => runUseCase<UserLessonEntity>(
    usecase: () => _getUserLessonUseCase(id),
    buildLoadingState: () =>
        state.copyWith(status: UserLessonStatus.loading, selected: null),
    onFailure: (error) => emit(state.copyWith(
      status: UserLessonStatus.failure,
      errorMessage: error,
    )),
    onSuccess: (lesson) => emit(
      state.copyWith(status: UserLessonStatus.success, selected: lesson),
    ),
  );

  /// Remember where the reader stopped.
  ///
  /// Deliberately silent and un-awaited by callers: this fires as the reader
  /// leaves the screen, and neither a spinner nor an error toast belongs in
  /// that moment. Losing the write costs a bookmark, not a lesson.
  void saveProgress({required String lessonId, required int sectionIndex}) {
    final selected = state.selected;
    if (selected != null && selected.stopAtSectionIndex == sectionIndex) return;

    // Optimistic: the card should show the new progress immediately even though
    // the write is in flight, because the user is looking at it right now.
    if (selected != null && selected.id == lessonId) {
      emit(state.copyWith(
        selected: selected.copyWith(stopAtSectionIndex: sectionIndex),
      ));
    }

    _updateProgressUseCase(
      UpdateLessonProgressParams(
        lessonId: lessonId,
        stopAtSectionIndex: sectionIndex,
      ),
    ).run();
  }

  Future<void> deleteLesson(String id) => runUseCaseVoid(
    usecase: () => _deleteUserLessonUseCase(id),
    onFailure: (error) => emit(state.copyWith(errorMessage: error)),
    // Reload rather than filtering locally: a page whose item count shrank can
    // need a different set of pages, and re-asking is cheaper than getting that
    // arithmetic subtly wrong.
    onSuccess: () => loadLessons(),
  );
}
