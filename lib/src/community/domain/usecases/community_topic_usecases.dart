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
