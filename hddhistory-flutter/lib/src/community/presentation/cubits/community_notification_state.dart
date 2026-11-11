part of '../../community.dart';

@freezed
abstract class CommunityNotificationState with _$CommunityNotificationState {
  const factory CommunityNotificationState({
    @Default(CommunityStatus.initial) CommunityStatus status,
    @Default(<CommunityNotificationEntity>[]) List<CommunityNotificationEntity> items,
    @Default(1) int currentPage,
    @Default(1) int totalPages,
    @Default(0) int unreadCount,
    @Default(false) bool isLoadingMore,
    String? errorMessage,
  }) = _CommunityNotificationState;

  factory CommunityNotificationState.initial() => const CommunityNotificationState();
}

extension CommunityNotificationStateX on CommunityNotificationState {
  bool get hasMore => currentPage < totalPages;

  bool get isEmpty => status == CommunityStatus.success && items.isEmpty;
}
