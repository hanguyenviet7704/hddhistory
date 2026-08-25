part of '../../community.dart';

/// Who wrote a post or comment.
///
/// [isOfficial] drives the team badge. The name can be empty for a deleted
/// account — the UI shows its own localised placeholder rather than an id.
@freezed
abstract class CommunityAuthorEntity with _$CommunityAuthorEntity {
  const factory CommunityAuthorEntity({
    @Default('') String id,
    @Default('') String name,
    String? avatar,
    @Default(false) bool isOfficial,

    /// Written without a name. The API sends no id and no name at all for
    /// these, so the app shows its own localised placeholder — the initials
    /// fall back to a glyph rather than a letter of the real name.
    @Default(false) bool isAnonymous,
  }) = _CommunityAuthorEntity;
}

/// A saved keypoint card carried by a post, snapshotted when it was written.
///
/// Deliberately a copy rather than a keypoint id to resolve: the card renders
/// from these three strings alone, and a keypoint later edited or unpublished
/// must not blank out the post someone wrote around it. [keypointId] is only
/// for opening the real card.
@freezed
abstract class CommunityAttachedCardEntity with _$CommunityAttachedCardEntity {
  const factory CommunityAttachedCardEntity({
    @Default('') String keypointId,
    @Default('') String title,
    @Default('') String back,
    String? courseName,
  }) = _CommunityAttachedCardEntity;
}

@freezed
abstract class CommunityPostTopicEntity with _$CommunityPostTopicEntity {
  const factory CommunityPostTopicEntity({
    @Default('') String id,
    @Default('') String name,

    /// The room's thumbnail, for the post screen's header. Null on a room with
    /// no image set, where the header falls back to the tinted house glyph the
    /// rest of the app uses for a room.
    String? imageUrl,
  }) = _CommunityPostTopicEntity;
}

@freezed
abstract class CommunityPostEntity with _$CommunityPostEntity {
  const factory CommunityPostEntity({
    @Default('') String id,
    @Default(CommunityAuthorEntity()) CommunityAuthorEntity author,

    /// Null when the writer posted without picking a group.
    CommunityPostTopicEntity? topic,

    /// The headline above the story. Empty on posts written before the
    /// composer grew a title field, and the card falls back to the body then.
    @Default('') String subject,
    @Default('') String body,
    @Default(<String>[]) List<String> images,

    /// Opens the shared-roadmap screen when tapped.
    String? attachedCourseId,
    CommunityAttachedCardEntity? attachedCard,
    @Default(false) bool isPinned,
    @Default(false) bool commentsLocked,
    @Default(0) int likeCount,
    @Default(0) int commentCount,
    @Default(0) int saveCount,
    @Default(false) bool isLiked,
    @Default(false) bool isSaved,
    @Default(false) bool isMine,
    DateTime? createdAt,
  }) = _CommunityPostEntity;
}

/// The question the team asks once a week. Answers are ordinary comments.
@freezed
abstract class CommunityWeeklyEntity with _$CommunityWeeklyEntity {
  const factory CommunityWeeklyEntity({
    @Default('') String id,
    @Default('') String title,
    @Default('') String note,
    int? weekNumber,
    int? year,
    DateTime? startsAt,
    DateTime? endsAt,
    @Default(0) int answerCount,
  }) = _CommunityWeeklyEntity;
}

extension CommunityWeeklyEntityX on CommunityWeeklyEntity {
  /// Whole days left, rounded up, so the last day still reads "1 ngày" rather
  /// than "0".
  int? get daysLeft {
    final end = endsAt;
    if (end == null) return null;

    final remaining = end.difference(DateTime.now());
    if (remaining.isNegative) return 0;

    return remaining.inHours ~/ 24 + (remaining.inHours % 24 > 0 ? 1 : 0);
  }

  bool get isOpen {
    final end = endsAt;
    return end == null || end.isAfter(DateTime.now());
  }
}

@freezed
abstract class CommunityFeedEntity with _$CommunityFeedEntity {
  const factory CommunityFeedEntity({
    /// Server time stamped by page 1; later pages send it back so a post
    /// written mid-scroll cannot appear on two pages.
    DateTime? anchorAt,
    CommunityWeeklyEntity? weekly,
    @Default(<CommunityPostEntity>[]) List<CommunityPostEntity> pinned,
    @Default(<CommunityPostEntity>[]) List<CommunityPostEntity> items,
    @Default(0) int currentPage,
    @Default(0) int totalPages,
  }) = _CommunityFeedEntity;
}

