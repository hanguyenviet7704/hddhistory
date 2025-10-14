# Testing Strategy

This document outlines the comprehensive testing strategy for Dcore Flutter projects.

## Testing Overview

The Dcore project follows a multi-layered testing approach aligned with Clean Architecture principles, ensuring code quality, reliability, and maintainability across all layers of the application.

## Testing Pyramid

### Test Distribution
- **Unit Tests (70%)**: Fast, isolated tests for business logic
- **Widget Tests (20%)**: UI component testing
- **Integration Tests (10%)**: End-to-end functionality testing

### Test Structure
```
test/
├── unit/                    # Unit tests
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   ├── data/
│   │   ├── datasources/
│   │   ├── models/
│   │   └── repositories/
│   └── presentation/
│       ├── blocs/
│       └── cubits/
├── widget/                  # Widget tests
│   ├── pages/
│   └── widgets/
└── integration/             # Integration tests
    ├── features/
    └── flows/
```

## Unit Testing

### Domain Layer Testing

#### Entity Testing
```dart
// test/unit/domain/entities/user_entity_test.dart
group('UserEntity', () {
  test('should create instance with required parameters', () {
    // Arrange
    const id = 'user-id';
    const name = 'John Doe';
    const email = 'john@example.com';

    // Act
    const userEntity = UserEntity(
      id: id,
      name: name,
      email: email,
    );

    // Assert
    expect(userEntity.id, equals(id));
    expect(userEntity.name, equals(name));
    expect(userEntity.email, equals(email));
    expect(userEntity.isVerified, false); // Default value
  });

  test('should support copyWith functionality', () {
    // Arrange
    const original = UserEntity(
      id: 'user-id',
      name: 'John Doe',
      email: 'john@example.com',
    );

    // Act
    final updated = original.copyWith(name: 'Jane Doe');

    // Assert
    expect(updated.id, equals(original.id));
    expect(updated.name, equals('Jane Doe'));
    expect(updated.email, equals(original.email));
  });
});
```

#### Use Case Testing
```dart
// test/unit/domain/usecases/get_user_usecase_test.dart
class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late GetUserUseCase usecase;
  late MockUserRepository mockUserRepository;

  setUp(() {
    mockUserRepository = MockUserRepository();
    usecase = GetUserUseCase(mockUserRepository);
  });

  group('GetUserUseCase', () {
    const userId = 'user-id';
    const userEntity = UserEntity(
      id: userId,
      name: 'John Doe',
      email: 'john@example.com',
    );

    test('should return user from repository when call is successful', () async {
      // Arrange
      when(() => mockUserRepository.getUser(any()))
          .thenAnswer((_) async => const Right(userEntity));

      // Act
      final result = await usecase(const GetUserParams(userId: userId));

      // Assert
      expect(result, equals(const Right(userEntity)));
      verify(() => mockUserRepository.getUser(userId));
      verifyNoMoreInteractions(mockUserRepository);
    });

    test('should return failure when repository call fails', () async {
      // Arrange
      const failure = NetworkFailure('Network error');
      when(() => mockUserRepository.getUser(any()))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await usecase(const GetUserParams(userId: userId));

      // Assert
      expect(result, equals(const Left(failure)));
      verify(() => mockUserRepository.getUser(userId));
    });
  });
}
```

### Data Layer Testing

