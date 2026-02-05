{{#include_domain_layer}}{{#has_update}}part of '../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

@lazySingleton
class Update{{#pascalCase}}{{entity_name}}{{/pascalCase}}UseCase implements UseCaseWithParams<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity> {
  final I{{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository _repository;

  Update{{#pascalCase}}{{entity_name}}{{/pascalCase}}UseCase(this._repository);

  @override
  TaskEither<AppException, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity> call({{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity params) {
    return _repository.update{{#pascalCase}}{{entity_name}}{{/pascalCase}}(params);
  }
}
{{/has_update}}{{/include_domain_layer}}
