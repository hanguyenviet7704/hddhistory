Description: Create complete Clean Architecture feature (Domain + Data layers) by analyzing similar patterns

# Setup New Feature

## What This Does
Creates a complete feature following Clean Architecture with:
- **Domain Layer**: Entities, repository interfaces, use cases
- **Data Layer**: Models with JSON serialization, repository implementations, API/GraphQL clients
- **Cubit** (optional): State management with HydratedCubit
- **Tests**: Scaffolds for all layers

**Uses intelligent exploration** to find similar features in your codebase and follow established patterns.

## When to Use
- Starting a new feature that needs backend integration
- Creating feature with REST API or GraphQL data source
- Need complete Clean Architecture layers generated
- Want to follow existing project patterns automatically

**Not for UI** - Use `/update-new-ux-ui` for presentation layer implementation.

## Required Context
Provide ONE of the following:
- Feature requirements or ticket description
- API endpoint documentation or contracts
- GraphQL schema/queries for the feature
- Path to similar existing feature as reference

## Command Flow

### 1. Ask Questions
Uses `AskUserQuestion` to gather:
```
1. Feature name (e.g., "user_notifications", "payment_history")
2. Data source type:
   - REST API
   - GraphQL
   - Local storage only
   - None (domain-only logic)
3. State management needed:
   - Yes (create Cubit)
   - No (skip presentation layer)
```

### 2. Explore Codebase
Spawns **Task agent (Explore)** to:
- Find 2-3 similar features in project
- Analyze their structure and patterns
- Identify which mixin to use (GraphQLRequestHandlerMixin vs RestfulRequestHandlerMixin)
- Note naming conventions and file organization

Example exploration:
```
Task: "Find similar features that use GraphQL data source.
      Analyze lib/src/*/domain/ and lib/src/*/data/ structure.
      Return: file paths, patterns used, repository implementations"
```

### 3. Create Todo Tracking
Uses `TodoWrite` to track:
```
☐ Create domain layer (entities, repositories, use cases)
☐ Create data layer (models, repositories, data sources)
☐ Create presentation layer (cubits) [if requested]
☐ Create test scaffolds
☐ Run code generation
☐ Validate build
```

### 4. Generate Domain Layer
Creates in `lib/src/[feature]/domain/`:

**Entity** (`entities/[feature]/[feature]_entity.dart`):
```dart
part of '../entities.dart';

@freezed
class [Feature]Entity with _$[Feature]Entity {
  const factory [Feature]Entity({
    @Default('') String id,
    @Default('') String name,
    // Fields based on requirements
  }) = _[Feature]Entity;

  factory [Feature]Entity.fromJson(Map<String, dynamic> json) =>
      _$[Feature]EntityFromJson(json);
}
```

**Repository Interface** (`repositories/i_[feature]_repository.dart`):
```dart
abstract interface class I[Feature]Repository {
  Future<Either<AppException, [Feature]Entity>> get[Feature](String id);
  Future<Either<AppException, List<[Feature]Entity>>> get[Feature]List();
  // Methods based on requirements
}
```

**Use Cases** (`usecases/[feature]/`):
```dart
@lazySingleton
class Get[Feature]UseCase extends UseCaseWithParams<[Feature]Entity, Get[Feature]Params> {
  final I[Feature]Repository _repository;
  Get[Feature]UseCase(this._repository);

  @override
  Future<Either<AppException, [Feature]Entity>> call(Get[Feature]Params params) =>
      _repository.get[Feature](params.id);
}

@freezed
class Get[Feature]Params with _$Get[Feature]Params {
  const factory Get[Feature]Params({required String id}) = _Get[Feature]Params;
}
```

**Updates part files**:
- Adds `part 'entities/[feature]/[feature]_entity.dart';` to `entities.dart`
- Adds `part 'usecases/[feature]/...dart';` to `usecases.dart`

### 5. Generate Data Layer
Creates in `lib/src/[feature]/data/`:

