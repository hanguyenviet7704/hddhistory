---
trigger: model_decision
description: Workflow for /setup-new-feature (Setup New Feature)
---

# Setup New Feature

## Invocation
Use only when the user explicitly requests `/setup-new-feature` or asks to run this workflow.
Ask the listed questions first, then execute the steps.

## Usage
Provide one of:
- Ticket/requirement description
- API/GraphQL endpoint documentation
- Reference to similar existing feature

## Agent Questions (Ask First)
1. **Feature name** (e.g., "user_notifications", "payment_history")
2. **Data source**: REST API | GraphQL | Local | None (UI-only)
3. **Needs state management**: Yes (BLoC/Cubit) | No
4. **Skip UI layer**: Yes (default) | No (only if explicitly requested)

## Auto-Execute After Questions

### 1. Find Similar Patterns
- Search codebase for similar features
- Identify pattern to follow (REST vs GraphQL vs Local)

### 2. Create Domain Layer
```
lib/src/[feature]/
├── domain/
│   ├── entities/
│   │   └── [feature]_entity.dart
│   ├── repositories/
│   │   └── i_[feature]_repository.dart
│   └── usecases/
│       ├── get_[feature]_usecase.dart
│       └── [other]_usecases.dart
```

**Auto-generate:**
- Entity with Freezed & JSON serialization
- Repository interface with TaskEither<AppException, T> returns
- Use cases with params classes
- Add parts to `entities.dart` and `usecases.dart`

### 3. Create Data Layer
```
lib/src/[feature]/
├── data/
│   ├── models/
│   │   └── [feature]_model.dart
│   ├── datasources/
│   │   ├── remote/
│   │   │   └── [feature]_api.dart (if REST)
│   │   ├── local/
│   │   │   └── [feature]_local_data_source.dart (if caching)
│   │   └── graphql/
│   │       └── template/[feature].graphql (if GraphQL)
│   └── repositories/
│       └── [feature]_repository.dart
```

**Auto-generate:**
- Model with Freezed & JSON serialization
- Extension `toEntity()` for model → entity conversion
- Repository implementation with proper mixins
- API client or GraphQL queries
- Add parts to `models.dart` and `repositories.dart`

### 4. Create Presentation Layer (Only if user says Yes)
```
lib/src/[feature]/
└── presentation/
    ├── cubits/
    │   ├── [feature]_cubit.dart
    │   └── [feature]_state.dart
    └── pages/
        └── [Optional - usually done via update-new-ux-ui]
```

**Auto-generate:**
- Cubit with HydratedCubit
- State with Freezed (initial, loading, success, error)
- Register in DI

### 5. Run Build & Verify
```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

### 6. Create Test Structure
```
test/unit/
└── [feature]/
    ├── domain/usecases/
    ├── data/repositories/
    └── presentation/cubits/
```

**Auto-generate test scaffolds**

## Output
```
✅ Feature '[feature_name]' created

Domain Layer:
- [Feature]Entity created
- I[Feature]Repository interface created
- X use cases created

Data Layer:
- [Feature]Model created with toEntity()
- [Feature]Repository implementation created
- [API/GraphQL] client configured

Presentation Layer:
- [Cubit created | Skipped (use /update-new-ux-ui for UI)]

Tests:
- X test scaffolds created

Build Status:
- ✅ Code generation successful
- ✅ No analyze errors

Next Steps:
1. Implement repository logic in [feature]_repository.dart
2. Add localization keys if needed
3. For UI: use /update-new-ux-ui command with Figma link
```

## Technical Templates (Auto-Applied)

### Entity
```dart
part of '../entities.dart';

@freezed
class [Feature]Entity with _$[Feature]Entity {
  const factory [Feature]Entity({
    @Default('') String id,
    // Fields from API/requirements
  }) = _[Feature]Entity;

  factory [Feature]Entity.fromJson(Map<String, dynamic> json) =>
      _$[Feature]EntityFromJson(json);
}
```

### Repository Interface
```dart
abstract interface class I[Feature]Repository {
  TaskEither<AppException, [Feature]Entity> get[Feature](String id);
  TaskEither<AppException, List<[Feature]Entity>> get[Feature]List();
}
```

### Model with Extension
```dart
part of '../models.dart';

@freezed
class [Feature]Model with _$[Feature]Model {
  const factory [Feature]Model({
    @Default('') String id,
    // Fields matching API response
  }) = _[Feature]Model;

  factory [Feature]Model.fromJson(Map<String, dynamic> json) =>
      _$[Feature]ModelFromJson(json);
}

extension [Feature]ModelExtension on [Feature]Model {
  [Feature]Entity toEntity() => [Feature]Entity(
    id: id,
    // Map fields
  );
}
```

### Repository Implementation (GraphQL)
```dart
@LazySingleton(as: I[Feature]Repository)
class [Feature]Repository with GraphQLRequestHandlerMixin implements I[Feature]Repository {
  final GraphQLClient graphqlClient;
  [Feature]Repository(@Named(DIKey.appGraphql) this.graphqlClient);

  @override
  TaskEither<AppException, [Feature]Entity> get[Feature](String id) {
    return callGraphQL(
      queryCall: () => graphqlClient.query$Get[Feature](...),
      dataExtractor: (data) => data?.item?.toModel()?.toEntity(),
    );
  }
}
```

### Use Case
```dart
part of '../usecases.dart';

@lazySingleton
class Get[Feature]UseCase extends UseCaseWithParams<[Feature]Entity, Get[Feature]Params> {
  final I[Feature]Repository _repository;
  Get[Feature]UseCase(this._repository);

  @override
  TaskEither<AppException, [Feature]Entity> call(Get[Feature]Params params) =>
      _repository.get[Feature](params.id);
}

@freezed
class Get[Feature]Params with _$Get[Feature]Params {
  const factory Get[Feature]Params({required String id}) = _Get[Feature]Params;
}
```

### Cubit (if requested)
```dart
part of '../cubits.dart';

@injectable
class [Feature]Cubit extends Cubit<[Feature]State>
    with CubitUseCaseHandlerMixin<[Feature]State> {
  final Get[Feature]UseCase _getUseCase;

  [Feature]Cubit(this._getUseCase) : super(const [Feature]State.initial());

  Future<void> load(String id) async {
    await runUseCase<[Feature]Entity>(
      usecase: () => _getUseCase(Get[Feature]Params(id: id)),
      buildLoadingState: () => const [Feature]State.loading(),
      onFailure: (error) {
        emit([Feature]State.error(error));
      },
      onSuccess: (data) {
        emit([Feature]State.success(data));
      },
    );
  }
}

@freezed
class [Feature]State with _$[Feature]State {
  const factory [Feature]State.initial() = _Initial;
  const factory [Feature]State.loading() = _Loading;
  const factory [Feature]State.success([Feature]Entity data) = _Success;
  const factory [Feature]State.error(AppException error) = _Error;
}
```
