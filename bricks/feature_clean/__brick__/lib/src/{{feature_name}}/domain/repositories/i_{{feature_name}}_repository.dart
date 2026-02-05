{{#include_domain_layer}}part of '../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

abstract class I{{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository {
  {{#has_list}}TaskEither<AppException, BasePageBreak<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>> getAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(
    PageBreakRequest request,
  );
  {{/has_list}}{{#has_detail}}TaskEither<AppException, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity> get{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id);
  {{/has_detail}}{{#has_create}}TaskEither<AppException, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity> create{{#pascalCase}}{{entity_name}}{{/pascalCase}}({{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity);
  {{/has_create}}{{#has_update}}TaskEither<AppException, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity> update{{#pascalCase}}{{entity_name}}{{/pascalCase}}({{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity);
  {{/has_update}}{{#has_delete}}TaskEither<AppException, Unit> delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id);
  {{/has_delete}}
}
{{/include_domain_layer}}
