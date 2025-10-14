# Unit Testing in Meup

This directory contains unit tests for the Meup project, organized according to the Clean Architecture structure of the project.

## Directory Structure

```
test/unit/
├── domain/
│   ├── repositories/
│   └── usecases/
│       └── auth/
│           └── login_usecase_test.dart
└── data/
    ├── datasources/
    └── repositories/
```

## Writing Tests for UseCase Classes

UseCase classes in Meup follow the Clean Architecture pattern and implement either `UseCaseWithParams<Params, Result>` or `UseCaseWithoutParams<Result>` interfaces.

### Test Structure

When writing tests for UseCase classes, follow this structure:

1. **Setup**: Create the necessary mocks and initialize the usecase under test
2. **Test Data**: Define test data for different scenarios
3. **Test Cases**: Write test cases that cover:
   - Success scenarios
   - Failure scenarios
   - Edge cases

### Example Structure for UseCase Tests

```dart
void main() {
  late YourUsecase usecase;
  late MockRepository mockRepository;

  setUp(() {
    mockRepository = MockRepository();
    usecase = YourUsecase(mockRepository);
  });

  group('YourUsecase', () {
    // Define test data
    final testData = {...};

    test('should return success data when repository returns successful result', () async {
      // Arrange - Setup the mock repository to return successful data
      
      // Act - Call the usecase
      final result = await usecase(testParams);
      
      // Assert - Verify the result and mock interactions
    });

    test('should return failure when repository returns error', () async {
      // Arrange - Setup the mock repository to return failure
      
      // Act - Call the usecase
      final result = await usecase(testParams);
      
      // Assert - Verify the result and mock interactions
    });
    
    // Additional tests for edge cases...
  });
}
```

### Using Mocks

#### Manual Mocking

For simple usecases, you can manually mock dependencies like this:

```dart
class MockRepository implements IRepository {
  // Define fields to store mock data and parameters
  Result? _returnValue;
  Params? _receivedParams;

  // Configure the mock
  void mockMethod(Result result) {
    _returnValue = result;
  }

  // Override the repository methods
  @override
  Future<Result> method(Params params) async {
    _receivedParams = params;
    return _returnValue ?? throwDefaultError();
  }

  // Add getters to verify interaction
  Params? getReceivedParams() => _receivedParams;
}
```

#### Mockito (Alternative Approach)

For more complex tests, consider using Mockito with code generation:

1. Add the dependencies to your `pubspec.yaml`:
   ```yaml
   dev_dependencies:
     mockito: ^5.4.0
     build_runner: ^2.3.3
   ```

2. Create your test file with `@GenerateMocks` annotation:
   ```dart
   import 'package:mockito/annotations.dart';
   
   @GenerateMocks([IRepository])
   void main() {
     // Your tests...
   }
   ```

3. Run the code generator:
   ```
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

### Testing Different Scenarios

#### Testing Success Cases

```dart
test('should return success data when repository succeeds', () async {
  // Arrange
  mockRepository.mockMethod(right(successData));
  
  // Act
  final result = await usecase(testParams);
  
  // Assert
  expect(result, right(successData));
  expect(mockRepository.getReceivedParams(), testParams);
});
```

#### Testing Failure Cases

```dart
test('should return failure when repository fails', () async {
  // Arrange
  mockRepository.mockMethod(left(Failure.server('Error message')));
  
  // Act
  final result = await usecase(testParams);
  
  // Assert
  expect(result, left(Failure.server('Error message')));
  expect(mockRepository.getReceivedParams(), testParams);
});
```

#### Testing Edge Cases

Make sure to test edge cases such as:
- Empty or null inputs
- Boundary conditions
- Invalid formats
- Special characters
- Timeouts and connection issues

## Running Tests

To run all unit tests:

```bash
flutter test test/unit/
```

To run a specific test file:

```bash
flutter test test/unit/domain/usecases/auth/login_usecase_test.dart
```

To run tests with coverage:

```bash
flutter test --coverage
``` 