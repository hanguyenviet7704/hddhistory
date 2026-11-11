part of '../../../library.dart';

enum SavedStatus { initial, loading, success, failure }

/// One cubit, two lists, and the two id sets that keep every bookmark in the
/// app agreeing with each other.
///
/// The sets are what the roadmap header and the recap card read — neither of
/// them has a list to consult, and neither should pay for one.
@freezed
abstract class SavedState with _$SavedState {
  const factory SavedState({
    @Default(<String>{}) Set<String> courseIds,
    @Default(<String>{}) Set<String> cardIds,

    /// Whether the id sets have been read at all this session. Until they have,
    /// a hollow bookmark means "not known yet", not "not saved" — surfaces that
    /// can mislead check this before drawing.
    @Default(false) bool idsLoaded,
    @Default(SavedStatus.initial) SavedStatus coursesStatus,
    @Default(SavedCourseFilter.upNext) SavedCourseFilter coursesFilter,
    @Default(BasePageBreak<CourseEntity>()) BasePageBreak<CourseEntity> coursesPageData,
    @Default(SavedStatus.initial) SavedStatus cardsStatus,
    @Default(BasePageBreak<SavedCardEntity>()) BasePageBreak<SavedCardEntity> cardsPageData,

    /// Deck vs grid on the Saved cards screen. Lives in state, not in the
    /// page's State, so leaving and coming back keeps the reader's choice.
    @Default(false) bool cardsDeckView,
    String? errorMessage,
  }) = _SavedState;

  factory SavedState.initial() => const SavedState();
}

extension SavedStateX on SavedState {
  bool isCourseSaved(String courseId) => courseIds.contains(courseId);

  bool isCardSaved(String keypointId) => cardIds.contains(keypointId);

  bool get isCoursesInitialLoading => coursesStatus == SavedStatus.loading && coursesPageData.items.isEmpty;

  bool get isCoursesEmpty => coursesStatus == SavedStatus.success && coursesPageData.items.isEmpty;

  bool get isCoursesFailure => coursesStatus == SavedStatus.failure;

  bool get isCardsInitialLoading => cardsStatus == SavedStatus.loading && cardsPageData.items.isEmpty;

  bool get isCardsEmpty => cardsStatus == SavedStatus.success && cardsPageData.items.isEmpty;

  bool get isCardsFailure => cardsStatus == SavedStatus.failure;

  List<SavedCardEntity> get cards => cardsPageData.items;
}
