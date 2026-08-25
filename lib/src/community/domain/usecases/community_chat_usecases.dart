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
  }) {
    return _repository.sendChatMessage(room: room, body: body);
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
