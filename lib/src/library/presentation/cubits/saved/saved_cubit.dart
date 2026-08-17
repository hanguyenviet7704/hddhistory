part of '../../../library.dart';

const int _kSavedCoursesPageSize = 20;
const int _kSavedCardsPageSize = 20;

/// Everything the reader has bookmarked: saved courses, saved recap cards, and
/// the two id sets that decide how a bookmark icon draws.
///
/// A single app-wide cubit rather than one per screen, because the bookmark is
/// not a Library concept — it is pressed on the course roadmap and at the end of
/// a keypoint, and read back on a screen in a different shell branch. Splitting
/// it would mean two owners of the same truth and a bookmark that disagrees with
/// itself depending on how you got there.
@lazySingleton
class SavedCubit extends Cubit<SavedState> with CubitUseCaseHandlerMixin<SavedState> {
  final GetSavedCoursesUseCase _getSavedCoursesUseCase;
  final GetSavedCourseIdsUseCase _getSavedCourseIdsUseCase;
  final ToggleSavedCourseUseCase _toggleSavedCourseUseCase;
  final GetSavedCardsUseCase _getSavedCardsUseCase;
  final GetSavedCardIdsUseCase _getSavedCardIdsUseCase;
  final ToggleSavedCardUseCase _toggleSavedCardUseCase;

  SavedCubit(
    this._getSavedCoursesUseCase,
    this._getSavedCourseIdsUseCase,
    this._toggleSavedCourseUseCase,
    this._getSavedCardsUseCase,
    this._getSavedCardIdsUseCase,
    this._toggleSavedCardUseCase,
  ) : super(SavedState.initial());

  // ---------------------------------------------------------------- id sets

  /// Reads both id sets. Cheap (two arrays of ids) and idempotent, so callers
  /// fire it on entry without coordinating.
  Future<void> loadIds() async {
    await Future.wait([_loadCourseIds(), _loadCardIds()]);
    if (!isClosed) emit(state.copyWith(idsLoaded: true));
  }

  /// Only when they have never been read. Entry points call this; a pull to
  /// refresh calls [loadIds].
  Future<void> ensureIdsLoaded() async {
    if (state.idsLoaded) return;
    await loadIds();
  }

  Future<void> _loadCourseIds() async {
    final result = await _getSavedCourseIdsUseCase().run();
    if (isClosed) return;
    result.fold(
      // Silent by design — see SavedRepository.getSavedCourseIds. Keeping the
      // previous set beats blanking every bookmark on one dropped request.
      (_) {},
      (ids) => emit(state.copyWith(courseIds: ids.toSet())),
    );
  }

  Future<void> _loadCardIds() async {
    final result = await _getSavedCardIdsUseCase().run();
    if (isClosed) return;
    result.fold((_) {}, (ids) => emit(state.copyWith(cardIds: ids.toSet())));
  }

  // -------------------------------------------------------------- toggles

  /// Flips the bookmark on screen first, then writes.
  ///
  /// Optimistic because the icon IS the feedback: waiting on the round trip
  /// leaves a tap that does nothing for as long as the network takes, on a
  /// control whose whole job is to answer instantly. A failed write rolls the
  /// icon back, which says "not saved" without a banner over the reader's card.
  ///
  /// Returns the state the bookmark ended in, so the caller knows whether to
  /// show its "Saved" toast — and does not show one for a write that failed.
  Future<bool> toggleCourse(String courseId) async {
    if (courseId.isEmpty) return false;

    final wasSaved = state.isCourseSaved(courseId);
    final willSave = !wasSaved;
    _applyCourseId(courseId, saved: willSave);

    final result = await _toggleSavedCourseUseCase(
      courseId: courseId,
      save: willSave,
    ).run();
    if (isClosed) return willSave;

    return result.fold(
      (_) {
        _applyCourseId(courseId, saved: wasSaved);
        return wasSaved;
      },
      (_) {
        // The Saved list is now stale: an unsave has to drop the row the reader
        // is looking at, and a save has to appear the next time they open it.
        if (state.coursesStatus != SavedStatus.initial) {
          unawaited(loadCourses(isInit: true));
        }
        return willSave;
      },
    );
  }

