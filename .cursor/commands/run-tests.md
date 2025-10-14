# Run Tests

## Overview
Execute comprehensive testing for the Meup Flutter project, including unit tests, widget tests, and integration tests with coverage reporting.

## Quick Test Commands

### All Tests
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run tests with detailed output
flutter test --verbose
```

### Specific Test Types

#### 1. **Unit Tests**
```bash
# Run all unit tests
flutter test test/unit/

# Run specific domain tests
flutter test test/unit/domain/

# Run specific use case test
flutter test test/unit/domain/usecases/auth/login_usecase_test.dart
```

#### 2. **Widget Tests**
```bash
# Run all widget tests
flutter test test/widget/

# Run specific widget test
flutter test test/widget/auth/login_page_test.dart
```

#### 3. **Integration Tests**
```bash
# Run integration tests
flutter test integration_test/

# Run specific integration test
flutter test integration_test/auth_flow_test.dart
```

## Test Structure

### Project Test Organization:
```
test/
├── unit/                    # Unit tests
│   ├── domain/             # Domain layer tests
│   │   ├── entities/       # Entity tests
│   │   ├── usecases/       # Use case tests
│   │   └── repositories/   # Repository interface tests
│   ├── data/               # Data layer tests
│   │   ├── models/         # Model tests
│   │   ├── datasources/    # Data source tests
│   │   └── repositories/   # Repository implementation tests
│   └── presentation/       # Presentation layer tests
│       ├── blocs/          # BLoC/Cubit tests
│       └── widgets/        # Widget unit tests
├── widget/                 # Widget tests
└── integration_test/       # Integration tests
```

## Coverage Reporting

### Generate Coverage Report:
```bash
# Run tests with coverage
flutter test --coverage

# Generate HTML coverage report (requires genhtml)
genhtml coverage/lcov.info -o coverage/html

# Open coverage report
open coverage/html/index.html
```

### Coverage Goals:
- **Domain Layer**: 100% (critical business logic)
- **Data Layer**: 90%+ (repository implementations)
- **Presentation Layer**: 80%+ (BLoCs and critical UI)
- **Overall Project**: 85%+

## Testing Patterns

### Unit Test Example:
```dart
// test/unit/domain/usecases/auth/login_usecase_test.dart
void main() {
  group('LoginUseCase', () {
    late LoginUseCase useCase;
    late MockAuthRepository mockRepository;
    
    setUp(() {
      mockRepository = MockAuthRepository();
      useCase = LoginUseCase(mockRepository);
    });
    
    group('call', () {
      test('should return user when credentials are valid', () async {
        // Arrange
        const params = LoginParams(email: 'test@test.com', password: 'password');
        final user = User(id: '1', email: 'test@test.com', name: 'Test User');
        when(() => mockRepository.login(any())).thenAnswer((_) async => Right(user));
        
        // Act
        final result = await useCase(params);
        
        // Assert
        expect(result, equals(Right(user)));
        verify(() => mockRepository.login(any())).called(1);
      });
    });
  });
}
```

### Widget Test Example:
```dart
// test/widget/auth/login_page_test.dart
void main() {
  group('LoginPage', () {
    testWidgets('displays login form correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => MockLoginCubit(),
            child: const LoginPage(),
          ),
        ),
      );
      
      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2)); // Email and password fields
      expect(find.byType(ElevatedButton), findsOneWidget); // Login button
    });
  });
}
```

### BLoC Test Example:
```dart
// test/unit/presentation/blocs/auth/login_cubit_test.dart
void main() {
  group('LoginCubit', () {
    late LoginCubit cubit;
    late MockLoginUseCase mockUseCase;
    
    setUp(() {
      mockUseCase = MockLoginUseCase();
      cubit = LoginCubit(mockUseCase);
    });
    
    blocTest<LoginCubit, LoginState>(
      'emits [loading, success] when login succeeds',
      build: () => cubit,
      setUp: () {
        when(() => mockUseCase(any())).thenAnswer(
          (_) async => Right(User(id: '1', email: 'test@test.com', name: 'Test')),
        );
      },
      act: (cubit) => cubit.login('test@test.com', 'password'),
      expect: () => [
        const LoginState.loading(),
        LoginState.success(User(id: '1', email: 'test@test.com', name: 'Test')),
      ],
    );
  });
}
```

## Test Utilities

### Mock Setup Helpers:
```dart
// test/helpers/mock_setup_helper.dart
class MockSetupHelper {
  static void setupSuccessfulAuth(MockAuthRepository repository) {
    when(() => repository.login(any())).thenAnswer(
      (_) async => Right(User(id: '1', email: 'test@test.com', name: 'Test')),
    );
  }
}
```

### Test Data Builders:
```dart
// test/helpers/user_builder.dart
class UserBuilder {
  String _id = '1';
  String _email = 'test@test.com';
  String _name = 'Test User';
  
  UserBuilder withId(String id) {
    _id = id;
    return this;
  }
  
  User build() => User(id: _id, email: _email, name: _name);
}
```

## Running Tests by Feature

### Authentication Tests:
```bash
# All auth-related tests
flutter test test/unit/domain/usecases/auth/
flutter test test/unit/presentation/blocs/auth/
flutter test test/widget/auth/
```

### User Profile Tests:
```bash
# All profile-related tests
flutter test test/unit/domain/usecases/profile/
flutter test test/unit/presentation/blocs/profile/
flutter test test/widget/profile/
```

## Continuous Integration

### Pre-commit Testing:
```bash
# Full test suite before committing
flutter analyze
flutter test --coverage
# Check coverage threshold
```

### CI Pipeline Testing:
```yaml
# Example GitHub Actions test job
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
    - run: flutter pub get
    - run: dart run build_runner build --delete-conflicting-outputs
    - run: flutter analyze
    - run: flutter test --coverage
```

## Test Configuration

### Test Setup Files:
```dart
// test/helpers/test_helper.dart
void setupTestDependencies() {
  // Setup test-specific dependencies
  AppDI.injector.reset();
  // Register test doubles
}
```

### Global Test Configuration:
```dart
// test/flutter_test_config.dart
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUpAll(() {
    // Global test setup
  });
  
  await testMain();
}
```

## Performance Testing

### Widget Performance:
```dart
testWidgets('widget builds efficiently', (tester) async {
  final stopwatch = Stopwatch()..start();
  
  await tester.pumpWidget(MyWidget());
  
  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(100));
});
```

## Debugging Tests

### Debug Test Failures:
```bash
# Run single test with verbose output
flutter test test/path/to/test.dart --verbose

# Run test in debug mode
flutter test test/path/to/test.dart --start-paused
```

### Test Debugging Tips:
- Use `printOnFailure()` for debugging output
- Add breakpoints in test code
- Use `tester.binding.debugPrintScheduler = true` for widget tests
- Check test logs for detailed error information

## Test Maintenance

### Keep Tests Updated:
- Update tests when changing business logic
- Maintain test coverage above thresholds
- Refactor tests when refactoring code
- Remove obsolete tests

### Test Quality Checklist:
- [ ] Tests are independent and isolated
- [ ] Tests have descriptive names
- [ ] Tests follow AAA pattern (Arrange, Act, Assert)
- [ ] Tests use appropriate mocks
- [ ] Tests cover edge cases and error scenarios
- [ ] Tests are fast and reliable