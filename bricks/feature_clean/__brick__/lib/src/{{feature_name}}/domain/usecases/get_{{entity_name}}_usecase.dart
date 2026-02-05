{{#include_domain_layer}}{{#has_detail}}part of '../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

@lazySingleton
class Get{{#pascalCase}}{{entity_name}}{{/pascalCase}}UseCase implements UseCaseWithParams<String, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity> {
  final I{{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository _repository;

  Get{{#pascalCase}}{{entity_name}}{{/pascalCase}}UseCase(this._repository);

  @override
  TaskEither<AppException, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity> call(String params) {
    return _repository.get{{#pascalCase}}{{entity_name}}{{/pascalCase}}(params);
  }
}
{{/has_detail}}{{/include_domain_layer}}
