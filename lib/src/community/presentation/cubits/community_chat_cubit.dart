part of '../../community.dart';

/// Drives one group chat room.
///
/// A factory, not a singleton: the room is opened and closed, and a stale cubit
/// would keep polling a screen nobody is on.
@injectable
class CommunityChatCubit extends Cubit<CommunityChatState>
    with CubitUseCaseHandlerMixin<CommunityChatState> {
  final GetCommunityChatRoomUseCase _getRoomUseCase;
  final GetCommunityChatMessagesUseCase _getMessagesUseCase;
  final SendCommunityChatMessageUseCase _sendUseCase;
  final LikeCommunityChatMessageUseCase _likeUseCase;
  final GetCommunityMemberStatusUseCase _memberStatusUseCase;

  CommunityChatCubit(
    this._getRoomUseCase,
    this._getMessagesUseCase,
    this._sendUseCase,
    this._likeUseCase,
    this._memberStatusUseCase,
  ) : super(CommunityChatState.initial());

  static const int _pageSize = 30;

  /// How often the room re-checks for new lines.
  ///
  /// Polling, not a socket. The gateway this app already runs is the AI
  /// streaming one, and pointing a chat at it means adding events to a
  /// connection Output Practice depends on. Six seconds reads as live in a
  /// conversation and costs one small request; moving to sockets later changes
  /// only what calls [_pull].
  static const Duration _pollInterval = Duration(seconds: 6);

  /// The pause after a line lands.
  ///
  /// Two seconds against the server's twenty lines a minute: enough that a
  /// button held down cannot flood the room, short enough that nobody typing at
  /// human speed ever notices it. The ceiling itself stays server-side — this is
  /// only what keeps an ordinary conversation from tripping it.
  static const Duration _sendCooldown = Duration(seconds: 2);

  String _room = '';
  Timer? _poll;
  Timer? _cooldown;

  @override
  Future<void> close() {
    _poll?.cancel();
    _cooldown?.cancel();
    return super.close();
  }

  Future<void> open(String room) async {
    _room = room;
    emit(state.copyWith(status: CommunityStatus.loading));

    await Future.wait([_loadRoom(), _loadPage(reset: true), _refreshMemberStatus()]);

    _poll?.cancel();
    _poll = Timer.periodic(_pollInterval, (_) => _pull());
  }

  Future<void> _loadRoom() {
    return runUseCase<CommunityChatRoomEntity>(
      usecase: () => _getRoomUseCase(_room),
      onFailure: (message) => emit(
        state.copyWith(status: CommunityStatus.failure, errorMessage: message),
      ),
      onSuccess: (room) => emit(state.copyWith(room: room)),
    );
  }

  Future<void> _refreshMemberStatus() {
    return runUseCase<CommunityMemberStatusEntity>(
      usecase: () => _memberStatusUseCase(),
      onFailure: (_) {},
      onSuccess: (status) => emit(state.copyWith(memberStatus: status)),
    );
  }

  Future<void> _loadPage({required bool reset}) {
    final page = reset ? 1 : state.currentPage + 1;

    return runUseCase<CommunityChatPageEntity>(
      usecase: () => _getMessagesUseCase(room: _room, page: page, take: _pageSize),
      onFailure: (message) => emit(
        state.copyWith(
          status: CommunityStatus.failure,
          isLoadingMore: false,
          errorMessage: message,
        ),
      ),
      onSuccess: (result) {
        // The API hands back newest-first; the screen reads top to bottom, so
        // each page is flipped and older pages go ABOVE what is already there.
        final incoming = result.items.reversed.toList();

        emit(
          state.copyWith(
            status: CommunityStatus.success,
            isLoadingMore: false,
            messages: reset ? incoming : [...incoming, ...state.messages],
            currentPage: result.currentPage,
            totalPages: result.totalPages,
          ),
        );
      },
    );
  }

  /// Older history, above what is on screen.
  Future<void> loadOlder() async {
    if (state.isLoadingMore || !state.hasMore) return;
    emit(state.copyWith(isLoadingMore: true));

    await _loadPage(reset: false);
  }

  /// The poll tick: only ever the newest page, merged by id.
  ///
  /// Re-fetching page 1 rather than asking "since when" keeps the read marker
  /// and the online count fresh in the same round trip, and the page is small.
  Future<void> _pull() async {
    if (isClosed) return;

    await Future.wait([
      _loadRoom(),
      runUseCase<CommunityChatPageEntity>(
        usecase: () => _getMessagesUseCase(room: _room, page: 1, take: _pageSize),
        onFailure: (_) {},
        onSuccess: (result) => emit(state.copyWith(messages: _merge(result.items.reversed))),
      ),
    ]);
  }

  /// Merges a fresh newest page into what is on screen.
  ///
  /// Keyed by id so a line the reader already has is not duplicated, and so the
  /// optimistic copy of their own message is replaced rather than doubled — the
  /// pending row carries no server id, so it is dropped once a real message with
  /// the same body and author arrives.
  List<CommunityChatMessageEntity> _merge(Iterable<CommunityChatMessageEntity> fresh) {
    final byId = <String, CommunityChatMessageEntity>{};
    for (final message in [...state.messages, ...fresh]) {
      if (message.isPending) continue;
      byId[message.id] = message;
    }

    final settled = byId.values.toList()
      ..sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));

    // Anything still un-acknowledged stays at the bottom where it was typed.
    final pending = state.messages.where(
      (message) => message.isPending && !settled.any((row) => row.body == message.body),
    );

    return [...settled, ...pending];
  }

  /// Sends, showing the line immediately.
  ///
  /// The optimistic row is what makes the room feel like a chat rather than a
  /// form: a six-second poll would otherwise be the soonest a reader sees their
  /// own words.
  Future<bool> send(String body) async {
    final text = body.trim();
    if (text.isEmpty || state.isSending || state.isCoolingDown) return false;

    final pending = CommunityChatMessageEntity(
      body: text,
      isMine: true,
      isPending: true,
      createdAt: DateTime.now(),
    );
    emit(
      state.copyWith(
        isSending: true,
        messages: [...state.messages, pending],
        // Cleared so a `false` from this call means THIS line was refused.
        errorMessage: null,
      ),
    );

    var sent = false;
    await runUseCase<CommunityChatMessageEntity>(
      usecase: () => _sendUseCase(room: _room, body: text),
      onFailure: (message) => emit(
        state.copyWith(
          isSending: false,
          // Drop the optimistic row: leaving it would tell the reader something
          // was said when it was not.
          messages: state.messages.where((row) => !row.isPending).toList(),
          errorMessage: message,
        ),
      ),
      onSuccess: (message) {
        sent = true;
        emit(state.copyWith(isSending: false, messages: _merge([message])));
        _startCooldown();
      },
    );

    return sent;
  }

  void _startCooldown() {
    _cooldown?.cancel();
    emit(state.copyWith(isCoolingDown: true));

    _cooldown = Timer(_sendCooldown, () {
      if (isClosed) return;
      emit(state.copyWith(isCoolingDown: false));
    });
  }

  Future<void> toggleLike(CommunityChatMessageEntity message) async {
    if (message.id.isEmpty) return;

    await runUseCase<({bool isLiked, int likeCount})>(
      usecase: () => _likeUseCase(message.id),
      onFailure: (_) {},
      onSuccess: (result) => emit(
        state.copyWith(
          messages: state.messages
              .map(
                (row) => row.id == message.id
                    ? row.copyWith(isLiked: result.isLiked, likeCount: result.likeCount)
                    : row,
              )
              .toList(),
        ),
      ),
    );
  }
}
