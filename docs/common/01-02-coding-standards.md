# Coding Standards and Best Practices

This document outlines the coding standards and best practices for Flutter development across projects.

## Code Formatting

### Dart Formatting
- Use `dart format` or IDE auto-formatting
- Line length: 80 characters (configurable in `analysis_options.yaml`)
- Use trailing commas for better Git diffs
- Consistent indentation (2 spaces)

```dart
// Good
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Example'),
    ),
    body: Column(
      children: [
        Text('Hello'),
        Text('World'),
      ],
    ),
  );
}
```

### Import Organization
```dart
// 1. Dart imports
import 'dart:async';
import 'dart:convert';

// 2. Package imports
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// 3. Relative imports
import '../models/user.dart';
import '../widgets/custom_button.dart';
```

## Naming Conventions

### Files and Directories
- Use **snake_case** for file and directory names
- Be descriptive and specific
- Group related files in directories

```
lib/
├── src/
│   ├── domain/
│   │   ├── entities/
│   │   │   └── user_entity.dart
│   │   └── repositories/
│   │       └── user_repository.dart
│   └── presentation/
│       ├── pages/
│       │   └── login_page.dart
│       └── widgets/
│           └── custom_text_field.dart
```

### Classes and Variables
```dart
// Classes: PascalCase
class UserRepository {}
class AuthenticationBloc {}

// Variables and functions: camelCase
String userName = '';
void fetchUserData() {}

// Constants: lowerCamelCase
const String apiEndpoint = 'https://api.example.com';

// Private variables: underscore prefix
String _privateVariable = '';

// Enums: PascalCase
enum UserStatus { active, inactive, pending }
```

## Architecture Patterns

### Clean Architecture Structure
```
lib/
├── config/           # App configuration
├── core/             # Utilities and constants
└── src/
    ├── domain/       # Business logic
    │   ├── entities/
    │   ├── repositories/
    │   └── usecases/
    ├── data/         # Data sources
    │   ├── datasources/
    │   ├── models/
    │   └── repositories/
    └── presentation/  # UI layer
        ├── blocs/
        ├── pages/
        └── widgets/
```

### State Management
- Use **BLoC pattern** for complex state
- Use **StatefulWidget** for simple local state
- Use **Provider** or **Consumer** for dependency injection

```dart
// BLoC implementation
class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterInitial()) {
    on<CounterIncrement>(_onIncrement);
  }

  void _onIncrement(CounterIncrement event, Emitter<CounterState> emit) {
    emit(CounterValue(state.value + 1));
  }
}
```

## Error Handling

### Exception Classes
```dart
abstract class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}
```

### Try-Catch Blocks
```dart
Future<User> fetchUser(String id) async {
  try {
    final response = await userRepository.getUser(id);
    return response;
  } on NetworkException catch (e) {
    // Handle network errors
    throw AppException('Failed to fetch user: ${e.message}');
  } catch (e) {
    // Handle unexpected errors
    throw AppException('Unexpected error: $e');
  }
}
```

## Documentation

### Class Documentation
```dart
/// A repository that manages user data.
/// 
/// This class handles user authentication, profile management,
/// and user preferences. It integrates with both local storage
/// and remote APIs.
class UserRepository {
  /// Creates a new [UserRepository] with the given [apiClient].
  UserRepository(this.apiClient);
  
  final ApiClient apiClient;
  
  /// Fetches user data for the given [userId].
  /// 
  /// Returns a [User] object if successful, otherwise throws
  /// a [UserNotFoundException].
  Future<User> fetchUser(String userId) async {
    // Implementation
  }
}
```

### Method Documentation
```dart
/// Validates the given email address.
/// 
/// Returns `true` if the email is valid, `false` otherwise.
/// 
/// Example:
/// ```dart
/// bool isValid = validateEmail('user@example.com'); // true
/// bool isInvalid = validateEmail('invalid-email'); // false
/// ```
bool validateEmail(String email) {
  // Implementation
}
```

## Performance Best Practices

### Widget Optimization
```dart
// Use const constructors when possible
const Text('Static text');

// Extract widgets to reduce rebuilds
class _CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CustomAppBar();
  
  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('App'));
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
```

### List Optimization
```dart
// Use ListView.builder for large lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(title: Text(items[index].name));
  },
);

// Use keys for list items when order changes
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(
      key: ValueKey(items[index].id),
      title: Text(items[index].name),
    );
  },
);
```

## Testing Standards

### Unit Tests
```dart
group('UserRepository', () {
  late UserRepository userRepository;
  late MockApiClient mockApiClient;
  
  setUp(() {
    mockApiClient = MockApiClient();
    userRepository = UserRepository(mockApiClient);
  });
  
  test('should return user when API call is successful', () async {
    // Arrange
    const userId = '123';
    const expectedUser = User(id: userId, name: 'John Doe');
    when(() => mockApiClient.getUser(userId))
        .thenAnswer((_) async => expectedUser);
    
    // Act
    final result = await userRepository.fetchUser(userId);
    
    // Assert
    expect(result, equals(expectedUser));
  });
});
```

### Widget Tests
```dart
testWidgets('LoginPage should display login form', (WidgetTester tester) async {
  // Arrange
  await tester.pumpWidget(
    MaterialApp(home: LoginPage()),
  );
  
  // Assert
  expect(find.byType(TextFormField), findsNWidgets(2));
  expect(find.text('Login'), findsOneWidget);
  expect(find.byType(ElevatedButton), findsOneWidget);
});
```

## Security Considerations

### Sensitive Data
- Never commit API keys, passwords, or tokens
- Use environment variables for sensitive configuration
- Implement proper authentication and authorization

### Input Validation
```dart
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email is required';
  }
  
  const emailRegex = r'^[^@]+@[^@]+\.[^@]+$';
  if (!RegExp(emailRegex).hasMatch(value)) {
    return 'Please enter a valid email';
  }
  
  return null;
}
```

### Network Security
```dart
// Use HTTPS for all network requests
static const String baseUrl = 'https://api.example.com';

// Implement certificate pinning for sensitive apps
class SecureHttpClient {
  static http.Client createSecureClient() {
    return http.Client(); // Configure with certificate pinning
  }
}
```