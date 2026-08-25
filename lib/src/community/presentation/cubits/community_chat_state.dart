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
    @Default(CommunityMemberStatusEntity()) CommunityMemberStatusEntity memberStatus,
    String? errorMessage,
  }) = _CommunityChatState;

  factory CommunityChatState.initial() => const CommunityChatState();
}

extension CommunityChatStateX on CommunityChatState {
  bool get hasMore => currentPage < totalPages;

  bool get canSend => memberStatus.canPost;
}
