part of '../../community.dart';

@lazySingleton
class GetCommunityNotificationsUseCase {
  final ICommunityRepository _repository;

  GetCommunityNotificationsUseCase(this._repository);

  TaskEither<AppException, CommunityNotificationPageEntity> call({
    required int page,
    int take = 20,
  }) {
    return _repository.getNotifications(page: page, take: take);
  }
}

/// The red dot on the community header.
@lazySingleton
class GetCommunityUnreadCountUseCase {
  final ICommunityRepository _repository;

  GetCommunityUnreadCountUseCase(this._repository);

  TaskEither<AppException, int> call() => _repository.getUnreadNotificationCount();
}

@lazySingleton
class MarkCommunityNotificationsReadUseCase {
  final ICommunityRepository _repository;

  MarkCommunityNotificationsReadUseCase(this._repository);

  /// Omit [ids] to clear everything unread.
  TaskEither<AppException, Unit> call({List<String>? ids}) {
    return _repository.markNotificationsRead(ids: ids);
  }
}