#### Model Testing
```dart
// test/unit/data/models/user_model_test.dart
group('UserModel', () {
  const userModel = UserModel(
    id: 'user-id',
    name: 'John Doe',
    email: 'john@example.com',
    profileImageUrl: 'https://example.com/avatar.jpg',
  );

  group('fromJson', () {
    test('should return valid model from JSON', () {
      // Arrange
      final jsonMap = {
        'id': 'user-id',
        'name': 'John Doe',
        'email': 'john@example.com',
        'profile_image_url': 'https://example.com/avatar.jpg',
      };

      // Act
      final result = UserModel.fromJson(jsonMap);

      // Assert
      expect(result, equals(userModel));
    });

    test('should handle null optional fields', () {
      // Arrange
      final jsonMap = {
        'id': 'user-id',
        'name': 'John Doe',
        'email': 'john@example.com',
      };

      // Act
      final result = UserModel.fromJson(jsonMap);

      // Assert
      expect(result.profileImageUrl, isNull);
    });
  });

  group('toJson', () {
    test('should return valid JSON map', () {
      // Act
      final result = userModel.toJson();

      // Assert
      final expectedMap = {
        'id': 'user-id',
        'name': 'John Doe',
        'email': 'john@example.com',
        'profile_image_url': 'https://example.com/avatar.jpg',
      };
      expect(result, equals(expectedMap));
    });
  });

  group('toEntity', () {
    test('should convert to UserEntity correctly', () {
      // Act
      final entity = userModel.toEntity();

      // Assert
      expect(entity.id, equals(userModel.id));
      expect(entity.name, equals(userModel.name));
      expect(entity.email, equals(userModel.email));
      expect(entity.profileImageUrl, equals(userModel.profileImageUrl));
    });
  });
});
```

#### Repository Testing
```dart
// test/unit/data/repositories/user_repository_impl_test.dart
class MockUserRemoteDataSource extends Mock implements UserRemoteDataSource {}
class MockUserLocalDataSource extends Mock implements UserLocalDataSource {}

void main() {
  late UserRepositoryImpl repository;
  late MockUserRemoteDataSource mockRemoteDataSource;
  late MockUserLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockUserRemoteDataSource();
    mockLocalDataSource = MockUserLocalDataSource();
    repository = UserRepositoryImpl(mockRemoteDataSource, mockLocalDataSource);
  });

  group('getUser', () {
    const userId = 'user-id';
    const userModel = UserModel(
      id: userId,
      name: 'John Doe',
      email: 'john@example.com',
    );

    test('should return cached user when available', () async {
      // Arrange
      when(() => mockLocalDataSource.getUser(any()))
          .thenAnswer((_) async => userModel);

      // Act
      final result = await repository.getUser(userId);

      // Assert
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (user) => expect(user, equals(userModel.toEntity())),
      );
      verify(() => mockLocalDataSource.getUser(userId));
      verifyNever(() => mockRemoteDataSource.getUser(any()));
    });

    test('should fetch from remote when cache is empty', () async {
      // Arrange
      when(() => mockLocalDataSource.getUser(any()))
          .thenAnswer((_) async => null);
      when(() => mockRemoteDataSource.getUser(any()))
          .thenAnswer((_) async => userModel);
      when(() => mockLocalDataSource.saveUser(any()))
          .thenAnswer((_) async => {});

      // Act
      final result = await repository.getUser(userId);

      // Assert
      result.fold(
        (failure) => fail('Expected success but got failure: $failure'),
        (user) => expect(user, equals(userModel.toEntity())),
      );
      verify(() => mockLocalDataSource.getUser(userId));
      verify(() => mockRemoteDataSource.getUser(userId));
      verify(() => mockLocalDataSource.saveUser(userModel));
    });

    test('should return failure when remote call fails', () async {
      // Arrange
      when(() => mockLocalDataSource.getUser(any()))
          .thenAnswer((_) async => null);
      when(() => mockRemoteDataSource.getUser(any()))
          .thenThrow(const NetworkException('Network error'));

      // Act
      final result = await repository.getUser(userId);

      // Assert
      result.fold(
        (failure) => expect(failure, isA<NetworkException>()),
        (user) => fail('Expected failure but got success: $user'),
      );
    });
  });
}
```

### Presentation Layer Testing

