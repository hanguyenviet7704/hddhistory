# feature_clean

A Mason brick for generating Clean Architecture feature modules in Flutter with a flatter structure.

## Features

- **Clean Architecture**: Separates domain, data, and presentation layers
- **Flatter Structure**: Places feature modules directly under `lib/src/`
- **Code Generation Ready**: Includes Freezed, Retrofit, and Injectable annotations
- **State Management**: Choose between BLoC or Cubit (Cubit is default)
- **Error Handling**: Uses `fpdart` for functional error handling with `TaskEither`
- **Dependency Injection**: Uses `get_it` and `injectable` for DI
- **Testing**: Complete test setup with Mockito and bloc_test

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
2. **entity_name**: The name of the main business object in PascalCase (e.g., `UserProfile`)
3. **use_bloc**: Whether to use BLoC instead of Cubit (default: false)

### Example

```bash
$ mason make feature_clean
? What is the feature name? product
? What is the entity name? Product
? Use BLoC instead of Cubit? false
```

This will generate:

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

test/
└── src/
    └── product/
        ├── data/
        │   └── repositories/
        │       └── product_repository_test.dart
        ├── domain/
        │   └── usecases/
        │       └── get_product_usecase_test.dart
        ├── presentation/
        │   └── cubits/
        │       └── product_cubit_test.dart
        └── product_mocks.dart
```

## Post-Generation Steps

1. **Generate Code**: Run code generation to create all generated files:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

2. **Generate Mocks**: Generate mock files for testing:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. **Update DI Configuration**: If needed, regenerate dependency injection:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Add API Endpoint**: Update `lib/core/constants/manual/endpoint.dart` with your actual API endpoints

5. **Customize API**: Update the Retrofit API methods in `data/datasources/{{feature_name}}_api.dart`

6. **Run Tests**: Verify everything works:
   ```bash
   flutter test test/src/{{feature_name}}/
   ```

## Architecture Details

### Domain Layer
- **Entities**: Pure business objects using Freezed
- **Repository Interfaces**: Abstract contracts for data access
- **Use Cases**: Business logic operations using `UseCaseWithParams` or `UseCaseWithoutParams`

### Data Layer
- **Models**: Data transfer objects with `toEntity()` method
- **Retrofit API**: Type-safe REST client
- **Repository Implementation**: Implements domain interfaces with error handling

### Presentation Layer
- **State**: Freezed state with status enum (initial, loading, success, failure)
- **Cubit/BLoC**: State management with dependency injection
- **Page**: Basic UI with error handling and loading states

### Error Handling
Uses `fpdart`'s `TaskEither<AppException, T>` for functional error handling:
- Left side: `AppException` with various types (notFound, server, connection, etc.)
- Right side: Success value
- Chainable operations with `match`, `fold`, and other combinators

### Testing
- **Mocks**: Generated using Mockito's `@GenerateMocks`
- **Unit Tests**: For use cases and repositories
- **Cubit/BLoC Tests**: Using `bloc_test` package
- **Test Structure**: Mirrors the lib structure

## Customization

### Change Default State Management
Edit `brick.yaml` to change the default from Cubit to BLoC:

```yaml
use_bloc:
  type: boolean
  description: Use BLoC instead of Cubit
  default: true  # Changed from false
  prompt: Use BLoC instead of Cubit?
```

### Add More Use Cases
Follow the existing patterns in `domain/usecases/` and update:
1. Create the new usecase file
2. Add `part` directive in the main feature file
3. Inject into Cubit/BLoC
4. Add corresponding test file

### Customize Entity/Model Fields
Edit the template files:
- `domain/entities/{{entity_name.snakeCase()}}_entity.dart`
- `data/models/{{entity_name.snakeCase()}}_model.dart`

## Best Practices

1. **Keep Domain Pure**: Domain layer should have no dependencies on data or presentation layers
2. **Use Task Either**: Always use `TaskEither` for async operations that can fail
3. **Test Everything**: Write tests for use cases, repositories, and cubits/blocs
4. **Update Exports**: Only export what's needed in the feature hub file
5. **Handle All States**: Always handle initial, loading, success, and failure states in UI

## License

This brick is part of the Meup Flutter project and follows the project's license.
