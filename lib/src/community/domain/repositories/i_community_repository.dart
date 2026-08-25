part of '../../community.dart';

abstract interface class ICommunityRepository {
  TaskEither<AppException, CommunityFeedEntity> getFeed({
    required int page,
    int take,
    String? topicId,
    bool followedOnly,
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
    String? subject,
    String? topicId,
    List<String>? images,
    String? attachedCourseId,
    CommunityAttachedCardEntity? attachedCard,
    bool isAnonymous,
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

  TaskEither<AppException, List<CommunityRoomSuggestionEntity>> getRoomSuggestions();

  /// Files an ask, or — when the name matches one already open — turns it into
  /// a vote on that one and returns it with `mergedIntoExisting` set.
  TaskEither<AppException, CommunityRoomSuggestionEntity> createRoomSuggestion({
    required String name,
    String? description,
  });

  TaskEither<AppException, CommunityRoomSuggestionEntity> voteRoomSuggestion(
    String id,
  );

  // ------------------------------------------------------------ group chat

  TaskEither<AppException, CommunityChatRoomEntity> getChatRoom(String room);

  /// One page of the transcript, NEWEST first — page 1 is the bottom of the
  /// screen, page 2 the history above it.
  TaskEither<AppException, CommunityChatPageEntity> getChatMessages({
    required String room,
    required int page,
    int take,
  });

  TaskEither<AppException, CommunityChatMessageEntity> sendChatMessage({
    required String room,
    required String body,
  });

  /// Returns the message's new state, so the row does not have to guess.
  TaskEither<AppException, ({bool isLiked, int likeCount})> likeChatMessage(String id);
}