extension CommunityFeedEntityX on CommunityFeedEntity {
  bool get hasMore => currentPage < totalPages;
}

@freezed
abstract class CommunityTopicEntity with _$CommunityTopicEntity {
  const factory CommunityTopicEntity({
    @Default('') String id,
    @Default('') String name,
    @Default('') String description,
    @Default('') String slug,
    String? imageUrl,
    @Default(0) int followers,
    @Default(0) int postsThisWeek,
    @Default(false) bool isFollowing,
  }) = _CommunityTopicEntity;
}

@freezed
abstract class CommunityTopicListEntity with _$CommunityTopicListEntity {
  const factory CommunityTopicListEntity({
    @Default(<CommunityTopicEntity>[]) List<CommunityTopicEntity> following,
    @Default(<CommunityTopicEntity>[]) List<CommunityTopicEntity> all,
  }) = _CommunityTopicListEntity;
}

@freezed
abstract class CommunityCommentEntity with _$CommunityCommentEntity {
  const factory CommunityCommentEntity({
    @Default('') String id,
    @Default(CommunityAuthorEntity()) CommunityAuthorEntity author,
    @Default('') String body,
    @Default(0) int likeCount,
    @Default(0) int replyCount,
    @Default(false) bool isLiked,
    @Default(false) bool isMine,

    /// Set on a reply that answers another reply — rendered as the "@name"
    /// prefix.
    String? replyToName,
    DateTime? createdAt,
    @Default(<CommunityCommentEntity>[]) List<CommunityCommentEntity> replies,
  }) = _CommunityCommentEntity;
}

@freezed
abstract class CommunityCommentPageEntity with _$CommunityCommentPageEntity {
  const factory CommunityCommentPageEntity({
    @Default(<CommunityCommentEntity>[]) List<CommunityCommentEntity> items,
    @Default(0) int currentPage,
    @Default(0) int totalPages,
  }) = _CommunityCommentPageEntity;
}

extension CommunityCommentPageEntityX on CommunityCommentPageEntity {
  bool get hasMore => currentPage < totalPages;
}

enum CommunityNotificationType {
  likeOnPost('LIKE_ON_POST'),
  commentOnPost('COMMENT_ON_POST'),
  replyToComment('REPLY_TO_COMMENT'),
  commentOnFollowedPost('COMMENT_ON_FOLLOWED_POST'),
  officialReply('OFFICIAL_REPLY'),
  postHidden('POST_HIDDEN'),
  sanctionApplied('SANCTION_APPLIED'),
  unknown('');

  const CommunityNotificationType(this.value);

  final String value;

  static CommunityNotificationType fromValue(String? value) {
    return CommunityNotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CommunityNotificationType.unknown,
    );
  }
}

@freezed
abstract class CommunityNotificationEntity with _$CommunityNotificationEntity {
  const factory CommunityNotificationEntity({
    @Default('') String id,
    @Default(CommunityNotificationType.unknown) CommunityNotificationType type,
    String? actorId,

    /// The person who acted, resolved by the API. Null on the rows that are
    /// about the reader themselves (a hidden post, a posting ban).
    CommunityAuthorEntity? actor,

    /// How many people beyond [actor] did the same thing — the "và N người
    /// khác" tail. Only ever above 0 on a like.
    @Default(0) int otherActorCount,
    String? postId,
    String? commentId,
    @Default(false) bool isRead,
    DateTime? createdAt,
  }) = _CommunityNotificationEntity;
}

enum CommunityRoomSuggestionStatus {
  pending('PENDING'),
  approved('APPROVED'),
  declined('DECLINED');

  const CommunityRoomSuggestionStatus(this.value);

  final String value;

  static CommunityRoomSuggestionStatus fromValue(String? value) {
    return CommunityRoomSuggestionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => CommunityRoomSuggestionStatus.pending,
    );
  }
}

