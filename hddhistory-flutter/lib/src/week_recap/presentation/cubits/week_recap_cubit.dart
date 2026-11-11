part of '../../week_recap.dart';

/// Drives "Hành trình tuần qua": the Library banner, the Monday popup, the
/// poster, and the Sổ tay grid.
///
/// Deliberately NOT hydrated. A recap is a finished record, but WHETHER it has
/// been offered yet is server state (`viewedAt` / `dismissedAt`) — caching the
/// answer locally is what made onboarding re-run after a reinstall, and here it
/// would pop a popup the learner already dismissed on another device.
@lazySingleton
class WeekRecapCubit extends Cubit<WeekRecapState> {
  final GetCurrentWeekRecapUseCase _getCurrentUseCase;
  final GetWeekRecapArchiveUseCase _getArchiveUseCase;
  final GetWeekRecapUseCase _getByIdUseCase;
  final MarkWeekRecapInteractedUseCase _markInteractedUseCase;

  WeekRecapCubit(
    this._getCurrentUseCase,
    this._getArchiveUseCase,
    this._getByIdUseCase,
    this._markInteractedUseCase,
  ) : super(WeekRecapState.initial());

  /// Minutes east of UTC — the sign convention the API expects, so the week is
  /// cut on the learner's Monday rather than the server's.
  int get _tzOffset => DateTime.now().timeZoneOffset.inMinutes;

  /// When the recap in hand was fetched, so a re-entry can tell fresh from stale.
  DateTime? _loadedAt;

  /// How long a fetched recap is trusted before the next entry re-asks.
  ///
  /// NOT "until next Monday": the server keeps rebuilding a week's snapshot for
  /// three days after it closes (`REBUILD_WINDOW_MS`), so work that lands late —
  /// filed offline, done on another device, synced after the poster was first
  /// built — changes the week under an app that is still open. Without this the
  /// only way to see the new numbers is to kill the app. Long enough that
  /// flicking between tabs costs nothing.
  static const Duration _freshFor = Duration(minutes: 2);

  /// Loads last week, and refreshes it once the copy in hand has gone stale.
  ///
  /// Safe to call from the Library tab, the popup host and the poster alike:
  /// whichever runs first does the fetch and the others read the state. A stale
  /// refresh is silent — whatever is drawn stays up while it runs.
  Future<void> ensureCurrentLoaded() {
    if (state.status == WeekRecapStatus.loading) return Future.value();
    if (state.status != WeekRecapStatus.success) return loadCurrent();

    final loadedAt = _loadedAt;
    if (loadedAt != null && DateTime.now().difference(loadedAt) < _freshFor) {
      return Future.value();
    }

    return loadCurrent(silent: true);
  }

  /// [silent] is the refresh path: no spinner over a poster that is already
  /// drawn, and a failed refresh leaves the last good week up instead of
  /// replacing real numbers with an error.
  Future<void> loadCurrent({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(status: WeekRecapStatus.loading, errorMessage: null));
    }

