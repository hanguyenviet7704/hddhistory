{{#use_bloc}}part of '../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

@freezed
sealed class {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event with _${{#pascalCase}}{{feature_name}}{{/pascalCase}}Event {
  const factory {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.loadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s() = _LoadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s;
  const factory {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.load{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id) = _Load{{#pascalCase}}{{entity_name}}{{/pascalCase}};
  const factory {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.create{{#pascalCase}}{{entity_name}}{{/pascalCase}}({{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity) = _Create{{#pascalCase}}{{entity_name}}{{/pascalCase}};
  const factory {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.update{{#pascalCase}}{{entity_name}}{{/pascalCase}}({{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity) = _Update{{#pascalCase}}{{entity_name}}{{/pascalCase}};
  const factory {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id) = _Delete{{#pascalCase}}{{entity_name}}{{/pascalCase}};
}
{{/use_bloc}}