# feature_clean

A Mason brick for generating Clean Architecture feature modules in Flutter with a flatter structure.

## Features

- **Clean Architecture**: Separates domain, data, and presentation layers while respecting Meup conventions
- **Flatter Structure**: Places feature modules directly under `lib/src/`
- **Flexible Profiles**: Pick presentation/data/domain profiles per feature, or skip entire layers when not needed
- **Code Generation Ready**: Includes Freezed, Retrofit, and Injectable annotations
- **State Management**: Choose between BLoC or Cubit (Cubit is default)
- **Error Handling**: Uses `fpdart` for functional error handling with `TaskEither`
- **Dependency Injection**: Uses `get_it` and `injectable` for DI

## Installation

Add Mason to your Flutter project:

```bash
dart pub global activate mason_cli
```

Add this brick to your project:

```bash
mason add feature_clean --path bricks/feature_clean
```

## Usage

Generate a new feature:

```bash
mason make feature_clean
```

You will be prompted for:

1. **feature_name**: The name of the feature in snake_case (e.g., `user_profile`)
2. **entity_name**: The name of the main business object (PascalCase works best)
3. **use_bloc**: Whether to use BLoC instead of Cubit (default: false)
4. **architecture_profile**: How many layers to scaffold (`presentation_only`, `domain_presentation`, `full_stack`)
5. **presentation_profile**: UI template to start from (`paged_list`, `single_item`, `blank_screen`)
6. **crud_operations**: Comma separated operations to scaffold (`list,detail,create,update,delete`)
7. **include_remote_datasource**: Include Retrofit/Dio API?
8. **include_local_cache**: Include local cache data source?

> Architecture profiles in a nutshell:
> - `presentation_only`: generates only the hub file + page.
> - `domain_presentation`: adds entities, repository contracts, use cases, and state management without data layer.
> - `full_stack`: everything above plus models, datasources, and repositories. Remote/local datasources can be toggled individually.

### Example

```bash
$ mason make feature_clean
? What is the feature name? product
? What is the entity name? Product
? Use BLoC instead of Cubit? false
? Which architecture profile do you need? full_stack
? Which presentation profile fits best? paged_list
? Which CRUD operations do you need? (comma separated) list,detail,create,update,delete
? Include remote data source (Retrofit/Dio)? (Y/n) y
? Include local cache data source? (Y/n) y
```

This will generate (with `full_stack`, BLoC, all CRUD operations, and both datasources enabled):

```
lib/
└── src/
    └── product/
        ├── data/
        │   ├── datasources/
        │   │   └── product_api.dart
        │   ├── models/
        │   │   └── product_model.dart
        │   └── repositories/
        │       └── product_repository.dart
        ├── domain/
        │   ├── entities/
        │   │   └── product_entity.dart
        │   ├── repositories/
        │   │   └── i_product_repository.dart
        │   └── usecases/
        │       ├── create_product_usecase.dart
        │       ├── delete_product_usecase.dart
        │       ├── get_all_products_usecase.dart
        │       ├── get_product_usecase.dart
        │       └── update_product_usecase.dart
        ├── presentation/
        │   ├── cubits/
        │   │   ├── product_cubit.dart
        │   │   └── product_state.dart
        │   └── pages/
        │       └── product_page.dart
        └── product.dart

Depending on the selected profile, the `data/` or `domain/` folders might be omitted entirely, and only the requested use cases/files will be generated.
```

## Post-Generation Steps

1. **Generate Code**: Run code generation to create all generated files:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

2. **Add API Endpoints**: Update `lib/core/constants/manual/endpoint.dart` with your actual API endpoints.

3. **Customize API/Data**: Update the Retrofit API methods in `data/datasources/{{feature_name}}_api.dart` or replace them with your preferred data source.

4. **Update DI**: If you introduce new dependencies, re-run build_runner to refresh Injectable outputs.

5. **Write Tests**: Tests are not generated automatically. Mirror the `lib/src/{{feature_name}}` structure under `test/` and use existing features as inspiration.

## Architecture Details

### Domain Layer
- **Entities**: Pure business objects using Freezed (optional when `presentation_only`)
- **Repository Interfaces**: Abstract contracts for data access
- **Use Cases**: Only the CRUD operations you selected are created, each wrapping `UseCaseWithParams`/`UseCaseWithoutParams`

### Data Layer
- **Models**: Data transfer objects with `toEntity()` method (generated when `full_stack`)
- **Datasources**: Retrofit API + optional local cache, each can be toggled independently
- **Repository Implementation**: Implements domain interfaces with error handling and graceful fallbacks when datasources are disabled

### Presentation Layer
- **State**: Freezed state with status enum
- **Cubit/BLoC**: Injected via `get_it`, now trims unused methods based on CRUD selection
- **Pages**: Choose from `paged_list`, `single_item`, or `blank_screen` templates; the generated screen adapts to the selected state-management strategy or falls back to pure presentation

### Error Handling
Uses `fpdart`'s `TaskEither<AppException, T>` for functional error handling:
- Left side: `AppException` with various types (notFound, server, connection, etc.)
- Right side: Success value
- Chainable operations with `match`, `fold`, and other combinators

### Testing
- Tests are not generated automatically. Follow the clean architecture folder structure inside `test/src/{{feature_name}}` and reuse existing utilities (Mockito, bloc_test, etc.) from the Meup repo.

## Customization

- **State management**: Answer the `use_bloc` prompt or edit `brick.yaml` to change the default.
- **Architecture profiles**: Choose between `presentation_only`, `domain_presentation`, and `full_stack` when running the brick. This controls which layers/directories are emitted.
- **Presentation profiles**: `paged_list`, `single_item`, and `blank_screen` templates cover the main onboarding cases. Pick the one that best matches your UX before you start wiring widgets.
- **CRUD/Use cases**: Provide a comma-separated list of operations. Only the requested repository methods, use cases, and Cubit/BLoC methods are generated.
- **Datasources**: Toggle the remote Retrofit client or local cache independently when using `full_stack`.
- **Entities/Models**: Edit the generated files directly (`domain/entities/...` and `data/models/...`) to add fields. Rerun build_runner afterwards.
- **Additional use cases**: Follow the existing pattern—create a new file under `domain/usecases`, add a `part` directive inside the hub file, extend the repository contract, and inject the use case into your Cubit/BLoC.

## Best Practices

1. **Keep Domain Pure**: Domain layer should have no dependencies on data or presentation layers
2. **Use Task Either**: Always use `TaskEither` for async operations that can fail
3. **Test Everything**: Write tests for use cases, repositories, and cubits/blocs
4. **Update Exports**: Only export what's needed in the feature hub file
5. **Handle All States**: Always handle initial, loading, success, and failure states in UI

## License

This brick is part of the Meup Flutter project and follows the project's license.
