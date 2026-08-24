part of '../../community.dart';

enum CommunityStatus { initial, loading, success, failure }

/// The two tabs on the community hub, plus the topic-scoped feed.
enum CommunityFeedScope { all, following }

@freezed
abstract class CommunityFeedState with _$CommunityFeedState {
  const factory CommunityFeedState({
    @Default(CommunityStatus.initial) CommunityStatus status,
    @Default(CommunityFeedScope.all) CommunityFeedScope scope,

    /// Pinned posts and the weekly question ride along with page 1 only.
    @Default(<CommunityPostEntity>[]) List<CommunityPostEntity> pinned,
    @Default(<CommunityPostEntity>[]) List<CommunityPostEntity> posts,
    CommunityWeeklyEntity? weekly,

    /// Stamped by page 1 and sent back on later pages so a post written
    /// mid-scroll cannot land on two pages at once.
    DateTime? anchorAt,
    @Default(1) int currentPage,
    @Default(1) int totalPages,
    @Default(false) bool isLoadingMore,

    /// The chip strip on the hub.
    @Default(CommunityStatus.initial) CommunityStatus topicsStatus,
    @Default(CommunityTopicListEntity()) CommunityTopicListEntity topics,

    /// Whether this reader may write, and why not.
    @Default(CommunityMemberStatusEntity()) CommunityMemberStatusEntity memberStatus,
    @Default(0) int unreadNotifications,
    String? errorMessage,
  }) = _CommunityFeedState;

  factory CommunityFeedState.initial() => const CommunityFeedState();
}

extension CommunityFeedStateX on CommunityFeedState {
  bool get hasMore => currentPage < totalPages;

  bool get isEmpty =>
      status == CommunityStatus.success && posts.isEmpty && pinned.isEmpty;

  /// The "following" tab with nothing followed yet is a different empty state
  /// from a followed-but-quiet one: the fix is to follow a topic, not to wait.
  bool get isFollowingNothing =>
      scope == CommunityFeedScope.following && topics.following.isEmpty;
}
