# Flutter Development Best Practices

This document outlines best practices for Flutter development that should be followed across all projects.

## Project Structure

### Recommended Directory Structure
```
lib/
├── config/           # App-level configuration
│   ├── di/          # Dependency injection setup
│   ├── routes/      # Navigation and routing
│   ├── services/    # Global services
│   └── themes/      # Theme definitions
├── core/            # Shared utilities and constants
│   ├── constants/   # App constants
│   ├── extensions/  # Dart extensions
│   ├── utils/       # Utility functions
│   └── widgets/     # Reusable widgets
└── src/             # Feature modules
    ├── domain/      # Business logic layer
    ├── data/        # Data access layer
    └── presentation/ # UI layer
```

### Clean Architecture Implementation
- **Domain Layer**: Contains business entities, use cases, and repository interfaces
- **Data Layer**: Implements repositories, data sources, and models
- **Presentation Layer**: Contains UI components, state management, and view models

## State Management

### BLoC Pattern Guidelines
```dart
// Bloc structure
abstract class AuthEvent {}
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  AuthLoginRequested({required this.email, required this.password});
}

abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {
  final User user;
  AuthSuccess(this.user);
}
class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
  }

  final AuthRepository _authRepository;

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
```

### State Management Best Practices
- Use BLoC for complex business logic
- Use StatefulWidget for simple local state
- Implement state persistence with HydratedBloc when needed
- Keep state immutable using `equatable` or `freezed`

## Widget Development

### Widget Design Principles
```dart
// Good: Stateless widget with const constructor
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading 
        ? const CircularProgressIndicator()
        : Text(text),
    );
  }
}
```

### Performance Optimization
```dart
// Use const constructors
const Text('Static text');

// Extract expensive widgets
class _ExpensiveWidget extends StatelessWidget {
  const _ExpensiveWidget();
  
  @override
  Widget build(BuildContext context) {
    // Expensive operations here
    return Container();
  }
}

// Use keys for dynamic lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(
      key: ValueKey(items[index].id),
      title: Text(items[index].title),
    );
  },
);
```

### Theme and Styling
```dart
// Define consistent themes
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    // Dark theme definitions
  );
}
```

## Navigation and Routing

### GoRouter Implementation
```dart
final GoRouter router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(
          path: '/profile/:userId',
          name: 'profile',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return ProfilePage(userId: userId);
          },
        ),
      ],
    ),
  ],
);
```

### Navigation Best Practices
- Use named routes instead of direct navigation
- Implement proper error handling for unknown routes
- Use type-safe navigation with code generation when possible
- Handle deep linking appropriately

## Dependency Injection

### GetIt and Injectable Setup
```dart
// Service locator setup
final GetIt getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();

// Injectable annotations
@injectable
class UserRepository {
  UserRepository(this._apiClient);
  final ApiClient _apiClient;
}

@singleton
class AuthService {
  // Singleton implementation
}

@lazySingleton
class CacheService {
  // Lazy singleton implementation
}
```

### Dependency Injection Best Practices
- Register dependencies at app startup
- Use appropriate lifetime scopes (singleton, transient, scoped)
- Prefer constructor injection over service locator pattern
- Mock dependencies in tests

## Error Handling

### Custom Exception Classes
```dart
abstract class AppException implements Exception {
  const AppException(this.message, [this.code]);
  final String message;
  final String? code;
}

class NetworkException extends AppException {
  const NetworkException(super.message, [super.code]);
}

class ValidationException extends AppException {
  const ValidationException(super.message, [super.code]);
}

class AuthenticationException extends AppException {
  const AuthenticationException(super.message, [super.code]);
}
```

### Error Handling Patterns
```dart
// Repository error handling
TaskEither<AppException, List<User>> getUsers() async {
  try {
    final users = await _apiClient.getUsers();
    return Right(users);
  } on DioException catch (e) {
    return Left(NetworkException(e.message ?? 'Network error'));
  } catch (e) {
    return Left(AppException('Unexpected error: $e'));
  }
}

// BLoC error handling
Future<void> _onGetUsers(
  GetUsersEvent event,
  Emitter<UserState> emit,
) async {
  emit(UserLoading());
  final result = await _userRepository.getUsers();
  result.fold(
    (exception) => emit(UserError(exception.message)),
    (users) => emit(UserLoaded(users)),
  );
}
```

## Testing Best Practices

