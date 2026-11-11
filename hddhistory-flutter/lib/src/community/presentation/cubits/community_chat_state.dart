part of '../../community.dart';

/// One open group chat room (design `S-03 · Hội bàn tròn`).
@freezed
abstract class CommunityChatState with _$CommunityChatState {
  const factory CommunityChatState({
    @Default(CommunityStatus.initial) CommunityStatus status,
    CommunityChatRoomEntity? room,

    /// OLDEST first — the order the screen draws them top to bottom. The API
    /// answers newest-first because that is what pagination needs; the cubit
    /// flips each page as it merges it.
    @Default(<CommunityChatMessageEntity>[]) List<CommunityChatMessageEntity> messages,
    @Default(1) int currentPage,
    @Default(1) int totalPages,
    @Default(false) bool isLoadingMore,
    @Default(false) bool isSending,

    /// A short pause after a line lands, so a hand on the send button cannot
    /// fire ten requests — and so an ordinary conversation never reaches the
    /// server's own flood ceiling.
    @Default(false) bool isCoolingDown,
    @Default(CommunityMemberStatusEntity()) CommunityMemberStatusEntity memberStatus,

    /// The room's pinned lines, NEWEST PIN FIRST — the bar draws the first one
    /// and the sheet lists them all. Carried by page 1 of the transcript, so
    /// the poll that already runs keeps them current.
    @Default(<CommunityChatMessageEntity>[]) List<CommunityChatMessageEntity> pinned,

    /// The house rules, or null when none are written — the header then has no
    /// info button rather than one that opens an empty sheet.
    CommunityChatGuideEntity? guide,

    /// The message wearing the violet ring right now, for the ~2s after a jump.
    String? flashedMessageId,

    /// The list is a WINDOW pulled from history, not the live bottom.
    ///
    /// Set when a jump lands somewhere with newer messages after it. While it
    /// holds, the poll must not merge page 1 in — mixing last month's window
    /// with today's lines would draw a transcript that never happened — and the
    /// screen offers the way back to the bottom instead.
    @Default(false) bool isInHistory,

    /// Whether that window has more history before it. Paging inside a window
    /// cannot use page numbers, so this replaces [hasMore] while in history.
    @Default(false) bool windowHasOlder,
    @Default(false) bool isJumping,

    /// The line the composer is answering, null when writing a fresh message.
    /// Held as the whole message, not an id: the quote strip above the composer
    /// draws the author and the text.
    CommunityChatMessageEntity? replyTarget,
    String? errorMessage,
  }) = _CommunityChatState;

  factory CommunityChatState.initial() => const CommunityChatState();
}

extension CommunityChatStateX on CommunityChatState {
  bool get hasMore =>
      isInHistory ? windowHasOlder : currentPage < totalPages;

  bool get canSend => memberStatus.canPost;

  /// The line the pin bar shows: the most recently PINNED one, which is not
  /// the most recently written one as soon as somebody pins an old message.
  CommunityChatMessageEntity? get latestPinned =>
      pinned.isEmpty ? null : pinned.first;

  /// Something worth opening. A row with only a locale on it is what an
  /// accidental save in the panel leaves behind, and the info button must not
  /// appear for that.
  bool get hasGuide =>
      (guide?.title.isNotEmpty ?? false) ||
      (guide?.dos.isNotEmpty ?? false) ||
      (guide?.donts.isNotEmpty ?? false) ||
      (guide?.starters.isNotEmpty ?? false);
}
