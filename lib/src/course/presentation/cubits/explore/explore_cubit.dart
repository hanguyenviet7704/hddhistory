part of '../../../course.dart';

@lazySingleton
class ExploreCubit extends Cubit<ExploreState> with CubitUseCaseHandlerMixin<ExploreState> {
  final GetExploreSectionsUseCase _getExploreSections;

  ExploreCubit(this._getExploreSections) : super(ExploreState(seed: _newSeed()));

  Future<void>? _inFlight;

  /// A fresh seed per cold start. `millisecondsSinceEpoch` is plenty — the only
  /// requirement is that two launches differ, not that it be unguessable.
  static int _newSeed() => DateTime.now().millisecondsSinceEpoch & 0x7fffffff;

  /// Loads the tab if it has nothing to show, and does nothing otherwise.
  ///
  /// Wired from the route listener so re-entering the tab recovers from a
  /// failed first load, without refetching a tab that is already populated —
  /// the same self-healing contract as `HomeCubit.ensureHomeDataLoaded`.
  Future<void> ensureExploreDataLoaded() {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    if (state.status == ExploreStatus.success && state.sections.isNotEmpty) {
      return Future.value();
    }
    return refresh();
  }

  /// Fetches unconditionally — pull to refresh, and the retry button on the
  /// failure state. Keeps the session's seed so the arrangement does not jump
  /// while the reader is looking at it.
  Future<void> refresh() {
    final future = _load().whenComplete(() => _inFlight = null);
    _inFlight = future;
    return future;
  }

  Future<void> _load() async {
    emit(state.copyWith(status: ExploreStatus.loading, errorMessage: null));

    await runUseCaseList<ExploreSectionEntity>(
      usecase: () => _getExploreSections(state.seed),
      onFailure: (errorMessage) => emit(
        state.copyWith(
          status: ExploreStatus.failure,
          errorMessage: errorMessage,
        ),
      ),
      onSuccess: (sections) => emit(
        state.copyWith(status: ExploreStatus.success, sections: sections),
      ),
    );
  }
}