### Test Structure
```dart
// Unit test structure
group('UserRepository', () {
  late UserRepository userRepository;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    userRepository = UserRepository(mockApiClient);
  });

  group('getUsers', () {
    test('should return list of users when API call is successful', () async {
      // Arrange
      const expectedUsers = [User(id: '1', name: 'John')];
      when(() => mockApiClient.getUsers())
          .thenAnswer((_) async => expectedUsers);

      // Act
      final result = await userRepository.getUsers();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (error) => fail('Expected success but got error: $error'),
        (users) => expect(users, equals(expectedUsers)),
      );
    });
  });
});
```

### Widget Testing
```dart
testWidgets('LoginPage should show error when login fails', (tester) async {
  // Arrange
  final mockAuthBloc = MockAuthBloc();
  whenListen(
    mockAuthBloc,
    Stream.fromIterable([
      AuthInitial(),
      AuthLoading(),
      AuthFailure('Invalid credentials'),
    ]),
    initialState: AuthInitial(),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<AuthBloc>(
        create: (_) => mockAuthBloc,
        child: const LoginPage(),
      ),
    ),
  );

  // Act
  await tester.enterText(find.byType(TextFormField).first, 'test@test.com');
  await tester.enterText(find.byType(TextFormField).last, 'password');
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();

  // Assert
  expect(find.text('Invalid credentials'), findsOneWidget);
});
```

## Code Generation

### Build Runner Commands
```bash
# Generate all files
flutter packages pub run build_runner build --delete-conflicting-outputs

# Watch for changes
flutter packages pub run build_runner watch --delete-conflicting-outputs

# Clean generated files
flutter packages pub run build_runner clean
```

### Freezed Models
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '../common/user.freezed.dart';
part '../common/user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    String? email,
    @Default(false) bool isActive,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

### JSON Serialization
```dart
@JsonSerializable()
class ApiResponse<T> {
  final T data;
  final String message;
  final int statusCode;

  ApiResponse({
    required this.data,
    required this.message,
    required this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);
}
```

## Performance Optimization

### Image Optimization
```dart
// Use CachedNetworkImage for network images
CachedNetworkImage(
  imageUrl: 'https://example.com/image.jpg',
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
  memCacheWidth: 300, // Resize in memory
  memCacheHeight: 300,
);

// Optimize asset images
Image.asset(
  'assets/images/hero_image.jpg',
  width: 300,
  height: 300,
  fit: BoxFit.cover,
);
```

### List Performance
```dart
// Use ListView.builder for large lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(
      key: ValueKey(items[index].id),
      title: Text(items[index].name),
    );
  },
);

// Use ListView.separated for dividers
ListView.separated(
  itemCount: items.length,
  separatorBuilder: (context, index) => const Divider(),
  itemBuilder: (context, index) => ListTile(
    title: Text(items[index].name),
  ),
);
```

### Memory Management
```dart
class _MyPageState extends State<MyPage> {
  late StreamSubscription _subscription;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _subscription = stream.listen(handleData);
  }

  @override
  void dispose() {
    _controller.dispose();
    _subscription.cancel();
    super.dispose();
  }
}
```

## Security Best Practices

### Sensitive Data Handling
- Store sensitive data in secure storage (flutter_secure_storage)
- Never hardcode API keys or secrets
- Use environment variables for configuration
- Implement certificate pinning for API calls

### Input Validation
```dart
class ValidationUtils {
  static String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) return 'Email is required';
    
    const emailRegex = r'^[^@]+@[^@]+\.[^@]+$';
    if (!RegExp(emailRegex).hasMatch(value!)) {
      return 'Enter a valid email';
    }
    
    return null;
  }

  static String? validatePassword(String? value) {
    if (value?.isEmpty ?? true) return 'Password is required';
    if (value!.length < 8) return 'Password must be at least 8 characters';
    
    return null;
  }
}
```

## Accessibility

### Semantic Labels
```dart
Semantics(
  label: 'Login button',
  child: ElevatedButton(
    onPressed: handleLogin,
    child: const Text('Login'),
  ),
);

// Or use semanticsLabel parameter
Image.asset(
  'assets/logo.png',
  semanticLabel: 'Company logo',
);
```

### Focus Management
```dart
class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          focusNode: _emailFocus,
          onFieldSubmitted: (_) {
            FocusScope.of(context).requestFocus(_passwordFocus);
          },
        ),
        TextFormField(
          focusNode: _passwordFocus,
          onFieldSubmitted: (_) => handleLogin(),
        ),
      ],
    );
  }
}
```