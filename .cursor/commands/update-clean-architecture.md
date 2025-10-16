# Update Clean Architecture Module Guide

This guide provides a step-by-step process for updating a Clean Architecture module in the Flutter project when the data model changes.

## Overview

When updating a module's data model, you need to ensure all layers of the Clean Architecture are properly updated to maintain consistency and avoid runtime errors.

## Steps to Update a Clean Architecture Module

### 1. Update Models

First, update the data models in the `data/models/` directory:

```dart
// Example: OnboardModel
@freezed
abstract class OnboardModel with _$OnboardModel {
  const factory OnboardModel({
    @Default('') String id,  // Add default values for non-nullable fields
    @Default(false) bool isNativeEnglishSpeaker,
    @Default('') String comfortableLearningTime,
    // ... other fields
  }) = _OnboardModel;

  factory OnboardModel.fromJson(Map<String, dynamic> json) => _$OnboardModelFromJson(json);
}
```

### 2. Update Entities

Update the domain entities in the `domain/entities/` directory to match the models:

```dart
// Example: OnboardEntity
@freezed
abstract class OnboardEntity with _$OnboardEntity {
  const factory OnboardEntity({
    @Default('') String id,  // Add default values for non-nullable fields
    @Default(false) bool isNativeEnglishSpeaker,
    @Default('') String comfortableLearningTime,
    // ... other fields
  }) = _OnboardEntity;

  factory OnboardEntity.fromJson(Map<String, dynamic> json) => _$OnboardEntityFromJson(json);
}
```

### 3. Update Model Extensions

Update the `toEntity()` method in model extensions to properly convert models to entities:

```dart
extension OnboardModelExtension on OnboardModel {
  OnboardEntity toEntity() => OnboardEntity(
    id: id,
    isNativeEnglishSpeaker: isNativeEnglishSpeaker,
    comfortableLearningTime: comfortableLearningTime,
    // For list fields, map each item to its entity
    topicsWantToMaster: topicsWantToMaster.map((model) => model.toEntity()).toList(),
    // ... other fields
  );
}
```

### 4. Update Repository Implementation

Update the repository implementation in `data/repositories/` to handle the new model structure:

```dart
@override
TaskEither<AppException, OnboardEntity> createOnboard(OnboardEntity entity) {
  return TaskEither.tryCatch(
    () async {
      final model = OnboardModel(
        id: entity.id,
        isNativeEnglishSpeaker: entity.isNativeEnglishSpeaker,
        // For list fields, map each entity to its model
        topicsWantToMaster: entity.topicsWantToMaster.map((e) => OnboardOptionModel(
          isNativeEnglishSpeaker: e.isNativeEnglishSpeaker,
          // ... other fields
        )).toList(),
        // ... other fields
      );
      final result = await _api.createOnboard(model);
      return result.toEntity();
    },
    (error, stackTrace) {
      // Error handling
    },
  );
}
```

### 5. Update Module Parts

Ensure all new files are added to the module's main file:

```dart
// In onboard.dart
part 'domain/entities/onboard_entity.dart';
part 'domain/entities/onboard_option_entity.dart';  // Add new entity parts
// ... other parts
```

### 6. Regenerate Generated Files

Run the build runner to regenerate Freezed and JSON serialization files:

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 7. Check for Lint Errors

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
```

### API Compatibility

If your API requires specific fields (like `id`), ensure they are included in both the model and entity, even if they're not part of the core business logic.

### List Field Conversion

When converting between models and entities with list fields, always map each item individually:

```dart
// Model to Entity
topicsWantToMaster: topicsWantToMaster.map((model) => model.toEntity()).toList(),

// Entity to Model
topicsWantToMaster: entity.topicsWantToMaster.map((e) => OnboardOptionModel(
  // ... field mappings
)).toList(),
```

### Error Handling

Maintain consistent error handling patterns in repositories:

```dart
(error, stackTrace) {
  if (error is DioException) {
    return AppException.fromDioException(error);
  }
  return AppException.unexpected(error.toString());
},
```

## Common Issues and Solutions

### Issue: "The parameter 'field' is non-nullable but is neither required nor marked with @Default"

**Solution**: Add `@Default` annotation to all non-nullable fields in Freezed models and entities.

### Issue: "The argument type 'List<Model>' can't be assigned to the parameter type 'List<Entity>'"

**Solution**: Use `.map()` to convert each item in the list from model to entity or vice versa.

### Issue: "The getter 'field' isn't defined for the type 'Entity'"

**Solution**: Ensure the field exists in the entity definition and that the generated files are up to date.

## Checklist

- [ ] Update all models with new fields and default values
- [ ] Update all entities to match models
- [ ] Update model extensions for proper entity conversion
- [ ] Update repository implementations
- [ ] Add new parts to module main file
- [ ] Regenerate generated files
- [ ] Fix any lint errors
- [ ] Test the changes

## Conclusion

Following this guide ensures that all layers of your Clean Architecture module remain consistent when updating data models, preventing runtime errors and maintaining code quality.