/// A room a reader asked for. Shown under the suggest form so the next reader
/// backs this instead of filing a fifth copy of it.
@freezed
abstract class CommunityRoomSuggestionEntity with _$CommunityRoomSuggestionEntity {
  const factory CommunityRoomSuggestionEntity({
    @Default('') String id,
    @Default('') String name,
    @Default('') String description,
    @Default(CommunityRoomSuggestionStatus.pending) CommunityRoomSuggestionStatus status,
    @Default(0) int voteCount,
    @Default(false) bool hasVoted,
    @Default(false) bool isMine,
    String? topicId,

    /// The ask matched one already open, so it became a vote rather than a new
    /// row. The screen says so instead of claiming it created something.
    @Default(false) bool mergedIntoExisting,
    DateTime? createdAt,
  }) = _CommunityRoomSuggestionEntity;
}

@freezed
abstract class CommunityNotificationPageEntity with _$CommunityNotificationPageEntity {
  const factory CommunityNotificationPageEntity({
    @Default(<CommunityNotificationEntity>[]) List<CommunityNotificationEntity> items,
    @Default(0) int currentPage,
    @Default(0) int totalPages,
    @Default(0) int unreadCount,
  }) = _CommunityNotificationPageEntity;
}

/// Whether this reader may write, and why not.
///
/// Two different answers with two different UIs: a guest gets the sign-in
/// sheet, a suspended member gets the reason and the date it lifts.
@freezed
abstract class CommunityMemberStatusEntity with _$CommunityMemberStatusEntity {
  const factory CommunityMemberStatusEntity({
    @Default(true) bool canPost,
    @Default(false) bool requiresLogin,
    String? reason,
    DateTime? mutedUntil,
  }) = _CommunityMemberStatusEntity;
}

/// How a feed is ordered — the design's "Mới nhất" / "Sôi nổi" chips.
enum CommunityFeedSort {
  recent('RECENT'),
  active('ACTIVE');

  const CommunityFeedSort(this.value);

  final String value;
}

enum CommunityTargetType {
  post('POST'),
  comment('COMMENT');

  const CommunityTargetType(this.value);

  final String value;
}

enum CommunityReactionKind {
  like('LIKE'),
  save('SAVE');

  const CommunityReactionKind(this.value);

  final String value;
}

enum CommunityReportReason {
  spam('SPAM'),
  harassment('HARASSMENT'),
  adult('ADULT'),
  misinformation('MISINFORMATION'),
  privacy('PRIVACY'),
  other('OTHER');

  const CommunityReportReason(this.value);

  final String value;
}

/// The group chat room behind the Confession FAB (design `S-03`).
@freezed
abstract class CommunityChatRoomEntity with _$CommunityChatRoomEntity {
  const factory CommunityChatRoomEntity({
    @Default('') String id,
    @Default('') String slug,
    @Default('') String name,

    /// Hosted by the MeUp team — drives the brand tile in the header.
    @Default(true) bool isOfficial,

    /// Members with a heartbeat in the last few minutes, not open sockets.
    @Default(0) int onlineCount,

    /// What the FAB's badge shows.
    @Default(0) int unreadCount,
  }) = _CommunityChatRoomEntity;
}

/// One line in a chat room.
@freezed
abstract class CommunityChatMessageEntity with _$CommunityChatMessageEntity {
  const factory CommunityChatMessageEntity({
    @Default('') String id,
    @Default(CommunityAuthorEntity()) CommunityAuthorEntity author,

    /// The "Quản trị viên" pill. Stamped on the message when it was written, so
    /// it does not change under the reader when someone stops being on duty.
    @Default(false) bool isModerator,
    @Default('') String body,
    @Default(0) int likeCount,
    @Default(false) bool isLiked,
    @Default(false) bool isMine,

    /// "Đã xem", and only ever on my own message: it means somebody ELSE has
    /// read past it.
    @Default(false) bool isSeen,
    DateTime? createdAt,

    /// True while the line is only on this device — drawn immediately so the
    /// room answers a tap, then replaced by the server's copy.
    @Default(false) bool isPending,
  }) = _CommunityChatMessageEntity;
}

@freezed
abstract class CommunityChatPageEntity with _$CommunityChatPageEntity {
  const factory CommunityChatPageEntity({
    @Default(<CommunityChatMessageEntity>[]) List<CommunityChatMessageEntity> items,
    @Default(0) int currentPage,
    @Default(0) int totalPages,
  }) = _CommunityChatPageEntity;
}
