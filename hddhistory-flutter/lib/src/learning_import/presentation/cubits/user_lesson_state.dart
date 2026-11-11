part of '../../learning_import.dart';

enum UserLessonStatus { initial, loading, success, failure }

/// Backs both the list screen and the reader.
///
/// [pageData] holds cards WITHOUT their body (the list endpoint omits it);
/// [selected] is the one lesson loaded in full. Keeping them apart is what lets
/// the list stay cheap while the reader still has everything it needs.
@freezed
abstract class UserLessonState with _$UserLessonState {
  const factory UserLessonState({
    @Default(UserLessonStatus.initial) UserLessonStatus status,
    @Default(BasePageBreak<UserLessonEntity>())
    BasePageBreak<UserLessonEntity> pageData,
    UserLessonEntity? selected,
    String? errorMessage,
  }) = _UserLessonState;

  factory UserLessonState.initial() => const UserLessonState();
}

extension UserLessonStateX on UserLessonState {
  bool get isLoading => status == UserLessonStatus.loading;

  bool get isEmpty =>
      status == UserLessonStatus.success && pageData.items.isEmpty;
}
