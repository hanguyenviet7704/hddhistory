part of '../../lesson.dart';

// abstract class LearningItemFilter with _$LearningItemFilter implements JsonConvertible {
@freezed
abstract class LearningItemFilter with _$LearningItemFilter {
  const factory LearningItemFilter({
    LearningItemFilterType? type,
    String? keypointId,
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
class GetAllLearningItemsUseCase implements UseCaseWithParams<PageBreakRequest<LearningItemFilter>, BasePageBreak<LearningItemEntity>> {
  final ILessonRepository _repository;

  GetAllLearningItemsUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<LearningItemEntity>> call(PageBreakRequest<LearningItemFilter> params) {
    return _repository.getAllLearningItems(params);
  }
}
