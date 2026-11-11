part of '../../learning_import.dart';

const _kLessonsPageSize = 20;

/// Owns the lessons the user already has: the list, the reader, and the two
/// writes against them (the reading bookmark, and "I want more of this").
///
/// No delete: the shelf is read-only by product call (2026-08-12). The endpoint
/// and its use case still exist (`DeleteUserLessonUseCase`) — nothing in the app
/// calls them.
@lazySingleton
class UserLessonCubit extends Cubit<UserLessonState>
    with CubitUseCaseHandlerMixin<UserLessonState> {
  final GetUserLessonsUseCase _getUserLessonsUseCase;
  final GetUserLessonUseCase _getUserLessonUseCase;
  final UpdateUserLessonProgressUseCase _updateProgressUseCase;
  final RequestUserLessonAdditionalContentUseCase _requestAdditionalContentUseCase;

  UserLessonCubit(
    this._getUserLessonsUseCase,
    this._getUserLessonUseCase,
    this._updateProgressUseCase,
    this._requestAdditionalContentUseCase,
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
  /// list, because the card in [pageData] has no body.
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

  /// Records "I want more content on this lesson", and reflects it locally the
  /// moment it lands.
  ///
  /// The selected lesson is patched rather than refetched: the answer is one
  /// timestamp, the panel only needs to know it exists, and re-reading the whole
  /// body (every keypoint, every card) to learn a date would rebuild the roadmap
  /// under the reader mid-tap. Failure leaves the panel unanswered — the wish was
  /// not recorded, so claiming otherwise would be a lie the next entry corrects.
  Future<void> requestAdditionalContent() async {
    final lesson = state.selected;
    if (lesson == null || lesson.id.isEmpty) return;
    if (lesson.hasRequestedMoreContent) return;

    await runUseCaseVoid(
      usecase: () => _requestAdditionalContentUseCase(lesson.id),
      onFailure: (error) => emit(state.copyWith(errorMessage: error)),
      onSuccess: () {
        final current = state.selected;
        if (current?.id != lesson.id) return;
        emit(
          state.copyWith(
            selected: current!.copyWith(
              additionalContentRequestedAt: DateTime.now(),
            ),
          ),
        );
      },
    );
  }

  /// The lesson behind a synthesised keypoint id, or null when that id belongs
  /// to the catalogue — the question the reader's completion screen asks before
  /// deciding where "next" goes.
  UserLessonEntity? lessonForKeypoint(String keypointId) {
    final lessonId = UserLessonCourseMapper.lessonIdOf(keypointId);
    if (lessonId.isEmpty) return null;
    final selected = state.selected;

    return selected?.id == lessonId ? selected : null;
  }

  /// Remember where the reader stopped: which keypoint, and which card in it.
  ///
  /// Deliberately silent and un-awaited by callers: this fires as the reader
  /// leaves the screen, and neither a spinner nor an error toast belongs in
  /// that moment. Losing the write costs a bookmark, not a lesson.
  void saveProgress({
    required String lessonId,
    required int keypointIndex,
    required int sectionIndex,
  }) {
    final selected = state.selected;
    final unchanged = selected != null &&
        selected.stopAtKeypointIndex == keypointIndex &&
        selected.stopAtSectionIndex == sectionIndex;
    if (unchanged) return;

    // Optimistic: the card should show the new progress immediately even though
    // the write is in flight, because the user is looking at it right now.
    if (selected != null && selected.id == lessonId) {
      emit(state.copyWith(
        selected: selected.copyWith(
          stopAtKeypointIndex: keypointIndex,
          stopAtSectionIndex: sectionIndex,
        ),
      ));
    }

    _updateProgressUseCase(
      UpdateLessonProgressParams(
        lessonId: lessonId,
        stopAtKeypointIndex: keypointIndex,
        stopAtSectionIndex: sectionIndex,
      ),
    ).run();
  }
}