**Model** (`models/[feature]/[feature]_model.dart`):
```dart
part of '../models.dart';

@freezed
class [Feature]Model with _$[Feature]Model {
  const factory [Feature]Model({
    @Default('') String id,
    @Default('') String name,
    // Fields matching API response
  }) = _[Feature]Model;

  factory [Feature]Model.fromJson(Map<String, dynamic> json) =>
      _$[Feature]ModelFromJson(json);
}

extension [Feature]ModelExtension on [Feature]Model {
  [Feature]Entity toEntity() => [Feature]Entity(
    id: id,
    name: name,
    // Map all fields
  );
}
```

**Repository Implementation** (`repositories/[feature]_repository.dart`):

For GraphQL:
```dart
@LazySingleton(as: I[Feature]Repository)
class [Feature]Repository
    with GraphQLRequestHandlerMixin
    implements I[Feature]Repository {
  final GraphQLClient graphqlClient;

  [Feature]Repository(@Named(DIKey.appGraphql) this.graphqlClient);

  @override
  Future<Either<AppException, [Feature]Entity>> get[Feature](String id) async {
    return callGraphQL(
      queryCall: () => graphqlClient.query$Get[Feature](
        Options$Query$Get[Feature](
          variables: Variables$Query$Get[Feature](id: id),
        ),
      ),
      dataExtractor: (data) => data?.item?.toModel()?.toEntity(),
    );
  }
}
```

For REST API:
```dart
@LazySingleton(as: I[Feature]Repository)
class [Feature]Repository
    with RestfulRequestHandlerMixin
    implements I[Feature]Repository {
  final [Feature]Api api;

  [Feature]Repository(this.api);

  @override
  Future<Either<AppException, [Feature]Entity>> call(Map<String, dynamic> params) async {
    return callApi(
      apiCall: () => api.get[Feature](params),
      transform: (response) => response.toModel().toEntity(),
    );
  }
}
```

**Data Source** (if REST API):
- Creates Retrofit API client in `datasources/apis/[feature]_api.dart`
- Or GraphQL queries in `datasources/graphql/template/[feature].graphql`

**Updates part files**:
- Adds parts to `models.dart` and `repositories.dart`

### 6. Create Presentation Layer (Optional)
If state management requested, creates in `lib/src/[feature]/presentation/cubits/`:

```dart
@injectable
class [Feature]Cubit extends HydratedCubit<[Feature]State> {
  final Get[Feature]UseCase _getUseCase;

  [Feature]Cubit(this._getUseCase) : super(const [Feature]State.initial());

  Future<void> load(String id) async {
    emit(const [Feature]State.loading());
    final result = await _getUseCase(Get[Feature]Params(id: id));
    result.fold(
      (error) => emit([Feature]State.error(error)),
      (data) => emit([Feature]State.success(data)),
    );
  }

  @override
  [Feature]State? fromJson(Map<String, dynamic> json) => null;

  @override
  Map<String, dynamic>? toJson([Feature]State state) => null;
}

@freezed
class [Feature]State with _$[Feature]State {
  const factory [Feature]State.initial() = _Initial;
  const factory [Feature]State.loading() = _Loading;
  const factory [Feature]State.success([Feature]Entity data) = _Success;
  const factory [Feature]State.error(AppException error) = _Error;
}
```

### 7. Create Test Scaffolds
Creates in `test/unit/`:
- `domain/usecases/[feature]/get_[feature]_usecase_test.dart`
- `data/repositories/[feature]/[feature]_repository_test.dart`
- `presentation/cubits/[feature]/[feature]_cubit_test.dart` (if cubit created)

Test template:
```dart
void main() {
  group('[Feature]UseCase', () {
    late [Feature]UseCase useCase;
    late Mock[Feature]Repository mockRepository;

    setUp(() {
      mockRepository = Mock[Feature]Repository();
      useCase = [Feature]UseCase(mockRepository);
    });

    test('should return entity when successful', () async {
      // Arrange
      const params = Get[Feature]Params(id: 'test-id');
      final entity = [Feature]Entity(id: 'test-id', name: 'Test');
      when(() => mockRepository.get[Feature](any()))
          .thenAnswer((_) async => Right(entity));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, Right(entity));
      verify(() => mockRepository.get[Feature](any())).called(1);
    });
  });
}
```

