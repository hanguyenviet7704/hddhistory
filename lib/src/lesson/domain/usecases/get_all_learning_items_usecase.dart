part of '../../lesson.dart';

@freezed
abstract class LearningItemFilter with _$LearningItemFilter implements JsonRequestConvertible {
  const factory LearningItemFilter({
    @Default(null) LearningItemFilterType? type,
    @Default(null) String? keypointId,
  }) = _LearningItemFilter;

  factory LearningItemFilter.fromJson(Map<String, dynamic> json) => _$LearningItemFilterFromJson(json);
}

enum LearningItemFilterType {
  theory('theory'),
  exercise('exercise');

  const LearningItemFilterType(this.name);
  final String name;
}

@lazySingleton
class GetAllLearningItemsUseCase implements UseCaseWithParams<PageBreakRequest, BasePageBreak<LearningItemEntity>> {
  final ILessonRepository _repository;

  GetAllLearningItemsUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<LearningItemEntity>> call(PageBreakRequest params) {
    return _repository.getAllLearningItems(params);
  }
}
