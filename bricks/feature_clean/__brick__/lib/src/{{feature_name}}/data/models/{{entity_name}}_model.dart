part of '../../{{#snakeCase}}{{feature_name}}{{/snakeCase}}.dart';

@freezed
abstract class {{#pascalCase}}{{entity_name}}{{/pascalCase}}Model with _${{#pascalCase}}{{entity_name}}{{/pascalCase}}Model {
  const factory {{#pascalCase}}{{entity_name}}{{/pascalCase}}Model({
    @Default('') String id,
    @Default('') String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _{{#pascalCase}}{{entity_name}}{{/pascalCase}}Model;


  factory {{#pascalCase}}{{entity_name}}{{/pascalCase}}Model.fromJson(Map<String, dynamic> json) => _${{#pascalCase}}{{entity_name}}{{/pascalCase}}ModelFromJson(json);

  {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity toEntity() => {{#pascalCase}}{{entity_name}}{{/pascalCase}}Entity(
        id: id,
        name: name,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
