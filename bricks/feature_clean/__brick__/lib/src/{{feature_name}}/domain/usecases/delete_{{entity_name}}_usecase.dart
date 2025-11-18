{{#include_domain_layer}}{{#has_delete}}part of '../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

@lazySingleton
class Delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}UseCase implements UseCaseWithParams<String, Unit> {
  final I{{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository _repository;

  Delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}UseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(String params) {
    return _repository.delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}(params);
  }
}
{{/has_delete}}{{/include_domain_layer}}
