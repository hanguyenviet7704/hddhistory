part of '../../community.dart';

@lazySingleton
class GetCommunityChatRoomUseCase {
  final ICommunityRepository _repository;

  GetCommunityChatRoomUseCase(this._repository);

  TaskEither<AppException, CommunityChatRoomEntity> call(String room) {
    return _repository.getChatRoom(room);
  }
}

@lazySingleton
class GetCommunityChatMessagesUseCase {
  final ICommunityRepository _repository;

  GetCommunityChatMessagesUseCase(this._repository);

  /// Newest first: page 1 is the bottom of the screen, page 2 the history above.
  TaskEither<AppException, CommunityChatPageEntity> call({
    required String room,
    required int page,
    int take = 30,
  }) {
    return _repository.getChatMessages(room: room, page: page, take: take);
  }
}

@lazySingleton
class SendCommunityChatMessageUseCase {
  final ICommunityRepository _repository;

  SendCommunityChatMessageUseCase(this._repository);

  TaskEither<AppException, CommunityChatMessageEntity> call({
    required String room,
    required String body,
    String? replyToId,
  }) {
    return _repository.sendChatMessage(
      room: room,
      body: body,
      replyToId: replyToId,
    );
  }
}

@lazySingleton
class LikeCommunityChatMessageUseCase {
  final ICommunityRepository _repository;

  LikeCommunityChatMessageUseCase(this._repository);

  TaskEither<AppException, ({bool isLiked, int likeCount})> call(String id) {
    return _repository.likeChatMessage(id);
  }
}

@lazySingleton
class GetCommunityChatMessageContextUseCase {
  final ICommunityRepository _repository;

  GetCommunityChatMessageContextUseCase(this._repository);

  /// The window a jump lands in. Needed because a pinned line can sit hundreds
  /// of messages back, where there is nothing on screen to scroll to.
  TaskEither<AppException, CommunityChatContextEntity> call({
    required String room,
    required String messageId,
  }) {
    return _repository.getChatMessageContext(room: room, messageId: messageId);
  }
}

@lazySingleton
class GetCommunityChatGuideUseCase {
  final ICommunityRepository _repository;

  GetCommunityChatGuideUseCase(this._repository);

  /// Null means nothing has been authored — the header hides its info button
  /// rather than opening an empty sheet.
  TaskEither<AppException, CommunityChatGuideEntity?> call() {
    return _repository.getChatGuide();
  }
}
