{{#include_state_management}}
{{#use_bloc}}
part of '../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

@freezed
sealed class {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event with _${{#pascalCase}}{{feature_name}}{{/pascalCase}}Event {
  {{#has_list}}const factory {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.loadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s({@Default(false) bool isInit}) = _LoadAll{{#pascalCase}}{{entity_name}}{{/pascalCase}}s;
  {{/has_list}}{{#has_detail}}const factory {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.load{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id) = _Load{{#pascalCase}}{{entity_name}}{{/pascalCase}};
  {{/has_detail}}{{#has_create}}const factory {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.create{{#pascalCase}}{{entity_name}}{{/pascalCase}}({{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity) = _Create{{#pascalCase}}{{entity_name}}{{/pascalCase}};
  {{/has_create}}{{#has_update}}const factory {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.update{{#pascalCase}}{{entity_name}}{{/pascalCase}}({{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity entity) = _Update{{#pascalCase}}{{entity_name}}{{/pascalCase}};
  {{/has_update}}{{#has_delete}}const factory {{#pascalCase}}{{feature_name}}{{/pascalCase}}Event.delete{{#pascalCase}}{{entity_name}}{{/pascalCase}}(String id) = _Delete{{#pascalCase}}{{entity_name}}{{/pascalCase}};
  {{/has_delete}}
}
{{/use_bloc}}
{{/include_state_management}}
