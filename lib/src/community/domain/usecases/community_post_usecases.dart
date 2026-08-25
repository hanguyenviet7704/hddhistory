part of '../../community.dart';

@lazySingleton
class GetCommunityPostUseCase {
  final ICommunityRepository _repository;

  GetCommunityPostUseCase(this._repository);

  TaskEither<AppException, CommunityPostEntity> call(String id) => _repository.getPost(id);
}

@lazySingleton
class CreateCommunityPostUseCase {
  final ICommunityRepository _repository;

  CreateCommunityPostUseCase(this._repository);

  TaskEither<AppException, CommunityPostEntity> call({
    required String body,
    String? subject,
    String? topicId,
    List<String>? images,
    String? attachedCourseId,
    CommunityAttachedCardEntity? attachedCard,
    bool isAnonymous = false,
  }) {
    return _repository.createPost(
      body: body,
      subject: subject,
      topicId: topicId,
      images: images,
      attachedCourseId: attachedCourseId,
      attachedCard: attachedCard,
      isAnonymous: isAnonymous,
    );
  }
}

@lazySingleton
class DeleteCommunityPostUseCase {
  final ICommunityRepository _repository;

  DeleteCommunityPostUseCase(this._repository);

  TaskEither<AppException, Unit> call(String id) => _repository.deletePost(id);
}
