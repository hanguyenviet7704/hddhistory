part of '../../community.dart';

@LazySingleton(as: ICommunityRepository)
class CommunityRepository implements ICommunityRepository {
  final CommunityApi _api;

  CommunityRepository(this._api);

  @override
  TaskEither<AppException, CommunityFeedEntity> getFeed({
    required int page,
    int take = 10,
    String? topicId,
    bool followedOnly = false,
    CommunityFeedSort sort = CommunityFeedSort.recent,
    DateTime? anchorAt,
  }) {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.getFeed(
          page: page,
          take: take,
          topicId: topicId,
          // Only sent when true: the server treats the parameter's presence as
          // "restrict to the threads I follow", and an explicit false would
          // still read as a filter to anyone debugging the request.
          followedOnly: followedOnly ? true : null,
          // Omitted when it is the default, so the request reads as plainly as
          // the server's own default behaviour.
          sort: sort == CommunityFeedSort.recent ? null : sort.value,
          anchorAt: anchorAt?.toIso8601String(),
        );

        return (response.data ?? const CommunityFeedModel()).toEntity();
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, CommunityTopicListEntity> getTopics() {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.getTopics();

        return (response.data ?? const CommunityTopicListModel()).toEntity();
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, CommunityTopicEntity> getTopic(String id) {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.getTopic(id);
        final model = response.data;
        if (model == null) throw Exception('Community topic $id is empty');

        return model.toEntity();
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, Unit> setTopicFollow({
    required String topicId,
    required bool follow,
  }) {
    return TaskEither.tryCatch(
      () async {
        if (follow) {
          await _api.followTopic(topicId);
        } else {
          await _api.unfollowTopic(topicId);
        }

        return unit;
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, CommunityPostEntity> getPost(String id) {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.getPost(id);
        final model = response.data;
        if (model == null) throw Exception('Community post $id is empty');

        return model.toEntity();
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, CommunityPostEntity> createPost({
    required String body,
    String? subject,
    String? topicId,
    List<String>? images,
    String? attachedCourseId,
    CommunityAttachedCardEntity? attachedCard,
    bool isAnonymous = false,
  }) {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.createPost({
          if (subject != null && subject.trim().isNotEmpty) 'subject': subject.trim(),
          'body': body,
          'topicId': ?topicId,
          if (images != null && images.isNotEmpty) 'images': images,
          'attachedCourseId': ?attachedCourseId,
          if (attachedCard != null)
            'attachedCard': {
              'keypointId': attachedCard.keypointId,
              'title': attachedCard.title,
              'back': attachedCard.back,
              if (attachedCard.courseName?.isNotEmpty == true) 'courseName': attachedCard.courseName,
            },
          // Only sent when on: the server defaults to a named post, and an
          // explicit false in the payload reads like a decision was made.
          if (isAnonymous) 'isAnonymous': true,
        });
        final model = response.data;
        if (model == null) throw Exception('Created community post is empty');

        return model.toEntity();
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, Unit> deletePost(String id) {
    return TaskEither.tryCatch(
      () async {
        await _api.deletePost(id);

        return unit;
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, CommunityCommentPageEntity> getComments({
    required String postId,
    required int page,
    int take = 10,
  }) {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.getComments(postId, page: page, take: take);

        return (response.data ?? const CommunityCommentPageModel()).toEntity();
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, CommunityCommentPageEntity> createComment({
    required String postId,
    required String body,
    String? parentId,
    String? replyToUserId,
  }) {
    return TaskEither.tryCatch(
      () async {
        // The API answers with the refreshed first page of the thread, so the
        // screen does not have to guess where the new comment landed.
        final response = await _api.createComment(postId, {
          'body': body,
          'parentId': ?parentId,
          'replyToUserId': ?replyToUserId,
        });

        return (response.data ?? const CommunityCommentPageModel()).toEntity();
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, Unit> deleteComment(String id) {
    return TaskEither.tryCatch(
      () async {
        await _api.deleteComment(id);

        return unit;
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, Unit> setReaction({
    required CommunityTargetType targetType,
    required String targetId,
    required CommunityReactionKind kind,
    required bool active,
  }) {
    return TaskEither.tryCatch(
      () async {
        final body = {
          'targetType': targetType.value,
          'targetId': targetId,
          'kind': kind.value,
        };

        if (active) {
          await _api.react(body);
        } else {
          await _api.unreact(body);
        }

        return unit;
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, Unit> hideItem({
    required CommunityTargetType targetType,
    required String targetId,
  }) {
    return TaskEither.tryCatch(
      () async {
        await _api.hide({
          'targetType': targetType.value,
          'targetId': targetId,
        });

        return unit;
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, Unit> report({
    required CommunityTargetType targetType,
    required String targetId,
    required CommunityReportReason reason,
    String? note,
  }) {
    return TaskEither.tryCatch(
      () async {
        await _api.report({
          'targetType': targetType.value,
          'targetId': targetId,
          'reason': reason.value,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        });

        return unit;
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, BasePageBreak<CommunityPostEntity>> getSavedPosts({
    required int page,
    int take = 10,
  }) {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.getSaved(page: page, take: take);
        final data = response.data ?? const CommunitySavedPageModel();

        return BasePageBreak<CommunityPostEntity>(
          totalPages: data.totalPages,
          currentPage: data.currentPage,
          itemsPerPage: data.itemsPerPage,
          items: data.items.map((item) => item.toEntity()).toList(),
        );
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, CommunityWeeklyEntity?> getWeekly() {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.getWeekly();

        return response.data?.toEntity();
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, CommunityNotificationPageEntity> getNotifications({
    required int page,
    int take = 20,
  }) {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.getNotifications(page: page, take: take);

        return (response.data ?? const CommunityNotificationPageModel()).toEntity();
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, int> getUnreadNotificationCount() {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.getUnreadCount();

        return response.data?.count ?? 0;
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, Unit> markNotificationsRead({List<String>? ids}) {
    return TaskEither.tryCatch(
      () async {
        await _api.markNotificationsRead({
          if (ids != null && ids.isNotEmpty) 'ids': ids,
        });

        return unit;
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, List<CommunityRoomSuggestionEntity>> getRoomSuggestions() {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.getRoomSuggestions();

        return (response.data?.items ?? const <CommunityRoomSuggestionModel>[]).map((item) => item.toEntity()).toList();
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, CommunityRoomSuggestionEntity> createRoomSuggestion({
    required String name,
    String? description,
  }) {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.createRoomSuggestion({
          'name': name.trim(),
          if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
        });
        final model = response.data;
        if (model == null) throw Exception('Room suggestion is empty');

        return model.toEntity();
      },
      // Not `error.toString()`: this endpoint answers with a CODE the sheet has
      // its own line for ("bạn đang có 3 đề xuất chờ"), and DioException's
      // toString drops the response body, so the code never arrived.
      (error, stackTrace) => AppException.unexpected(_serverMessage(error)),
    );
  }

  @override
  TaskEither<AppException, CommunityRoomSuggestionEntity> voteRoomSuggestion(
    String id,
  ) {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.voteRoomSuggestion(id);
        final model = response.data;
        if (model == null) throw Exception('Room suggestion is empty');

        return model.toEntity();
      },
      (error, stackTrace) => AppException.unexpected(_serverMessage(error)),
    );
  }

  /// The API's own `message` when there is one, so a caller can branch on the
  /// server's error CODE rather than on a stringified exception.
  String _serverMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) return '${data['message']}';
    }

    return error.toString();
  }

  @override
  TaskEither<AppException, CommunityMemberStatusEntity> getMemberStatus() {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.getMemberStatus();

        return (response.data ?? const CommunityMemberStatusModel()).toEntity();
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, Unit> markTourSeen() {
    return TaskEither.tryCatch(
      () async {
        await _api.markTourSeen();

        return unit;
      },
      (error, stackTrace) => communityException(error),
    );
  }

  // ------------------------------------------------------------ group chat

  @override
  TaskEither<AppException, CommunityChatRoomEntity> getChatRoom(String room) {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.getChatRoom(room);

        return (response.data ?? const CommunityChatRoomModel()).toEntity();
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, CommunityChatPageEntity> getChatMessages({
    required String room,
    required int page,
    int take = 30,
  }) {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.getChatMessages(room, page: page, take: take);

        return (response.data ?? const CommunityChatPageModel()).toEntity();
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, CommunityChatMessageEntity> sendChatMessage({
    required String room,
    required String body,
  }) {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.sendChatMessage(room, {'body': body});

        return (response.data ?? const CommunityChatMessageModel()).toEntity();
      },
      (error, stackTrace) => communityException(error),
    );
  }

  @override
  TaskEither<AppException, ({bool isLiked, int likeCount})> likeChatMessage(String id) {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.likeChatMessage(id);
        final data = response.data ?? const CommunityChatLikeModel();

        return (isLiked: data.isLiked, likeCount: data.likeCount);
      },
      (error, stackTrace) => communityException(error),
    );
  }
}

//* Model -> Entity mappers. Kept beside the repository because that is the only
//* place they are used: nothing outside the data layer sees a model.
extension CommunityAuthorModelX on CommunityAuthorModel {
  CommunityAuthorEntity toEntity() => CommunityAuthorEntity(
    id: id,
    name: name,
    avatar: avatar,
    isOfficial: authorType == 'OFFICIAL',
    isAnonymous: authorType == 'ANONYMOUS',
  );
}

extension CommunityAttachedCardModelX on CommunityAttachedCardModel {
  CommunityAttachedCardEntity toEntity() => CommunityAttachedCardEntity(
    keypointId: keypointId,
    title: title,
    back: back,
    courseName: courseName,
  );
}

extension CommunityPostTopicModelX on CommunityPostTopicModel {
  CommunityPostTopicEntity toEntity() =>
      CommunityPostTopicEntity(id: id, name: name, imageUrl: imageUrl);
}

extension CommunityPostModelX on CommunityPostModel {
  CommunityPostEntity toEntity() => CommunityPostEntity(
    id: id,
    author: author.toEntity(),
    topic: topic?.toEntity(),
    subject: subject,
    body: body,
    images: images,
    attachedCourseId: attachedCourseId,
    attachedCard: attachedCard?.toEntity(),
    isPinned: isPinned,
    commentsLocked: commentsLocked,
    likeCount: likeCount,
    commentCount: commentCount,
    saveCount: saveCount,
    isLiked: isLiked,
    isSaved: isSaved,
    isMine: isMine,
    createdAt: DateTime.tryParse(createdAt ?? '')?.toLocal(),
  );
}

extension CommunityWeeklyModelX on CommunityWeeklyModel {
  CommunityWeeklyEntity toEntity() => CommunityWeeklyEntity(
    id: id,
    title: title,
    note: note,
    weekNumber: weekNumber,
    year: year,
    startsAt: DateTime.tryParse(startsAt ?? '')?.toLocal(),
    endsAt: DateTime.tryParse(endsAt ?? '')?.toLocal(),
    answerCount: answerCount,
  );
}

extension CommunityFeedModelX on CommunityFeedModel {
  CommunityFeedEntity toEntity() => CommunityFeedEntity(
    anchorAt: DateTime.tryParse(anchorAt ?? '')?.toLocal(),
    weekly: weekly?.toEntity(),
    pinned: pinned.map((post) => post.toEntity()).toList(),
    items: items.map((post) => post.toEntity()).toList(),
    currentPage: currentPage,
    totalPages: totalPages,
  );
}

extension CommunityTopicModelX on CommunityTopicModel {
  CommunityTopicEntity toEntity() => CommunityTopicEntity(
    id: id,
    name: name,
    description: description,
    slug: slug,
    imageUrl: imageUrl,
    followers: followers,
    postsThisWeek: postsThisWeek,
    isFollowing: isFollowing,
  );
}

extension CommunityChatRoomModelX on CommunityChatRoomModel {
  CommunityChatRoomEntity toEntity() => CommunityChatRoomEntity(
    id: id,
    slug: slug,
    name: name,
    isOfficial: isOfficial,
    onlineCount: onlineCount,
    unreadCount: unreadCount,
  );
}

extension CommunityChatMessageModelX on CommunityChatMessageModel {
  CommunityChatMessageEntity toEntity() => CommunityChatMessageEntity(
    id: id,
    author: author.toEntity(),
    isModerator: isModerator,
    body: body,
    likeCount: likeCount,
    isLiked: isLiked,
    isMine: isMine,
    isSeen: isSeen,
    createdAt: DateTime.tryParse(createdAt ?? '')?.toLocal(),
  );
}

extension CommunityChatPageModelX on CommunityChatPageModel {
  CommunityChatPageEntity toEntity() => CommunityChatPageEntity(
    items: items.map((message) => message.toEntity()).toList(),
    currentPage: currentPage,
    totalPages: totalPages,
  );
}

extension CommunityTopicListModelX on CommunityTopicListModel {
  CommunityTopicListEntity toEntity() => CommunityTopicListEntity(
    following: following.map((topic) => topic.toEntity()).toList(),
    all: all.map((topic) => topic.toEntity()).toList(),
  );
}

extension CommunityCommentModelX on CommunityCommentModel {
  CommunityCommentEntity toEntity() => CommunityCommentEntity(
    id: id,
    author: author.toEntity(),
    body: body,
    likeCount: likeCount,
    replyCount: replyCount,
    isLiked: isLiked,
    isMine: isMine,
    replyToName: replyToName,
    createdAt: DateTime.tryParse(createdAt ?? '')?.toLocal(),
    replies: replies.map((reply) => reply.toEntity()).toList(),
  );
}

extension CommunityCommentPageModelX on CommunityCommentPageModel {
  CommunityCommentPageEntity toEntity() => CommunityCommentPageEntity(
    items: items.map((comment) => comment.toEntity()).toList(),
    currentPage: currentPage,
    totalPages: totalPages,
  );
}

extension CommunityNotificationModelX on CommunityNotificationModel {
  CommunityNotificationEntity toEntity() => CommunityNotificationEntity(
    id: id,
    type: CommunityNotificationType.fromValue(type),
    actorId: actorId,
    actor: actor?.toEntity(),
    otherActorCount: otherActorCount,
    postId: postId,
    commentId: commentId,
    roomId: roomId,
    roomSlug: roomSlug,
    isRead: isRead,
    createdAt: DateTime.tryParse(createdAt ?? '')?.toLocal(),
  );
}

extension CommunityNotificationPageModelX on CommunityNotificationPageModel {
  CommunityNotificationPageEntity toEntity() => CommunityNotificationPageEntity(
    items: items.map((item) => item.toEntity()).toList(),
    currentPage: currentPage,
    totalPages: totalPages,
    unreadCount: unreadCount,
  );
}

extension CommunityRoomSuggestionModelX on CommunityRoomSuggestionModel {
  CommunityRoomSuggestionEntity toEntity() => CommunityRoomSuggestionEntity(
    id: id,
    name: name,
    description: description,
    status: CommunityRoomSuggestionStatus.fromValue(status),
    voteCount: voteCount,
    hasVoted: hasVoted,
    isMine: isMine,
    topicId: topicId,
    mergedIntoExisting: mergedIntoExisting,
    createdAt: DateTime.tryParse(createdAt ?? '')?.toLocal(),
  );
}

extension CommunityMemberStatusModelX on CommunityMemberStatusModel {
  CommunityMemberStatusEntity toEntity() => CommunityMemberStatusEntity(
    canPost: canPost,
    requiresLogin: requiresLogin,
    reason: reason,
    mutedUntil: DateTime.tryParse(mutedUntil ?? '')?.toLocal(),
    tourSeen: tourSeen,
  );
}
