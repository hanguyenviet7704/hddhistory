{{#include_state_management}}
part of '../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

enum {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status { initial, loading, success, failure }

@freezed
abstract class {{#pascalCase}}{{feature_name}}{{/pascalCase}}State with _${{#pascalCase}}{{feature_name}}{{/pascalCase}}State {
  const factory {{#pascalCase}}{{feature_name}}{{/pascalCase}}State({
    @Default({{#pascalCase}}{{feature_name}}{{/pascalCase}}Status.initial) {{#pascalCase}}{{feature_name}}{{/pascalCase}}Status status,
    {{#has_list}}@Default(BasePageBreak<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity>()) BasePageBreak<{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity> pageData,
    {{/has_list}}{{#has_detail}}{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity? selectedItem,
    {{/has_detail}}String? errorMessage,
  }) = _{{#pascalCase}}{{feature_name}}{{/pascalCase}}State;

  factory {{#pascalCase}}{{feature_name}}{{/pascalCase}}State.initial() => {{#pascalCase}}{{feature_name}}{{/pascalCase}}State();

  factory {{#pascalCase}}{{feature_name}}{{/pascalCase}}State.fromJson(Map<String, dynamic> json) => _${{#pascalCase}}{{feature_name}}{{/pascalCase}}StateFromJson(json);
}
{{/include_state_management}}
