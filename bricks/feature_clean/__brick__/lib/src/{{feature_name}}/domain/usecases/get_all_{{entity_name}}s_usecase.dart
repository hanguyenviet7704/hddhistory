{{#include_domain_layer}}{{#has_list}}part of '../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

@lazySingleton
class GetAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}sUseCase implements UseCaseWithParams<PageBreakRequest, BasePageBreak<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>> {
  final I{{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository _repository;

  GetAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}sUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>> call(PageBreakRequest params) {
    return _repository.getAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(params);
  }
}
{{/has_list}}{{/include_domain_layer}}
