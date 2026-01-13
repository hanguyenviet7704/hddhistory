---
trigger: model_decision
description: Testing patterns and guidelines for unit, widget, and integration tests
---

# Testing Patterns and Guidelines

## Testing Structure
Follow the established test directory structure:
```
test/
├── unit/                  # Unit tests
│   ├── domain/           # Domain layer tests
│   ├── data/             # Data layer tests  
│   └── presentation/     # Presentation layer tests
├── widget/               # Widget tests
└── integration_test/     # Integration tests
```

## Unit Testing Patterns

### Use Case Testing
```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements IUserRepository {}

void main() {
  group('GetUserUseCase', () {
    late GetUserUseCase useCase;
    late MockUserRepository mockRepository;
    
    setUp(() {
      mockRepository = MockUserRepository();
      useCase = GetUserUseCase(mockRepository);
    });
    
    group('call', () {
      const userId = 'user-123';
      final user = User(
        id: userId,
        name: 'John Doe',
        email: 'john@example.com',
      );
      
      test('should return user when repository returns user', () async {
        // Arrange
        when(() => mockRepository.getUser(userId))
            .thenAnswer((_) async => Right(user));
        
        // Act
        final result = await useCase(GetUserParams(userId: userId));
        
        // Assert
        expect(result, equals(Right(user)));
        verify(() => mockRepository.getUser(userId)).called(1);
      });
      
      test('should return AppException when repository fails', () async {
        // Arrange
        const exception = AppException.notFoundError(message: 'User not found');
        when(() => mockRepository.getUser(userId))
            .thenAnswer((_) async => const Left(exception));
        
        // Act
        final result = await useCase(GetUserParams(userId: userId));
        
        // Assert
        expect(result, equals(const Left(exception)));
        verify(() => mockRepository.getUser(userId)).called(1);
      });
      
      test('should return validation error when userId is empty', () async {
        // Act
        final result = await useCase(const GetUserParams(userId: ''));
        
        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, isA<_ValidationError>()),
          (user) => fail('Expected validation error'),
        );
        verifyNever(() => mockRepository.getUser(any()));
      });
    });
  });
}
```

### Repository Testing
```dart
class MockApiClient extends Mock implements ApiClient {}
class MockLocalDataSource extends Mock implements UserLocalDataSource {}

void main() {
  group('UserRepository', () {
    late UserRepository repository;
    late MockApiClient mockApiClient;
    late MockLocalDataSource mockLocalDataSource;
    
    setUp(() {
      mockApiClient = MockApiClient();
      mockLocalDataSource = MockLocalDataSource();
      repository = UserRepository(mockApiClient, mockLocalDataSource);
    });
    
    group('getUser', () {
      const userId = 'user-123';
      final userModel = UserModel(
        id: userId,
        name: 'John Doe',
        email: 'john@example.com',
      );
      final user = userModel.toEntity();
      
      test('should return user from API and cache locally', () async {
        // Arrange
        when(() => mockApiClient.getUser(userId))
            .thenAnswer((_) async => ApiResponse(
              success: true,
              data: userModel,
            ));
        when(() => mockLocalDataSource.cacheUser(userModel))
            .thenAnswer((_) async {});
        
        // Act
        final result = await repository.getUser(userId);
        
        // Assert
        expect(result, equals(Right(user)));
        verify(() => mockApiClient.getUser(userId)).called(1);
        verify(() => mockLocalDataSource.cacheUser(userModel)).called(1);
      });
      
      test('should return cached user when API fails', () async {
        // Arrange
        when(() => mockApiClient.getUser(userId))
            .thenThrow(const AppException.networkError());
        when(() => mockLocalDataSource.getCachedUser(userId))
            .thenAnswer((_) async => userModel);
        
        // Act
        final result = await repository.getUser(userId);
        
        // Assert
        expect(result, equals(Right(user)));
        verify(() => mockApiClient.getUser(userId)).called(1);
        verify(() => mockLocalDataSource.getCachedUser(userId)).called(1);
      });
    });
  });
}
```

