part of '../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

@lazySingleton
class GetAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}sUseCase implements UseCaseWithoutParams<List<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>> {
  final I{{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository _repository;

  GetAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}sUseCase(this._repository);

  @override
  TaskEither<AppException, List<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>> call() {
    return _repository.getAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s();
  }
}
