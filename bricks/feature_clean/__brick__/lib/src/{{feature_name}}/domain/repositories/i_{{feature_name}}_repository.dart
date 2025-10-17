part of '../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

abstract class I{{#pascalCase}}{{feature_name}}{{/pascalCase}}Repository {
  TaskEither<AppException, BasePageBreak<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>> getAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s(
    PageBreakRequest request,
  );
  TaskEither<AppException, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity> get{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id);
  TaskEither<AppException, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity> create{{#pascalCase}}{{entity_name}}{{/pascalCase}}({{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity);
  TaskEither<AppException, {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity> update{{#pascalCase}}{{entity_name}}{{/pascalCase}}({{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity);
  TaskEither<AppException, Unit> delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id);
}