    final result = await _getCurrentUseCase(tzOffset: _tzOffset).run();
    result.match(
      (error) {
        if (isClosed || silent) return;
        emit(state.copyWith(status: WeekRecapStatus.failure, errorMessage: error.toString()));
      },
      (data) {
        if (isClosed) return;
        _loadedAt = DateTime.now();
        final recap = _keepLocalAnswer(data.recap);
        final opened = state.opened;
        emit(
          state.copyWith(
            status: WeekRecapStatus.success,
            current: recap,
            // The poster screen holds its own copy. When that copy IS this week,
            // it has to move too, or the one screen showing the numbers is the
            // one screen still showing the old ones.
            opened: recap != null && opened?.id == recap.id ? recap : opened,
            archiveCount: data.archiveCount,
            errorMessage: null,
          ),
        );
      },
    );
  }

  /// Carries the local "Xem hành trình" / "Để sau" answer across a refresh.
  ///
  /// [markInteracted] stamps optimistically and its POST may still be in flight
  /// — or have failed. The server copy would then arrive unanswered and re-arm
  /// the "MỚI" pill (and the popup, on the next app open) for a week the reader
  /// has already dealt with.
  WeekRecapEntity? _keepLocalAnswer(WeekRecapEntity? fresh) {
    final previous = state.current;
    if (fresh == null || previous == null || previous.id != fresh.id) return fresh;

    return fresh.copyWith(
      viewedAt: fresh.viewedAt ?? previous.viewedAt,
      dismissedAt: _later(fresh.dismissedAt, previous.dismissedAt),
    );
  }

  static DateTime? _later(DateTime? one, DateTime? other) {
    if (one == null) return other;
    if (other == null) return one;

    return one.isAfter(other) ? one : other;
  }

  Future<void> loadArchive({bool isInit = true}) async {
    if (!isInit && state.archive.isLastPage) return;
    final page = isInit ? 1 : state.archive.nextPage;

    emit(
      state.copyWith(
        archiveStatus: isInit ? WeekRecapStatus.loading : state.archiveStatus,
        errorMessage: null,
      ),
    );

    final result = await _getArchiveUseCase(page: page).run();
    result.match(
      (error) {
        if (isClosed) return;
        emit(state.copyWith(archiveStatus: WeekRecapStatus.failure, errorMessage: error.toString()));
      },
      (data) {
        if (isClosed) return;
        emit(
          state.copyWith(
            archiveStatus: WeekRecapStatus.success,
            archive: isInit ? data : data.copyWith(items: [...state.archive.items, ...data.items]),
            errorMessage: null,
          ),
        );
      },
    );
  }

  /// Puts a recap on the poster screen.
  ///
  /// [recap] is passed straight through when the caller already holds it (the
  /// banner and the popup do), so the poster paints on the first frame instead
  /// of flashing a spinner over data already in memory.
  void openRecap(WeekRecapEntity recap) {
    emit(state.copyWith(opened: recap, openedStatus: WeekRecapStatus.success, errorMessage: null));
    _markViewedIfCurrent(recap.id);
  }

  /// Records the week as READ the moment its poster is opened, whichever door
  /// the reader came through.
  ///
  /// It lives here rather than at each call site because the Monday popup's
  /// button used to be the ONLY thing that wrote `viewedAt`: a reader who
  /// opened their week from the Library banner instead was offered the same
  /// popup again every morning until Sunday, and the banner's "MỚI" pill —
  /// which keys off the same stamp — never went out at all. A fifth entry point
  /// added later must not have to remember this.
  ///
  /// Scoped to the CURRENT week. A recap pulled out of Sổ tay is history being
  /// re-read; its stamps were written the week it was live and re-stamping them
  /// would be a lie about when it was seen.
  void _markViewedIfCurrent(String id) {
    if (id.isEmpty || state.current?.id != id) return;

    unawaited(markInteracted(viewed: true));
  }

  /// Fetches an older recap by id — the Sổ tay path, where only the tile's
  /// summary is in memory.
  Future<void> openRecapById(String id) async {
    final cached = state.current?.id == id ? state.current : null;
    emit(
      state.copyWith(
        opened: cached,
        openedStatus: cached != null ? WeekRecapStatus.success : WeekRecapStatus.loading,
        errorMessage: null,
      ),
    );
    if (cached != null) {
      _markViewedIfCurrent(id);

      return;
    }

    final result = await _getByIdUseCase(id).run();
    result.match(
      (error) {
        if (isClosed) return;
        emit(state.copyWith(openedStatus: WeekRecapStatus.failure, errorMessage: error.toString()));
      },
      (data) {
        if (isClosed) return;
        emit(state.copyWith(opened: data, openedStatus: WeekRecapStatus.success, errorMessage: null));
        _markViewedIfCurrent(id);
      },
    );
  }

  /// "Xem hành trình" / "Để sau".
  ///
  /// Viewing ends the Monday popup for good. "Để sau" mutes it only for today —
  /// the server MOVES `dismissedAt` on every press, so tomorrow's first open
  /// re-offers the week until it is actually viewed.
  ///
  /// The local stamp is applied FIRST and kept even if the call fails: the
  /// learner has answered, and a failed POST must not make the popup reappear
  /// on the next screen. The server is corrected on the next `loadCurrent`.
  Future<void> markInteracted({required bool viewed}) async {
    final recap = state.current;
    // Once viewed there is nothing left to stamp either way; an id-less recap
    // is the debug preview, which has no document to stamp against.
    if (recap == null || recap.id.isEmpty || recap.viewedAt != null) return;

    final now = DateTime.now();
    final dismissed = recap.dismissedAt;
    if (!viewed && dismissed != null && DateUtils.isSameDay(dismissed, now)) return;

    emit(
      state.copyWith(
        current: viewed ? recap.copyWith(viewedAt: now) : recap.copyWith(dismissedAt: now),
      ),
    );

    await _markInteractedUseCase(id: recap.id, viewed: viewed).run();
  }
}
