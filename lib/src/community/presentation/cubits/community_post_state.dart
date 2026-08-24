part of '../../community.dart';

/// One open post — or the weekly question, which is a post with a different
/// header. Both use this state and the same comment machinery.
@freezed
abstract class CommunityPostState with _$CommunityPostState {
  const factory CommunityPostState({
    @Default(CommunityStatus.initial) CommunityStatus status,
    CommunityPostEntity? post,

    /// Set instead of [post] when the screen was opened for the weekly
    /// question.
    CommunityWeeklyEntity? weekly,
    @Default(CommunityStatus.initial) CommunityStatus commentsStatus,
    @Default(<CommunityCommentEntity>[]) List<CommunityCommentEntity> comments,
    @Default(1) int currentPage,
    @Default(1) int totalPages,
    @Default(false) bool isLoadingMore,
    @Default(false) bool isSubmitting,

    /// The comment being replied to, which pins the "Đang trả lời X" strip above
    /// the composer.
    CommunityCommentEntity? replyTarget,
    @Default(CommunityMemberStatusEntity()) CommunityMemberStatusEntity memberStatus,
    String? errorMessage,
  }) = _CommunityPostState;

  factory CommunityPostState.initial() => const CommunityPostState();
}

extension CommunityPostStateX on CommunityPostState {
  bool get hasMore => currentPage < totalPages;

  bool get isWeekly => weekly != null;

  /// Locked by a moderator, or closed because the weekly window has passed.
  bool get canComment {
    if (!memberStatus.canPost) return false;
    if (weekly != null) return weekly!.isOpen;

    return !(post?.commentsLocked ?? false);
  }

  int get answerCount => weekly?.answerCount ?? post?.commentCount ?? 0;
}


/// What the post-detail screen hands back when it closes.
///
/// A plain updated post is not enough: the reader can also delete or hide the
/// post from in there, and the list behind has to drop the row rather than
/// re-render the copy it still holds.
class CommunityPostScreenResult {
  const CommunityPostScreenResult({this.post, this.removed = false});

  final CommunityPostEntity? post;

  /// Deleted by its author, or hidden for this reader.
  final bool removed;
}
