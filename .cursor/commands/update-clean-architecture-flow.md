# Update Clean Architecture Module Command

This command provides a complete guide for updating a Clean Architecture module in the Flutter project when the data model changes. The approach is designed to work with any module by passing a file path as a parameter.

## Command Usage

To update any Clean Architecture module, provide the path to one of the module's files:

```
update-clean-architecture-flow lib/src/[module_name]/data/models/[module_name]_model.dart
```

Examples:
```
update-clean-architecture-flow lib/src/onboard/data/models/onboard_model.dart
update-clean-architecture-flow lib/src/auth/domain/entities/auth_entity.dart
update-clean-architecture-flow lib/src/profile/data/repositories/profile_repository.dart
```

## Agent Instructions

When this command is invoked with a file path, follow these steps:

### 1. Identify Module Structure

1. Extract the module name from the file path (e.g., "onboard" from "lib/src/onboard/data/models/onboard_model.dart")
2. Identify the module type (model, entity, repository, etc.)
3. Locate all related files in the Clean Architecture flow:
   - Models: `lib/src/[module_name]/data/models/`
   - Entities: `lib/src/[module_name]/domain/entities/`
   - Repositories: `lib/src/[module_name]/data/repositories/`
   - API: `lib/src/[module_name]/data/datasources/remote/`
   - Local Data Source: `lib/src/[module_name]/data/datasources/local/`
   - Use Cases: `lib/src/[module_name]/domain/usecases/`
   - Cubits: `lib/src/[module_name]/presentation/cubits/`
   - Pages: `lib/src/[module_name]/presentation/pages/`

### 2. Update Models

Update the data models in the `data/models/` directory:

```dart
// Example: [ModuleName]Model
@freezed
abstract class [ModuleName]Model with _$[ModuleName]Model {
  const factory [ModuleName]Model({
    @Default('') String id,  // Add default values for non-nullable fields
    // Add your fields here
    @Default([]) List<[ModuleName]OptionModel> options,  // Example of list field
    DateTime? createdAt,  // Nullable fields don't need @Default
    DateTime? updatedAt,
  }) = _[ModuleName]Model;

  factory [ModuleName]Model.fromJson(Map<String, dynamic> json) => _$[ModuleName]ModelFromJson(json);
}
```

### 3. Update Option Models (if applicable)

If your module has option models, update them to match the new structure:

```dart
// Example: [ModuleName]OptionModel
@freezed
abstract class [ModuleName]OptionModel with _$[ModuleName]OptionModel {
  const factory [ModuleName]OptionModel({
    @Default(0) int id,
    @Default('') String icon,
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
    // Add your option-specific fields here
  }) = _[ModuleName]OptionModel;

  factory [ModuleName]OptionModel.fromJson(Map<String, dynamic> json) => _$[ModuleName]OptionModelFromJson(json);
}
```

### 4. Update Entities

Update the domain entities in the `domain/entities/` directory to match the models:

```dart
// Example: [ModuleName]Entity
@freezed
abstract class [ModuleName]Entity with _$[ModuleName]Entity {
  const factory [ModuleName]Entity({
    @Default('') String id,  // Add default values for non-nullable fields
    // Add your fields here (matching the model)
    @Default([]) List<[ModuleName]OptionEntity> options,  // Example of list field
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _[ModuleName]Entity;

  factory [ModuleName]Entity.fromJson(Map<String, dynamic> json) => _$[ModuleName]EntityFromJson(json);
}
```

### 5. Update Option Entities (if applicable)

If your module has option entities, update them to match the new option models:

```dart
// Example: [ModuleName]OptionEntity
@freezed
abstract class [ModuleName]OptionEntity with _$[ModuleName]OptionEntity {
  const factory [ModuleName]OptionEntity({
    @Default(0) int id,
    @Default('') String icon,
    @Default(BaseMultiLanguage()) BaseMultiLanguage label,
    // Add your option-specific fields here (matching the option model)
  }) = _[ModuleName]OptionEntity;

  factory [ModuleName]OptionEntity.fromJson(Map<String, dynamic> json) => _$[ModuleName]OptionEntityFromJson(json);
}
```

### 6. Update Model Extensions

Update the `toEntity()` method in model extensions to properly convert models to entities:

```dart
// For main model
extension [ModuleName]ModelExtension on [ModuleName]Model {
  [ModuleName]Entity toEntity() => [ModuleName]Entity(
    id: id,
    // Map your fields here
    // For list fields, map each item to its entity
    options: options.map((model) => model.toEntity()).toList(),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

// For option model
extension [ModuleName]OptionModelExtension on [ModuleName]OptionModel {
  [ModuleName]OptionEntity toEntity() => [ModuleName]OptionEntity(
    id: id,
    icon: icon,
    label: label,
    // Map your option-specific fields here
  );
}
```

### 7. Update Repository Implementation

Update the repository implementation in `data/repositories/` to handle the new model structure:

```dart
@override
TaskEither<AppException, [ModuleName]Entity> create[ModuleName]([ModuleName]Entity entity) {
  return callApiWithTransform<[ModuleName]Model, [ModuleName]Entity>(
    apiCall: () => _api.create[ModuleName](_entityToJson(entity)),
    transform: (model) => model.toEntity(),
    onSuccess: (data) async => await _localDataSource.cache[ModuleName](data ?? [ModuleName]Model()),
    defaultValue: [ModuleName]Entity(),
  );
}

// Helper method to convert entity to JSON
Map<String, dynamic> _entityToJson([ModuleName]Entity entity) {
  return {
    'id': entity.id,
    // Map your fields here
    // For list fields, map each entity to its JSON representation
    'options': entity.options.map((e) => {
      'id': e.id,
      'icon': e.icon,
      'label': e.label.toJson(),
      // Map your option-specific fields here
    }).toList(),
    'createdAt': entity.createdAt?.toIso8601String(),
    'updatedAt': entity.updatedAt?.toIso8601String(),
  };
}
```

### 8. Update Module Parts

Ensure all new files are added to the module's main file:

```dart
// In [module_name].dart
part 'domain/entities/[module_name]_entity.dart';
part 'domain/entities/[module_name]_option_entity.dart';  // Add new entity parts
part 'data/models/[module_name]_model.dart';
part 'data/models/[module_name]_option_model.dart';  // Add new model parts
part 'data/repositories/[module_name]_repository.dart';
// ... other parts
```

### 9. Regenerate Generated Files

Run the build runner to regenerate Freezed and JSON serialization files:

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 10. Check for Lint Errors

Check for any lint errors and fix them:

```bash
flutter analyze
```

## Important Considerations

### Default Values

Always provide default values for non-nullable fields in Freezed models and entities:

```dart
@Default('') String stringValue,
@Default(false) bool boolValue,
@Default([]) List<Type> listValue,
@Default(0) int intValue,
```

### API Compatibility

If your API requires specific fields (like `id`), ensure they are included in both the model and entity, even if they're not part of the core business logic.

### List Field Conversion

When converting between models and entities with list fields, always map each item individually:

```dart
// Model to Entity
options: options.map((model) => model.toEntity()).toList(),

// Entity to JSON for API
'options': entity.options.map((e) => {
  'id': e.id,
  'icon': e.icon,
  'label': e.label.toJson(),
}).toList(),
```

### Multi-language Support

For fields that support multiple languages, use the BaseMultiLanguage type:

```dart
@Default(BaseMultiLanguage()) BaseMultiLanguage label,
```

And when converting to JSON:

```dart
'label': e.label.toJson(),
```

### DateTime Fields

For DateTime fields, use nullable types and convert to ISO 8601 strings when serializing to JSON:

```dart
DateTime? createdAt,
DateTime? updatedAt,

// In JSON conversion
'createdAt': entity.createdAt?.toIso8601String(),
'updatedAt': entity.updatedAt?.toIso8601String(),
```

### Error Handling

Maintain consistent error handling patterns in repositories using the project's established patterns:

```dart
return callApiWithTransform<[ModuleName]Model, [ModuleName]Entity>(
  apiCall: () => _api.create[ModuleName](_entityToJson(entity)),
  transform: (model) => model.toEntity(),
  onSuccess: (data) async => await _localDataSource.cache[ModuleName](data ?? [ModuleName]Model()),
  defaultValue: [ModuleName]Entity(),
);
```

## Common Issues and Solutions

### Issue: "The parameter 'field' is non-nullable but is neither required nor marked with @Default"

**Solution**: Add `@Default` annotation to all non-nullable fields in Freezed models and entities.

### Issue: "The argument type 'List<Model>' can't be assigned to the parameter type 'List<Entity>'"

**Solution**: Use `.map()` to convert each item in the list from model to entity or vice versa.

### Issue: "The getter 'field' isn't defined for the type 'Entity'"

**Solution**: Ensure the field exists in the entity definition and that the generated files are up to date.

### Issue: "The redirected constructor has incompatible parameters"

**Solution**: Run the build runner to regenerate the Freezed files after updating model definitions.

## Field Type Guidelines

### Supported Field Types

- `String` - Text fields with `@Default('')`
- `int` - Integer fields with `@Default(0)`
- `bool` - Boolean fields with `@Default(false)`
- `List<Type>` - List fields with `@Default([])`
- `DateTime?` - Nullable DateTime fields (no default needed)
- `BaseMultiLanguage` - Multi-language text fields with `@Default(BaseMultiLanguage())`

### Field Naming Conventions

- Use camelCase for field names (e.g., `userName`, `createdAt`)
- Use descriptive names that clearly indicate the field's purpose
- Avoid abbreviations unless they are widely understood

## Checklist

- [ ] Update all models with new fields and default values
- [ ] Update all option models (if applicable)
- [ ] Update all entities to match models
- [ ] Update all option entities (if applicable)
- [ ] Update model extensions for proper entity conversion
- [ ] Update option model extensions (if applicable)
- [ ] Update repository implementations and JSON conversion methods
- [ ] Add new parts to module main file
- [ ] Regenerate generated files
- [ ] Fix any lint errors
- [ ] Test the changes

## Conclusion

Following this guide ensures that all layers of your Clean Architecture module remain consistent when updating data models, preventing runtime errors and maintaining code quality. This approach can be applied to any module in the project by simply providing the path to one of the module's files.
