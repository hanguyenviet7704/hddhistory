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
  final GetCommunityChatMessageContextUseCase _contextUseCase;
  final GetCommunityChatGuideUseCase _guideUseCase;
  final ReportCommunityItemUseCase _reportUseCase;

  CommunityChatCubit(
    this._getRoomUseCase,
    this._getMessagesUseCase,
    this._sendUseCase,
    this._likeUseCase,
    this._memberStatusUseCase,
    this._contextUseCase,
    this._guideUseCase,
    this._reportUseCase,
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

  /// How long a jumped-to message wears the violet ring.
  ///
  /// The design's own number. Long enough to find the line with your eye after
  /// the scroll settles, short enough that it is gone before it becomes part of
  /// how the message looks.
  static const Duration _flashDuration = Duration(milliseconds: 1900);

  String _room = '';
  Timer? _poll;
  Timer? _cooldown;
  Timer? _flash;

  @override
  Future<void> close() {
    _poll?.cancel();
    _cooldown?.cancel();
    _flash?.cancel();
    return super.close();
  }

  Future<void> open(String room) async {
    _room = room;
    emit(state.copyWith(status: CommunityStatus.loading));

    await Future.wait([
      _loadRoom(),
      _loadPage(reset: true),
      _refreshMemberStatus(),
      _loadGuide(),
    ]);

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

  /// The house rules, read once per room opening.
  ///
  /// Fetched up front rather than when the info button is tapped, because the
  /// button's very presence depends on the answer: with nothing authored there
  /// is no button, which is better than one that opens an empty sheet.
  Future<void> _loadGuide() {
    return runUseCase<CommunityChatGuideEntity?>(
      usecase: () => _guideUseCase(),
      onFailure: (_) {},
      onSuccess: (guide) => emit(state.copyWith(guide: guide)),
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
            // Only page 1 carries the pins. Assigning on page 2 would wipe the
            // bar the moment the reader scrolled up into history.
            pinned: page <= 1 ? result.pinned : state.pinned,
            // A reset is a return to the live bottom by definition.
            isInHistory: reset ? false : state.isInHistory,
          ),
        );
      },
    );
  }

  /// Re-opens the room after a failed load.
  ///
  /// The room is held privately, so without this the screen has no way to ask
  /// again — and a chat that fails to open with no retry is a dead end.
  Future<void> retry() {
    if (_room.isEmpty) return Future.value();

    return open(_room);
  }

  /// Older history, above what is on screen.
  ///
  /// Two different walks, because a jumped-to WINDOW has no page number to
  /// increment: inside one, older history is fetched by asking for the context
  /// of the oldest line currently held, and merged by id.
  Future<void> loadOlder() async {
    if (state.isLoadingMore || !state.hasMore) return;
    emit(state.copyWith(isLoadingMore: true));

    if (state.isInHistory) {
      await _loadOlderInWindow();
      return;
    }

    await _loadPage(reset: false);
  }

  Future<void> _loadOlderInWindow() async {
    final oldest = state.messages.firstOrNull;
    if (oldest == null || oldest.id.isEmpty) {
      emit(state.copyWith(isLoadingMore: false, windowHasOlder: false));
      return;
    }

    await runUseCase<CommunityChatContextEntity>(
      usecase: () => _contextUseCase(room: _room, messageId: oldest.id),
      onFailure: (_) => emit(state.copyWith(isLoadingMore: false)),
      onSuccess: (context) => emit(
        state.copyWith(
          isLoadingMore: false,
          // Dedup by id: the window is centred on a line already on screen, so
          // its newer half is entirely made of messages we are holding.
          messages: _dedupe([...context.items, ...state.messages]),
          windowHasOlder: context.hasOlder,
        ),
      ),
    );
  }

  /// Takes the reader to a message, wherever it is in the room's history.
  ///
  /// Already on screen: scroll and flash, no request. Otherwise the server
  /// answers with a window around it and the list is REPLACED by that window —
  /// the pin being tapped can be months old, and paging back to it would be
  /// dozens of requests with an unbounded worst case.
  Future<void> jumpToMessage(String messageId) async {
    if (messageId.isEmpty || state.isJumping) return;

    if (state.messages.any((message) => message.id == messageId)) {
      flashMessage(messageId);
      return;
    }

    emit(state.copyWith(isJumping: true));

    await runUseCase<CommunityChatContextEntity>(
      usecase: () => _contextUseCase(room: _room, messageId: messageId),
      onFailure: (message) =>
          emit(state.copyWith(isJumping: false, errorMessage: message)),
      onSuccess: (context) {
        emit(
          state.copyWith(
            isJumping: false,
            // Server order is newest-first; the screen reads top to bottom.
            messages: context.items.reversed.toList(),
            // Only a window that stops short of the newest line is "history".
            // One that reaches the bottom IS the live transcript, so polling
            // may go on merging into it and no way back is needed.
            isInHistory: context.hasNewer,
            windowHasOlder: context.hasOlder,
          ),
        );
        flashMessage(messageId);
      },
    );
  }

  /// Back to the running transcript after a jump into history.
  Future<void> backToLatest() async {
    _flash?.cancel();
    emit(state.copyWith(flashedMessageId: null, isInHistory: false));

    await _loadPage(reset: true);
  }

  /// The violet ring, for the design's 1900ms.
  ///
  /// Public because the screen also calls it for a tap on the pin bar when the
  /// message is already drawn — there is nothing to fetch then, only to point
  /// at.
  void flashMessage(String messageId) {
    _flash?.cancel();
    emit(state.copyWith(flashedMessageId: messageId));

    _flash = Timer(_flashDuration, () {
      if (isClosed) return;
      emit(state.copyWith(flashedMessageId: null));
    });
  }


  /// Re-marks the lines on screen against a fresh pin list.
  List<CommunityChatMessageEntity> _applyPinFlags(
    List<CommunityChatMessageEntity> pinned,
  ) {
    final pinnedIds = pinned.map((message) => message.id).toSet();

    return state.messages
        .map((message) => message.copyWith(isPinned: pinnedIds.contains(message.id)))
        .toList();
  }

  List<CommunityChatMessageEntity> _dedupe(
    Iterable<CommunityChatMessageEntity> rows,
  ) {
    final byId = <String, CommunityChatMessageEntity>{};
    for (final message in rows) {
      if (message.id.isEmpty) continue;
      byId[message.id] = message;
    }

    return byId.values.toList()
      ..sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
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
        onSuccess: (result) => emit(
          state.copyWith(
            // The pin bar stays live for everyone even while reading history:
            // another admin's pin lands here with no request of its own.
            pinned: result.pinned,
            // But the TRANSCRIPT is left alone while the reader is in a window
            // from last month. Merging today's lines into it would draw a
            // conversation that never happened.
            messages: state.isInHistory
                ? _applyPinFlags(result.pinned)
                : _merge(result.items.reversed),
          ),
        ),
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

    final replyTo = state.replyTarget;
    final pending = CommunityChatMessageEntity(
      body: text,
      isMine: true,
      isPending: true,
      createdAt: DateTime.now(),
      // Drawn on the optimistic bubble too, so the quote does not pop in a
      // beat later than the words it belongs to.
      replyTo: replyTo == null
          ? null
          : CommunityChatReplyEntity(
              id: replyTo.id,
              author: replyTo.author,
              body: replyTo.body,
            ),
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
      usecase: () => _sendUseCase(
        room: _room,
        body: text,
        replyToId: replyTo?.id.isEmpty ?? true ? null : replyTo!.id,
      ),
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
        emit(
          state.copyWith(
            isSending: false,
            messages: _merge([message]),
            // Cleared only once the line has actually landed: a failed send
            // leaves the quote up so the retry still answers the same message.
            replyTarget: null,
          ),
        );
        _startCooldown();
      },
    );

    return sent;
  }

  /// Answer one line. The composer grows a quote strip above it.
  void startReply(CommunityChatMessageEntity message) {
    if (message.id.isEmpty) return;
    emit(state.copyWith(replyTarget: message));
  }

  void cancelReply() => emit(state.copyWith(replyTarget: null));

  /// Report a chat line — the same queue a reported post goes to.
  ///
  /// Post-moderation: nothing disappears on the reporter's say-so, so the
  /// screen's confirmation says the team will look rather than implying the
  /// line has gone.
  Future<bool> reportMessage(
    CommunityChatMessageEntity message,
    CommunityReportReason reason,
  ) async {
    if (message.id.isEmpty) return false;

    var reported = false;
    await runUseCase<Unit>(
      usecase: () => _reportUseCase(
        targetType: CommunityTargetType.chatMessage,
        targetId: message.id,
        reason: reason,
      ),
      onFailure: (error) => emit(state.copyWith(errorMessage: error)),
      onSuccess: (_) => reported = true,
    );

    return reported;
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
