part of '../../progress.dart';

@freezed
abstract class UserProgressFilter with _$UserProgressFilter implements JsonRequestConvertible {
  const factory UserProgressFilter({
    @Default('') String userId,
    UserProgressFilterType? grade,
    String? courseId,
    String? lessonId,
    String? keypointId,
    String? exerciseId,
  }) = _UserProgressFilter;

  factory UserProgressFilter.fromJson(Map<String, dynamic> json) => _$UserProgressFilterFromJson(json);
}

enum UserProgressFilterType {
  course('course'),
  lesson('lesson'),
  keypoint('keypoint'),
  exercise('exercise')
  ;

  const UserProgressFilterType(this.name);
  final String name;
}

@lazySingleton
class GetAllUserProgresssUseCase implements BaseUseCase<UserProgressFilter, UserProgressEntity> {
  final IProgressRepository _repository;

  GetAllUserProgresssUseCase(this._repository);

  @override
  TaskEither<AppException, UserProgressEntity> call(UserProgressFilter params) {
    return _repository.getAllUserProgresss(params);
  }
}
