part of '../../community.dart';

@lazySingleton
class GetCommunityCommentsUseCase {
  final ICommunityRepository _repository;

  GetCommunityCommentsUseCase(this._repository);

  TaskEither<AppException, CommunityCommentPageEntity> call({
    required String postId,
    required int page,
    int take = 10,
  }) {
    return _repository.getComments(postId: postId, page: page, take: take);
  }
}

@lazySingleton
class CreateCommunityCommentUseCase {
  final ICommunityRepository _repository;

  CreateCommunityCommentUseCase(this._repository);

  /// Returns the refreshed first page of the thread, which is what the screen
  /// renders — no local guess about where the new comment belongs.
  TaskEither<AppException, CommunityCommentPageEntity> call({
    required String postId,
    required String body,
    String? parentId,
    String? replyToUserId,
  }) {
    return _repository.createComment(
      postId: postId,
      body: body,
      parentId: parentId,
      replyToUserId: replyToUserId,
    );
  }
}

@lazySingleton
class DeleteCommunityCommentUseCase {
  final ICommunityRepository _repository;

  DeleteCommunityCommentUseCase(this._repository);

  TaskEither<AppException, Unit> call(String id) => _repository.deleteComment(id);
}