#### BLoC Testing
```dart
// test/unit/presentation/blocs/auth_bloc_test.dart
class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}

void main() {
  late AuthBloc authBloc;
  late MockLoginUseCase mockLoginUseCase;
  late MockLogoutUseCase mockLogoutUseCase;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    authBloc = AuthBloc(mockLoginUseCase, mockLogoutUseCase);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    const userEntity = UserEntity(
      id: 'user-id',
      name: 'John Doe',
      email: 'john@example.com',
    );

    group('AuthLoginRequested', () {
      const email = 'test@example.com';
      const password = 'password123';

      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] when login succeeds',
        build: () {
          when(() => mockLoginUseCase(any()))
              .thenAnswer((_) async => const Right(userEntity));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthEvent.loginRequested(
          email: email,
          password: password,
        )),
        expect: () => [
          const AuthState.loading(),
          const AuthState.authenticated(userEntity),
        ],
        verify: (_) {
          verify(() => mockLoginUseCase(const LoginParams(
            email: email,
            password: password,
          ))).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] when login fails',
        build: () {
          when(() => mockLoginUseCase(any()))
              .thenAnswer((_) async => const Left(NetworkFailure('Network error')));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthEvent.loginRequested(
          email: email,
          password: password,
        )),
        expect: () => [
          const AuthState.loading(),
          const AuthState.error('Network error'),
        ],
      );
    });
  });
}
```

## Widget Testing

### Page Testing
```dart
// test/widget/pages/login_page_test.dart
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  testWidgets('LoginPage should display login form', (tester) async {
    // Arrange
    when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>(
          create: (_) => mockAuthBloc,
          child: const LoginPage(),
        ),
      ),
    );

    // Assert
    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('should show loading indicator when state is loading', (tester) async {
    // Arrange
    when(() => mockAuthBloc.state).thenReturn(const AuthState.loading());

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>(
          create: (_) => mockAuthBloc,
          child: const LoginPage(),
        ),
      ),
    );

    // Assert
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('should show error message when state is error', (tester) async {
    // Arrange
    const errorMessage = 'Login failed';
    when(() => mockAuthBloc.state).thenReturn(const AuthState.error(errorMessage));

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>(
          create: (_) => mockAuthBloc,
          child: const LoginPage(),
        ),
      ),
    );

    // Assert
    expect(find.text(errorMessage), findsOneWidget);
  });

  testWidgets('should add login event when login button is pressed', (tester) async {
    // Arrange
    when(() => mockAuthBloc.state).thenReturn(const AuthState.initial());

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>(
          create: (_) => mockAuthBloc,
          child: const LoginPage(),
        ),
      ),
    );

    // Act
    await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.byType(ElevatedButton));

    // Assert
    verify(() => mockAuthBloc.add(const AuthEvent.loginRequested(
      email: 'test@example.com',
      password: 'password123',
    ))).called(1);
  });
}
```

### Widget Testing
```dart
// test/widget/widgets/user_avatar_test.dart
void main() {
  group('UserAvatar', () {
    testWidgets('should display user initials when no image URL', (tester) async {
      // Arrange
      const user = UserEntity(
        id: 'user-id',
        name: 'John Doe',
        email: 'john@example.com',
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(user: user),
          ),
        ),
      );

      // Assert
      expect(find.text('JD'), findsOneWidget); // John Doe initials
    });

    testWidgets('should display image when image URL is provided', (tester) async {
      // Arrange
      const user = UserEntity(
        id: 'user-id',
        name: 'John Doe',
        email: 'john@example.com',
        profileImageUrl: 'https://example.com/avatar.jpg',
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(user: user),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byType(NetworkImage), findsOneWidget);
    });
  });
}
```

## Integration Testing

### Feature Testing
```dart
// integration_test/features/authentication_test.dart
void main() {
  group('Authentication Flow', () {
    testWidgets('complete login flow', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Act & Assert - Navigate to login
      expect(find.text('Login'), findsOneWidget);

      // Enter credentials
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');

      // Tap login button
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Verify successful login
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('should show error for invalid credentials', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Act - Enter invalid credentials
      await tester.enterText(find.byKey(const Key('email_field')), 'invalid@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'wrongpassword');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Invalid credentials'), findsOneWidget);
    });
  });
}
```

