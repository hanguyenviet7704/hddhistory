{{#include_domain_layer}}part of '../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

@freezed
abstract class {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity with _${{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity {
  const factory {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity({
    @Default('') String id,
    @Default('') String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _{{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity;

  factory {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity.fromJson(Map<String, dynamic> json) => _${{#pascalCase}}{{entity_name}}{{/pascalCase}}EntityFromJson(json);
}
{{/include_domain_layer}}