### BLoC Testing
```dart
import 'package:bloc_test/bloc_test.dart';

class MockGetUserUseCase extends Mock implements GetUserUseCase {}

void main() {
  group('UserCubit', () {
    late UserCubit cubit;
    late MockGetUserUseCase mockGetUserUseCase;
    
    setUp(() {
      mockGetUserUseCase = MockGetUserUseCase();
      cubit = UserCubit(mockGetUserUseCase);
    });
    
    tearDown(() {
      cubit.close();
    });
    
    group('loadUser', () {
      const userId = 'user-123';
      final user = User(
        id: userId,
        name: 'John Doe',
        email: 'john@example.com',
      );
      
      blocTest<UserCubit, UserState>(
        'emits [loading, success] when user is loaded successfully',
        build: () => cubit,
        setUp: () {
          when(() => mockGetUserUseCase(GetUserParams(userId: userId)))
              .thenAnswer((_) async => Right(user));
        },
        act: (cubit) => cubit.loadUser(userId),
        expect: () => [
          const UserState.loading(),
          UserState.success(user),
        ],
      );
      
      blocTest<UserCubit, UserState>(
        'emits [loading, error] when loading user fails',
        build: () => cubit,
        setUp: () {
          const exception = AppException.networkError();
          when(() => mockGetUserUseCase(GetUserParams(userId: userId)))
              .thenAnswer((_) async => const Left(exception));
        },
        act: (cubit) => cubit.loadUser(userId),
        expect: () => [
          const UserState.loading(),
          const UserState.error(AppException.networkError()),
        ],
      );
      
      blocTest<UserCubit, UserState>(
        'does not emit new state when user ID is empty',
        build: () => cubit,
        act: (cubit) => cubit.loadUser(''),
        expect: () => [],
      );
    });
    
    group('clearError', () {
      blocTest<UserCubit, UserState>(
        'emits initial state when current state is error',
        build: () => cubit,
        seed: () => const UserState.error(AppException.networkError()),
        act: (cubit) => cubit.clearError(),
        expect: () => [const UserState.initial()],
      );
      
      blocTest<UserCubit, UserState>(
        'does not emit new state when current state is not error',
        build: () => cubit,
        seed: () => const UserState.loading(),
        act: (cubit) => cubit.clearError(),
        expect: () => [],
      );
    });
  });
}
```

## Widget Testing

### Widget Test Setup
```dart
void main() {
  group('UserCard Widget', () {
    late User testUser;
    
    setUp(() {
      testUser = User(
        id: 'user-123',
        name: 'John Doe',
        email: 'john@example.com',
        avatarUrl: 'https://example.com/avatar.jpg',
      );
    });
    
    testWidgets('displays user information correctly', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCard(user: testUser),
          ),
        ),
      );
      
      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });
    
    testWidgets('calls onTap when tapped', (tester) async {
      // Arrange
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCard(
              user: testUser,
              onTap: (_) => tapped = true,
            ),
          ),
        ),
      );
      
      // Act
      await tester.tap(find.byType(UserCard));
      await tester.pumpAndSettle();
      
      // Assert
      expect(tapped, true);
    });
  });
}
```

