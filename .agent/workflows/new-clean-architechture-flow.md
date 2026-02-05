---
trigger: model_decision
description: Workflow for /new-clean-architechture-flow (Clean Architecture Flow Implementation Guide)
---

# Clean Architecture Flow Implementation Guide

## Invocation
Use only when the user explicitly requests `/new-clean-architechture-flow` or asks to run this workflow.
Ask the listed questions first, then execute the steps.

This guide provides step-by-step instructions for implementing new features following the Clean Architecture pattern used in the Meup Flutter project.

## Architecture Layers

The project follows Clean Architecture with three main layers:

1. **Domain Layer** (`lib/src/<feature>/domain/`): Business logic, entities, repository interfaces, and use cases
2. **Data Layer** (`lib/src/<feature>/data/`): Repository implementations, data sources (API/GraphQL), and data models
3. **Presentation Layer** (`lib/src/<feature>/presentation/`): UI, BLoC/Cubit state management, pages, and widgets

## Implementation Steps

### Step 1: Analyze Data Sources

Review existing data sources to understand the available APIs and GraphQL queries:

- **REST API**: Check `lib/src/<feature>/data/datasources/remote/` for API definitions
- **GraphQL**: Check `lib/src/<feature>/data/datasources/graphql/template/` for GraphQL queries

### Step 2: Define Repository Interface (Domain Layer)

1. Navigate to `lib/src/<feature>/domain/repositories/`
2. Open or create the repository interface file (e.g., `i_picture_study_repository.dart`)
3. Add method signatures that define the contract:

```dart
abstract interface class IFeatureRepository {
  TaskEither<AppException, List<[Entity]>> getItems({
    required String param1,
    required String param2,
  });

  TaskEither<AppException, [Entity]> getItem({
    required String id,
  });

  TaskEither<AppException, [Entity]> submitData(Map<String, dynamic> data);
}
```

### Step 3: Create/Update Data Models

1. Navigate to `lib/src/<feature>/data/models/`
2. Create or update Freezed models with proper serialization:

```dart
part of '../models.dart';

@freezed
abstract class ModelName with _$ModelName {
  const factory ModelName({
    @Default('') String id,
    @Default('') String name,
  }) = _ModelName;

  factory ModelName.fromJson(Map<String, dynamic> json) => _$ModelNameFromJson(json);
}
```

3. Add GraphQL/API mapper extensions if needed:

```dart
// For GraphQL responses
extension QueryModelExtension on List<Query$GetItems$items> {
  List<ModelName> toModels() => map((e) => ModelName.fromJson(e.toJson())).toList();
}

// For single GraphQL response
extension QuerySingleModelExtension on Query$GetItem$item$data {
  ModelName toModel() => ModelName.fromJson(toJson());
}
```

### Step 4: Implement Repository (Data Layer)

1. Navigate to `lib/src/<feature>/data/repositories/`
2. Open or create the repository implementation file (e.g., `feature_repository.dart`)
3. Implement the interface with proper mixins:

```dart
part of 'repositories.dart';

@LazySingleton(as: IFeatureRepository)
class FeatureRepository with GraphQLRequestHandlerMixin, RestfulRequestHandlerMixin implements IFeatureRepository {
  final GraphQLClient graphqlClient;
  final FeatureApi featureApi;

  FeatureRepository(@Named(DIKey.appGraphql) this.graphqlClient, this.featureApi);

  @override
  TaskEither<AppException, List<[Entity]>> getItems({
    required String param1,
    required String param2,
  }) {
    return callGraphQLList(
      queryCall: () => graphqlClient.query$GetItems(
        Options$Query$GetItems(
          variables: Variables$Query$GetItems(
            param1: param1,
            param2: param2,
          ),
        ),
      ),
      dataExtractor: (data) =>
          data?.items.toModels().map((model) => model.toEntity()).toList() ?? [],
    );
  }

  @override
  TaskEither<AppException, [Entity]> getItem({
    required String id,
  }) {
    return callGraphQL(
      queryCall: () => graphqlClient.query$GetItem(
        Options$Query$GetItem(
          variables: Variables$Query$GetItem(id: id),
        ),
      ),
      dataExtractor: (data) => data?.item.data?.toModel().toEntity(),
    );
  }

  @override
  TaskEither<AppException, [Entity]> submitData(Map<String, dynamic> data) {
    return callApi(
      apiCall: () => featureApi.submitData(data),
      dataExtractor: (response) => response.data?.toModel().toEntity(),
    );
  }
}
```