  /// Same contract as [toggleCourse]. [params] carries the recap snapshot, so
  /// the caller must be the surface that HAS the recap — the card itself.
  Future<bool> toggleCard(SaveCardParams params) async {
    if (params.keypointId.isEmpty) return false;

    final wasSaved = state.isCardSaved(params.keypointId);
    final willSave = !wasSaved;
    _applyCardId(params.keypointId, saved: willSave);

    final result = await _toggleSavedCardUseCase(
      params: params,
      save: willSave,
    ).run();
    if (isClosed) return willSave;

    return result.fold(
      (_) {
        _applyCardId(params.keypointId, saved: wasSaved);
        return wasSaved;
      },
      (_) {
        if (state.cardsStatus != SavedStatus.initial) {
          unawaited(loadCards(isInit: true));
        }
        return willSave;
      },
    );
  }

  /// Removing from the Saved cards screen itself: the row is dropped from the
  /// loaded page immediately rather than refetching, so the grid does not
  /// flicker through a loading state to lose one card.
  Future<void> removeCard(String keypointId) async {
    if (keypointId.isEmpty) return;
    if (!state.isCardSaved(keypointId)) return;

    final previousPage = state.cardsPageData;
    _applyCardId(keypointId, saved: false);
    emit(
      state.copyWith(
        cardsPageData: previousPage.copyWith(
          items: previousPage.items.where((card) => card.keypointId != keypointId).toList(),
        ),
      ),
    );

    final result = await _toggleSavedCardUseCase(
      params: SaveCardParams(keypointId: keypointId),
      save: false,
    ).run();
    if (isClosed) return;

    result.fold(
      (_) {
        _applyCardId(keypointId, saved: true);
        emit(state.copyWith(cardsPageData: previousPage));
      },
      (_) {},
    );
  }

  void _applyCourseId(String courseId, {required bool saved}) {
    final next = Set<String>.from(state.courseIds);
    saved ? next.add(courseId) : next.remove(courseId);
    emit(state.copyWith(courseIds: next));
  }

  void _applyCardId(String keypointId, {required bool saved}) {
    final next = Set<String>.from(state.cardIds);
    saved ? next.add(keypointId) : next.remove(keypointId);
    emit(state.copyWith(cardIds: next));
  }

  // ------------------------------------------------------------ saved list

  void setCoursesFilter(SavedCourseFilter filter) {
    if (state.coursesFilter == filter) return;
    // Clear the page as the chip changes: the previous chip's rows are not this
    // chip's, and leaving them up while the new page loads shows the reader a
    // list that contradicts the chip they just pressed.
    emit(
      state.copyWith(
        coursesFilter: filter,
        coursesPageData: const BasePageBreak<CourseEntity>(),
      ),
    );
    unawaited(loadCourses(isInit: true));
  }

  Future<void> loadCourses({bool isInit = true}) async {
    final nextPage = isInit ? 1 : state.coursesPageData.nextPage;
    if (!isInit && state.coursesPageData.isLastPage) return;

    await runUseCasePageBreak<CourseEntity>(
      usecase: () => _getSavedCoursesUseCase(
        page: nextPage,
        take: _kSavedCoursesPageSize,
        filter: state.coursesFilter,
      ),
      currentPageData: state.coursesPageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(coursesStatus: SavedStatus.loading),
      onFailure: (error) => emit(
        state.copyWith(
          coursesStatus: SavedStatus.failure,
          errorMessage: error,
        ),
      ),
      onSuccess: (pageData) => emit(
        state.copyWith(
          coursesStatus: SavedStatus.success,
          coursesPageData: pageData,
        ),
      ),
    );
  }

  Future<void> ensureCoursesLoaded() async {
    if (state.coursesStatus != SavedStatus.initial) return;
    await loadCourses(isInit: true);
  }

  // ----------------------------------------------------------- saved cards

  void setCardsDeckView({required bool deck}) {
    if (state.cardsDeckView == deck) return;
    emit(state.copyWith(cardsDeckView: deck));
  }

  Future<void> loadCards({bool isInit = true}) async {
    final nextPage = isInit ? 1 : state.cardsPageData.nextPage;
    if (!isInit && state.cardsPageData.isLastPage) return;

    await runUseCasePageBreak<SavedCardEntity>(
      usecase: () => _getSavedCardsUseCase(page: nextPage, take: _kSavedCardsPageSize),
      currentPageData: state.cardsPageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(cardsStatus: SavedStatus.loading),
      onFailure: (error) => emit(
        state.copyWith(cardsStatus: SavedStatus.failure, errorMessage: error),
      ),
      onSuccess: (pageData) => emit(
        state.copyWith(
          cardsStatus: SavedStatus.success,
          cardsPageData: pageData,
        ),
      ),
    );
  }

  Future<void> ensureCardsLoaded() async {
    if (state.cardsStatus != SavedStatus.initial) return;
    await loadCards(isInit: true);
  }
}
