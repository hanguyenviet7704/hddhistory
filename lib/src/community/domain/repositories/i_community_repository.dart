part of '../../community.dart';

abstract interface class ICommunityRepository {
  TaskEither<AppException, CommunityFeedEntity> getFeed({
    required int page,
    int take,
    String? topicId,
    bool followingOnly,
    CommunityFeedSort sort,
    DateTime? anchorAt,
  });

  TaskEither<AppException, CommunityTopicListEntity> getTopics();

  TaskEither<AppException, CommunityTopicEntity> getTopic(String id);

  TaskEither<AppException, Unit> setTopicFollow({
    required String topicId,
    required bool follow,
  });

  TaskEither<AppException, CommunityPostEntity> getPost(String id);

  TaskEither<AppException, CommunityPostEntity> createPost({
    required String body,
    String? topicId,
    List<String>? images,
    String? attachedCourseId,
  });

  TaskEither<AppException, Unit> deletePost(String id);

  TaskEither<AppException, CommunityCommentPageEntity> getComments({
    required String postId,
    required int page,
    int take,
  });

  TaskEither<AppException, CommunityCommentPageEntity> createComment({
    required String postId,
    required String body,
    String? parentId,
    String? replyToUserId,
  });

  TaskEither<AppException, Unit> deleteComment(String id);

  TaskEither<AppException, Unit> setReaction({
    required CommunityTargetType targetType,
    required String targetId,
    required CommunityReactionKind kind,
    required bool active,
  });

  TaskEither<AppException, Unit> hideItem({
    required CommunityTargetType targetType,
    required String targetId,
  });

  TaskEither<AppException, Unit> report({
    required CommunityTargetType targetType,
    required String targetId,
    required CommunityReportReason reason,
    String? note,
  });

  TaskEither<AppException, BasePageBreak<CommunityPostEntity>> getSavedPosts({
    required int page,
    int take,
  });

  /// Null when no question is open this week.
  TaskEither<AppException, CommunityWeeklyEntity?> getWeekly();

  TaskEither<AppException, CommunityNotificationPageEntity> getNotifications({
    required int page,
    int take,
  });

  /// Just the badge number.
  TaskEither<AppException, int> getUnreadNotificationCount();

  TaskEither<AppException, Unit> markNotificationsRead({List<String>? ids});

  TaskEither<AppException, CommunityMemberStatusEntity> getMemberStatus();
}
