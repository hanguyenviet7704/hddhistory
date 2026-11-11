part of '../../home.dart';

@lazySingleton
class GetCategoryUseCase implements BaseUseCase<String, CategoryEntity> {
  final IHomeRepository _repository;

  GetCategoryUseCase(this._repository);

  @override
  TaskEither<AppException, CategoryEntity> call(String params) {
    return _repository.getCategory(params);
  }
}