### Testing with BLoC
```dart
class MockUserCubit extends MockCubit<UserState> implements UserCubit {}

void main() {
  group('UserProfileView', () {
    late MockUserCubit mockCubit;
    
    setUp(() {
      mockCubit = MockUserCubit();
    });
    
    testWidgets('shows loading indicator when state is loading', (tester) async {
      // Arrange
      when(() => mockCubit.state).thenReturn(const UserState.loading());
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<UserCubit>(
            create: (_) => mockCubit,
            child: const UserProfileView(),
          ),
        ),
      );
      
      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    
    testWidgets('shows user content when state is success', (tester) async {
      // Arrange
      final user = User(
        id: 'user-123',
        name: 'John Doe',
        email: 'john@example.com',
      );
      when(() => mockCubit.state).thenReturn(UserState.success(user));
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<UserCubit>(
            create: (_) => mockCubit,
            child: const UserProfileView(),
          ),
        ),
      );
      
      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
    });
    
    testWidgets('shows error display when state is error', (tester) async {
      // Arrange
      const exception = AppException.networkError();
      when(() => mockCubit.state).thenReturn(const UserState.error(exception));
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<UserCubit>(
            create: (_) => mockCubit,
            child: const UserProfileView(),
          ),
        ),
      );
      
      // Assert
      expect(find.byType(ErrorDisplay), findsOneWidget);
      expect(find.text('Network connection failed'), findsOneWidget);
    });
  });
}
```

## Integration Testing

### Basic Integration Test
```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meup/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('User Profile Flow', () {
    testWidgets('should complete user profile flow', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to login
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      
      // Enter login credentials
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );
      
      // Tap login button
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      
      // Verify navigation to home
      expect(find.text('Welcome'), findsOneWidget);
      
      // Navigate to profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      
      // Verify profile page
      expect(find.text('User Profile'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });
  });
}
```

## Test Utilities

### Test Data Builders
```dart
class UserBuilder {
  String _id = 'user-123';
  String _name = 'John Doe';
  String _email = 'john@example.com';
  String? _avatarUrl;
  DateTime? _lastLoginAt;
  
  UserBuilder withId(String id) {
    _id = id;
    return this;
  }
  
  UserBuilder withName(String name) {
    _name = name;
    return this;
  }
  
  UserBuilder withEmail(String email) {
    _email = email;
    return this;
  }
  
  UserBuilder withAvatar(String url) {
    _avatarUrl = url;
    return this;
  }
  
  UserBuilder withLastLogin(DateTime date) {
    _lastLoginAt = date;
    return this;
  }
  
  User build() {
    return User(
      id: _id,
      name: _name,
      email: _email,
      avatarUrl: _avatarUrl,
      lastLoginAt: _lastLoginAt,
    );
  }
}

// Usage in tests
final user = UserBuilder()
    .withName('Jane Doe')
    .withEmail('jane@example.com')
    .build();
```

### Mock Setup Helpers
```dart
class MockSetupHelper {
  static void setupSuccessfulUserRepository(
    MockUserRepository repository,
    User user,
  ) {
    when(() => repository.getUser(user.id))
        .thenAnswer((_) async => Right(user));
    when(() => repository.updateUser(any()))
        .thenAnswer((_) async => Right(user));
  }
  
  static void setupFailingUserRepository(
    MockUserRepository repository,
    AppException exception,
  ) {
    when(() => repository.getUser(any()))
        .thenAnswer((_) async => Left(exception));
    when(() => repository.updateUser(any()))
        .thenAnswer((_) async => Left(exception));
  }
}
```

## Test Coverage

### Running Tests with Coverage
```bash
# Run all tests with coverage
flutter test --coverage

# Run specific test with coverage
flutter test test/unit/domain/usecases/get_user_usecase_test.dart --coverage

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Coverage Goals
- **Domain Layer**: 100% coverage (critical business logic)
- **Data Layer**: 90%+ coverage (repository implementations)
- **Presentation Layer**: 80%+ coverage (BLoCs and critical UI)
- **Overall Project**: 85%+ coverage

### Testing Best Practices
1. **AAA Pattern**: Arrange, Act, Assert
2. **One assertion per test**: Keep tests focused
3. **Descriptive test names**: Explain what is being tested
4. **Mock external dependencies**: Isolate units under test
5. **Test edge cases**: Error conditions, empty states, boundaries
6. **Use builders for complex objects**: Make tests readable
7. **Group related tests**: Organize with `group()` blocks