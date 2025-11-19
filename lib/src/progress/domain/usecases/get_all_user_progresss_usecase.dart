part of '../../progress.dart';

@freezed
abstract class UserProgressFilter with _$UserProgressFilter implements JsonRequestConvertible {
  const factory UserProgressFilter({
    UserProgressFilterType? grade,
    String? courseId,
    String? userId,
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
class GetAllUserProgresssUseCase implements UseCaseWithParams<PageBreakRequest, BasePageBreak<UserProgressEntity>> {
  final IProgressRepository _repository;

  GetAllUserProgresssUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<UserProgressEntity>> call(PageBreakRequest params) {
    return _repository.getAllUserProgresss(params);
  }
}
