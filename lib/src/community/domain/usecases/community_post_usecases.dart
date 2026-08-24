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
    String? topicId,
    List<String>? images,
    String? attachedCourseId,
  }) {
    return _repository.createPost(
      body: body,
      topicId: topicId,
      images: images,
      attachedCourseId: attachedCourseId,
    );
  }
}

@lazySingleton
class DeleteCommunityPostUseCase {
  final ICommunityRepository _repository;

  DeleteCommunityPostUseCase(this._repository);

  TaskEither<AppException, Unit> call(String id) => _repository.deletePost(id);
}
