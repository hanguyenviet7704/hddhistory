part of '../../community.dart';

@lazySingleton
class GetCommunityTopicsUseCase {
  final ICommunityRepository _repository;

  GetCommunityTopicsUseCase(this._repository);

  TaskEither<AppException, CommunityTopicListEntity> call() => _repository.getTopics();
}

@lazySingleton
class GetCommunityTopicUseCase {
  final ICommunityRepository _repository;

  GetCommunityTopicUseCase(this._repository);

  TaskEither<AppException, CommunityTopicEntity> call(String id) => _repository.getTopic(id);
}

@lazySingleton
class SetCommunityTopicFollowUseCase {
  final ICommunityRepository _repository;

  SetCommunityTopicFollowUseCase(this._repository);

  TaskEither<AppException, Unit> call({
    required String topicId,
    required bool follow,
  }) {
    return _repository.setTopicFollow(topicId: topicId, follow: follow);
  }
}

@lazySingleton
class GetCommunityRoomSuggestionsUseCase {
  final ICommunityRepository _repository;

  GetCommunityRoomSuggestionsUseCase(this._repository);

  TaskEither<AppException, List<CommunityRoomSuggestionEntity>> call() => _repository.getRoomSuggestions();
}

@lazySingleton
class CreateCommunityRoomSuggestionUseCase {
  final ICommunityRepository _repository;

  CreateCommunityRoomSuggestionUseCase(this._repository);

  TaskEither<AppException, CommunityRoomSuggestionEntity> call({
    required String name,
    String? description,
  }) {
    return _repository.createRoomSuggestion(
      name: name,
      description: description,
    );
  }
}

@lazySingleton
class VoteCommunityRoomSuggestionUseCase {
  final ICommunityRepository _repository;

  VoteCommunityRoomSuggestionUseCase(this._repository);

  TaskEither<AppException, CommunityRoomSuggestionEntity> call(String id) => _repository.voteRoomSuggestion(id);
}