### End-to-End Testing
```dart
// integration_test/flows/user_journey_test.dart
void main() {
  group('Complete User Journey', () {
    testWidgets('user can complete full app flow', (tester) async {
      // Arrange
      app.main();
      await tester.pumpAndSettle();

      // Login
      await _performLogin(tester);

      // Navigate to profile
      await tester.tap(find.byKey(const Key('profile_tab')));
      await tester.pumpAndSettle();

      // Update profile
      await tester.tap(find.byKey(const Key('edit_profile_button')));
      await tester.pumpAndSettle();
      
      await tester.enterText(find.byKey(const Key('name_field')), 'Updated Name');
      await tester.tap(find.byKey(const Key('save_button')));
      await tester.pumpAndSettle();

      // Verify update
      expect(find.text('Updated Name'), findsOneWidget);

      // Logout
      await _performLogout(tester);
      
      // Verify logged out
      expect(find.text('Login'), findsOneWidget);
    });
  });
}

Future<void> _performLogin(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
  await tester.enterText(find.byKey(const Key('password_field')), 'password123');
  await tester.tap(find.byKey(const Key('login_button')));
  await tester.pumpAndSettle();
}

Future<void> _performLogout(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('logout_button')));
  await tester.pumpAndSettle();
}
```

## Test Configuration

### Test Setup
```dart
// test/helpers/test_helper.dart
class TestHelper {
  static Widget createTestApp({required Widget child}) {
    return MaterialApp(
      home: child,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  static Widget createTestAppWithRouter({required GoRouter router}) {
    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

// Mock data factories
class MockDataFactory {
  static const UserEntity userEntity = UserEntity(
    id: 'test-user-id',
    name: 'Test User',
    email: 'test@example.com',
  );

  static const UserModel userModel = UserModel(
    id: 'test-user-id',
    name: 'Test User',
    email: 'test@example.com',
  );
}
```

### Test Utilities
```dart
// test/utils/test_utils.dart
extension WidgetTesterExtension on WidgetTester {
  Future<void> pumpWidgetWithMaterialApp(Widget widget) async {
    await pumpWidget(
      MaterialApp(home: Scaffold(body: widget)),
    );
  }

  Future<void> enterTextAndSettle(Finder finder, String text) async {
    await enterText(finder, text);
    await pumpAndSettle();
  }

  Future<void> tapAndSettle(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }
}
```

## Running Tests

### Command Line
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/domain/usecases/get_user_usecase_test.dart

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/

# Run widget tests only
flutter test test/widget/

# Run unit tests only
flutter test test/unit/
```

### IDE Integration
- **VS Code**: Use Flutter test runner extension
- **IntelliJ/Android Studio**: Use built-in test runner
- **Debugging**: Set breakpoints and debug tests

### Continuous Integration
```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test --coverage
      - run: flutter test integration_test/
```

## Test Coverage

### Coverage Analysis
```bash
# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# View coverage report
open coverage/html/index.html
```

### Coverage Goals
- **Unit Tests**: >90% code coverage
- **Widget Tests**: >80% widget coverage
- **Integration Tests**: >70% feature coverage

## Best Practices

### Test Organization
- Group related tests together
- Use descriptive test names
- Follow AAA pattern (Arrange, Act, Assert)
- Keep tests independent and isolated

### Mocking
- Mock external dependencies
- Use consistent mock data
- Verify mock interactions
- Reset mocks between tests

### Performance
- Keep tests fast and focused
- Use `setUp` and `tearDown` appropriately
- Avoid unnecessary widget pumps
- Mock heavy operations

### Maintenance
- Update tests with code changes
- Remove obsolete tests
- Refactor test utilities
- Monitor test performance and reliability