### 8. Run Code Generation
Executes sequentially:
```bash
dart run build_runner build --delete-conflicting-outputs
```

Generates:
- `*.freezed.dart` - Freezed classes
- `*.g.dart` - JSON serialization
- DI configuration updates

### 9. Validate Build
Checks:
- ✅ All files compile without errors
- ✅ DI registration successful
- ✅ Code generation completed
- ✅ No analyze errors
- ✅ Imports resolved

Uses `flutter analyze` to verify.

## Output Format

```
✅ Feature '[feature_name]' Created

📦 Domain Layer
- [Feature]Entity with X fields
- I[Feature]Repository interface
- X use cases created:
  • Get[Feature]UseCase
  • [Other]UseCase

📦 Data Layer
- [Feature]Model with toEntity() extension
- [Feature]Repository implementation ([GraphQL/REST API])
- [API client/GraphQL queries] configured
- Part files updated

📦 Presentation Layer
- [Feature]Cubit with 4 states
- Registered in DI

🧪 Tests
- X test scaffolds created
- Ready for implementation

🔧 Build Status
- ✅ Code generation successful
- ✅ All files compile
- ✅ DI registration verified
- ✅ flutter analyze passed

📁 Files Created
lib/src/[feature]/
  domain/
    entities/[feature]/[feature]_entity.dart
    repositories/i_[feature]_repository.dart
    usecases/[feature]/get_[feature]_usecase.dart
  data/
    models/[feature]/[feature]_model.dart
    repositories/[feature]_repository.dart
    datasources/[...]
  presentation/
    cubits/[feature]/[feature]_cubit.dart

🎯 Next Steps
1. Implement repository logic based on API contracts
2. Add additional use cases if needed
3. Use /update-new-ux-ui for UI implementation
4. Write test implementations
5. Add localization keys if needed
```

## Example Usage

### Example 1: GraphQL Feature
```
User: /setup-new-feature
      "Need to implement user notifications feature.
       GraphQL endpoint: query userNotifications { ... }"

Claude: Questions:
        1. Feature name? → user_notifications
        2. Data source? → GraphQL
        3. State management? → Yes

        [Explores codebase for GraphQL patterns]
        [Finds profile feature as reference]
        [Creates all layers following profile pattern]
        [Uses GraphQLRequestHandlerMixin]

        ✅ Complete in 45 seconds
        [Shows detailed output above]
```

### Example 2: REST API Feature
```
User: /setup-new-feature
      "Payment history feature, REST API at /api/payments"

Claude: Questions:
        1. Feature name? → payment_history
        2. Data source? → REST API
        3. State management? → Yes

        [Explores for REST API patterns]
        [Creates Retrofit API client]
        [Uses RestfulRequestHandlerMixin]

        ✅ Complete
        [Shows detailed output]
```

## Advanced Features

### Intelligent Pattern Detection
- Automatically detects if project uses singular vs plural naming
- Follows existing file organization patterns
- Uses same import structure as similar features
- Maintains consistent code style

### Parallel File Creation
Creates all files simultaneously when possible:
- Entity + Model in parallel
- Repository interface + implementation in parallel
- Multiple use cases at once

### Smart Validation
Checks for common issues:
- Missing @Default annotations
- Incorrect part directives
- DI registration conflicts
- Import errors

### Context Preservation
References found patterns:
```
"Following pattern from lib/src/profile/ (similar GraphQL feature)
 - Using GraphQLRequestHandlerMixin
 - Using callGraphQL with dataExtractor pattern
 - Implementing HydratedCubit for state persistence"
```

---

*See CLAUDE.md: Clean Architecture section for detailed architectural patterns*
*See CLAUDE.md: Dependency Injection section for DI conventions*
*See CLAUDE.md: Code Generation section for build_runner workflows*
