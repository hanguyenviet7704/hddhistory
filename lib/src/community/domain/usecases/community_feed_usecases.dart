part of '../../community.dart';

@lazySingleton
class GetCommunityFeedUseCase {
  final ICommunityRepository _repository;

  GetCommunityFeedUseCase(this._repository);

  TaskEither<AppException, CommunityFeedEntity> call({
    required int page,
    int take = 10,
    String? topicId,
    bool followedOnly = false,
    CommunityFeedSort sort = CommunityFeedSort.recent,
    DateTime? anchorAt,
  }) {
    return _repository.getFeed(
      page: page,
      take: take,
      topicId: topicId,
      followedOnly: followedOnly,
      sort: sort,
      anchorAt: anchorAt,
    );
  }
}

@lazySingleton
class GetCommunitySavedPostsUseCase {
  final ICommunityRepository _repository;

  GetCommunitySavedPostsUseCase(this._repository);

  TaskEither<AppException, BasePageBreak<CommunityPostEntity>> call({
    required int page,
    int take = 10,
  }) {
    return _repository.getSavedPosts(page: page, take: take);
  }
}

@lazySingleton
class GetCommunityWeeklyUseCase {
  final ICommunityRepository _repository;

  GetCommunityWeeklyUseCase(this._repository);

  TaskEither<AppException, CommunityWeeklyEntity?> call() => _repository.getWeekly();
}

@lazySingleton
class GetCommunityMemberStatusUseCase {
  final ICommunityRepository _repository;

  GetCommunityMemberStatusUseCase(this._repository);

  TaskEither<AppException, CommunityMemberStatusEntity> call() => _repository.getMemberStatus();
}

@lazySingleton
class MarkCommunityTourSeenUseCase {
  final ICommunityRepository _repository;

  MarkCommunityTourSeenUseCase(this._repository);

  TaskEither<AppException, Unit> call() => _repository.markTourSeen();
}
