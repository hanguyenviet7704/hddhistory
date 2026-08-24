part of '../../community.dart';

/// The community inbox: who replied to what.
@injectable
class CommunityNotificationCubit extends Cubit<CommunityNotificationState> {
  final GetCommunityNotificationsUseCase _getNotificationsUseCase;
  final MarkCommunityNotificationsReadUseCase _markReadUseCase;

  CommunityNotificationCubit(
    this._getNotificationsUseCase,
    this._markReadUseCase,
  ) : super(CommunityNotificationState.initial());

  static const int _pageSize = 20;

  Future<void> load({bool reset = true}) async {
    final page = reset ? 1 : state.currentPage + 1;

    if (reset) {
      emit(state.copyWith(status: CommunityStatus.loading));
    } else {
      if (state.isLoadingMore || !state.hasMore) return;
      emit(state.copyWith(isLoadingMore: true));
    }

    final result = await _getNotificationsUseCase(page: page, take: _pageSize).run();

    result.fold(
      (exception) => emit(
        state.copyWith(
          status: CommunityStatus.failure,
          isLoadingMore: false,
          errorMessage: exception.message,
        ),
      ),
      (data) => emit(
        state.copyWith(
          status: CommunityStatus.success,
          items: reset ? data.items : [...state.items, ...data.items],
          currentPage: data.currentPage == 0 ? page : data.currentPage,
          totalPages: data.totalPages == 0 ? 1 : data.totalPages,
          unreadCount: data.unreadCount,
          isLoadingMore: false,
        ),
      ),
    );
  }

  /// Marks everything read when the inbox is opened.
  ///
  /// The badge is cleared locally first: the reader has just looked at the list,
  /// so leaving the dot up while a request flies reads as the app not noticing.
  Future<void> markAllRead() async {
    if (state.unreadCount == 0) return;

    emit(
      state.copyWith(
        unreadCount: 0,
        items: state.items.map((item) => item.copyWith(isRead: true)).toList(),
      ),
    );

    await _markReadUseCase().run();
  }
}
