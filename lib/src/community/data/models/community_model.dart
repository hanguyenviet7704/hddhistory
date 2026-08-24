part of '../../community.dart';

@freezed
abstract class CommunityAuthorModel with _$CommunityAuthorModel {
  const factory CommunityAuthorModel({
    @Default('') String id,
    @Default('') String name,
    String? avatar,
    @Default('USER') String authorType,
  }) = _CommunityAuthorModel;

  factory CommunityAuthorModel.fromJson(Map<String, dynamic> json) => _$CommunityAuthorModelFromJson(json);
}

@freezed
abstract class CommunityPostTopicModel with _$CommunityPostTopicModel {
  const factory CommunityPostTopicModel({
    @Default('') String id,
    @Default('') String name,
  }) = _CommunityPostTopicModel;

  factory CommunityPostTopicModel.fromJson(Map<String, dynamic> json) => _$CommunityPostTopicModelFromJson(json);
}

@freezed
abstract class CommunityPostModel with _$CommunityPostModel {
  const factory CommunityPostModel({
    @Default('') String id,
    @Default('POST') String type,
    @Default(CommunityAuthorModel()) CommunityAuthorModel author,
    CommunityPostTopicModel? topic,
    @Default('') String body,
    @Default(<String>[]) List<String> images,
    String? attachedCourseId,
    @Default(false) bool isPinned,
    @Default(false) bool commentsLocked,
    @Default(0) int likeCount,
    @Default(0) int commentCount,
    @Default(0) int saveCount,
    @Default(false) bool isLiked,
    @Default(false) bool isSaved,
    @Default(false) bool isMine,
    String? createdAt,
  }) = _CommunityPostModel;

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) => _$CommunityPostModelFromJson(json);
}

@freezed
abstract class CommunityWeeklyModel with _$CommunityWeeklyModel {
  const factory CommunityWeeklyModel({
    @Default('') String id,
    @Default('') String title,
    @Default('') String note,
    int? weekNumber,
    int? year,
    String? startsAt,
    String? endsAt,
    @Default(0) int answerCount,
  }) = _CommunityWeeklyModel;

  factory CommunityWeeklyModel.fromJson(Map<String, dynamic> json) => _$CommunityWeeklyModelFromJson(json);
}

/// The feed response: page 1 carries the pinned posts and the open weekly
/// question, later pages only the list.
@freezed
abstract class CommunityFeedModel with _$CommunityFeedModel {
  const factory CommunityFeedModel({
    String? anchorAt,
    CommunityWeeklyModel? weekly,
    @Default(<CommunityPostModel>[]) List<CommunityPostModel> pinned,
    @Default(<CommunityPostModel>[]) List<CommunityPostModel> items,
    @Default(0) int currentPage,
    @Default(0) int totalPages,
    @Default(0) int itemsPerPage,
  }) = _CommunityFeedModel;

  factory CommunityFeedModel.fromJson(Map<String, dynamic> json) => _$CommunityFeedModelFromJson(json);
}

@freezed
abstract class CommunityTopicModel with _$CommunityTopicModel {
  const factory CommunityTopicModel({
    @Default('') String id,
    @Default('') String name,
    @Default('') String description,
    @Default('') String slug,
    String? imageUrl,
    @Default(0) int followers,
    @Default(0) int postsThisWeek,
    @Default(false) bool isFollowing,
  }) = _CommunityTopicModel;

  factory CommunityTopicModel.fromJson(Map<String, dynamic> json) => _$CommunityTopicModelFromJson(json);
}

@freezed
abstract class CommunityTopicListModel with _$CommunityTopicListModel {
  const factory CommunityTopicListModel({
    @Default(<CommunityTopicModel>[]) List<CommunityTopicModel> following,
    @Default(<CommunityTopicModel>[]) List<CommunityTopicModel> all,
  }) = _CommunityTopicListModel;

  factory CommunityTopicListModel.fromJson(Map<String, dynamic> json) => _$CommunityTopicListModelFromJson(json);
}

@freezed
abstract class CommunityCommentModel with _$CommunityCommentModel {
  const factory CommunityCommentModel({
    @Default('') String id,
    @Default(CommunityAuthorModel()) CommunityAuthorModel author,
    @Default('') String body,
    @Default(0) int likeCount,
    @Default(0) int replyCount,
    @Default(false) bool isLiked,
    @Default(false) bool isMine,
    String? replyToName,
    String? createdAt,
    @Default(<CommunityCommentModel>[]) List<CommunityCommentModel> replies,
  }) = _CommunityCommentModel;

  factory CommunityCommentModel.fromJson(Map<String, dynamic> json) => _$CommunityCommentModelFromJson(json);
}

@freezed
abstract class CommunityCommentPageModel with _$CommunityCommentPageModel {
  const factory CommunityCommentPageModel({
    @Default(<CommunityCommentModel>[]) List<CommunityCommentModel> items,
    @Default(0) int currentPage,
    @Default(0) int totalPages,
    @Default(0) int itemsPerPage,
  }) = _CommunityCommentPageModel;

  factory CommunityCommentPageModel.fromJson(Map<String, dynamic> json) => _$CommunityCommentPageModelFromJson(json);
}

@freezed
abstract class CommunityNotificationModel with _$CommunityNotificationModel {
  const factory CommunityNotificationModel({
    @JsonKey(name: '_id') @Default('') String id,
    @Default('') String type,
    String? actorId,
    String? postId,
    String? commentId,
    @Default(false) bool isRead,
    String? createdAt,
  }) = _CommunityNotificationModel;

  factory CommunityNotificationModel.fromJson(Map<String, dynamic> json) => _$CommunityNotificationModelFromJson(json);
}

@freezed
abstract class CommunityNotificationPageModel with _$CommunityNotificationPageModel {
  const factory CommunityNotificationPageModel({
    @Default(<CommunityNotificationModel>[]) List<CommunityNotificationModel> items,
    @Default(0) int currentPage,
    @Default(0) int totalPages,
    @Default(0) int itemsPerPage,
    @Default(0) int unreadCount,
  }) = _CommunityNotificationPageModel;

  factory CommunityNotificationPageModel.fromJson(Map<String, dynamic> json) => _$CommunityNotificationPageModelFromJson(json);
}

/// Why the composer may be closed: a guest who has to sign in, or a member
/// whose posting is suspended.
@freezed
abstract class CommunityMemberStatusModel with _$CommunityMemberStatusModel {
  const factory CommunityMemberStatusModel({
    @Default(true) bool canPost,
    @Default(false) bool requiresLogin,
    String? reason,
    String? mutedUntil,
  }) = _CommunityMemberStatusModel;

  factory CommunityMemberStatusModel.fromJson(Map<String, dynamic> json) => _$CommunityMemberStatusModelFromJson(json);
}

@freezed
abstract class CommunitySavedPageModel with _$CommunitySavedPageModel {
  const factory CommunitySavedPageModel({
    @Default(<CommunityPostModel>[]) List<CommunityPostModel> items,
    @Default(0) int currentPage,
    @Default(0) int totalPages,
    @Default(0) int itemsPerPage,
  }) = _CommunitySavedPageModel;

  factory CommunitySavedPageModel.fromJson(Map<String, dynamic> json) => _$CommunitySavedPageModelFromJson(json);
}


@freezed
abstract class CommunityUnreadCountModel with _$CommunityUnreadCountModel {
  const factory CommunityUnreadCountModel({@Default(0) int count}) =
      _CommunityUnreadCountModel;

  factory CommunityUnreadCountModel.fromJson(Map<String, dynamic> json) =>
      _$CommunityUnreadCountModelFromJson(json);
}