### Step 5: Create Use Cases (Domain Layer)

1. Navigate to `lib/src/<feature>/domain/usecases/`
2. Create use case files following this pattern:

```dart
part of '../usecases.dart';

class GetItemsParams {
  final String param1;
  final String param2;

  GetItemsParams({
    required this.param1,
    required this.param2,
  });
}

@lazySingleton
class GetItemsUseCase implements UseCaseWithParams<GetItemsParams, List<[Entity]>> {
  final IFeatureRepository _featureRepository;
  GetItemsUseCase(this._featureRepository);

  @override
  TaskEither<AppException, List<[Entity]>> call(GetItemsParams params) =>
      _featureRepository.getItems(
        param1: params.param1,
        param2: params.param2,
      );
}
```

For use cases without parameters:

```dart
@lazySingleton
class GetItemUseCase implements UseCaseWithoutParams<[Entity]> {
  final IFeatureRepository _featureRepository;
  GetItemUseCase(this._featureRepository);

  @override
  TaskEither<AppException, [Entity]> call() =>
      _featureRepository.getItem();
}
```

3. Register use cases in `lib/src/<feature>/domain/usecases/usecases.dart`:

```dart
//? Feature usecases
part 'feature_name/get_items_usecase.dart';
part 'feature_name/get_item_usecase.dart';
part 'feature_name/submit_data_usecase.dart';
```

### Step 6: Run Code Generation

After implementing all layers, run code generation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates:
- Freezed models (`*.freezed.dart`)
- JSON serialization (`*.g.dart`)
- Dependency injection (`di.g.dart`)
- GraphQL code (if GraphQL schemas changed)

### Step 7: Verify Implementation

1. Check for compilation errors
2. Verify dependency injection is working
3. Test the data flow from presentation to data layer

## Common Patterns

### GraphQL Response Handling

For list responses:
```dart
return callGraphQLList(
  queryCall: () => graphqlClient.query$GetItems(...),
  dataExtractor: (data) => data?.items.toModels() ?? [],
);
```

For single item responses:
```dart
return callGraphQL(
  queryCall: () => graphqlClient.query$GetItem(...),
  dataExtractor: (data) {
    final itemData = data?.item.data;
    return itemData != null ? itemData.toModel() : null;
  },
);
```

### REST API Handling

```dart
return callApi(apiCall: () => api.submitData(data));
```

### Repository Mixins

- Use `GraphQLRequestHandlerMixin` for GraphQL operations
- Use `RestfulRequestHandlerMixin` for REST API operations
- Can use both mixins together if needed

## File Structure Example

```
lib/
└── src/
    └── <feature>/
        ├── domain/
        │   ├── entities/
        │   │   └── feature_entity.dart
        │   ├── repositories/
        │   │   └── i_feature_repository.dart
        │   └── usecases/
        │       ├── get_items_usecase.dart
        │       ├── get_item_usecase.dart
        │       └── submit_data_usecase.dart
        ├── data/
        │   ├── models/
        │   │   ├── model_name.dart
        │   │   └── related_model.dart
        │   ├── datasources/
        │   │   ├── remote/
        │   │   │   └── feature_api.dart
        │   │   └── graphql/
        │   │       └── template/
        │   │           └── feature.graphql
        │   └── repositories/
        │       └── feature_repository.dart
        └── presentation/
            └── (implemented by presentation team)
```

## Tips

1. **Always follow the existing code patterns** in the project
2. **Use TaskEither<AppException, T>** for all repository and use case return types
3. **Add mapper extensions** in model files for GraphQL responses
4. **Run code generation** after any changes to models or GraphQL
5. **Use proper annotations**: `@LazySingleton` for repositories, `@lazySingleton` for use cases
6. **Named parameters** are preferred for better code readability
7. **Handle null safety** properly in data extractors

## Related Documentation

- See `CLAUDE.md` for overall project structure
- See `lib/core/base/use_case/use_case.dart` for use case base classes
- See existing repositories in `lib/src/<feature>/data/repositories/` for reference implementations
