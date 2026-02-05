---
trigger: model_decision
description: BLoC state management patterns and guidelines for Cubit and Bloc usage
---

# BLoC State Management Rules

## When to Use Cubit vs Bloc

### Use Cubit for Simple State (90% of cases)
- Single responsibility
- Simple state transitions
- Direct method calls

### Use Bloc for Complex State (10% of cases)  
- Multiple event types
- Complex business logic
- Event transformation needed

## State Architecture Pattern

### State Definition with Freezed
```dart
@freezed
class UserState with _$UserState {
  const factory UserState.initial() = _Initial;
  const factory UserState.loading() = _Loading;
  const factory UserState.success(User user) = _Success;
  const factory UserState.error(AppException exception) = _Error;
}
```

### Cubit Implementation
```dart
@injectable
class UserCubit extends HydratedCubit<UserState> {
  final GetUserUseCase getUserUseCase;
  final UpdateUserUseCase updateUserUseCase;
  
  UserCubit(this.getUserUseCase, this.updateUserUseCase) 
    : super(const UserState.initial());
  
  Future<void> loadUser(String userId) async {
    emit(const UserState.loading());
    
    final result = await getUserUseCase(GetUserParams(userId: userId));
    
    result.fold(
      (error) => emit(UserState.error(error)),
      (user) => emit(UserState.success(user)),
    );
  }
  
  @override
  UserState? fromJson(Map<String, dynamic> json) {
    // Implement persistence logic
    return null; // or parsed state
  }
  
  @override
  Map<String, dynamic>? toJson(UserState state) {
    // Implement persistence logic
    return state.maybeWhen(
      success: (user) => {'user': user.toJson()},
      orElse: () => null,
    );
  }
}
```

## UI Integration Patterns

### Page Structure
```dart
class UserPage extends StatelessWidget {
  const UserPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppDI.injector.get<UserCubit>(),
      child: const UserView(),
    );
  }
}
```

### View Implementation
```dart
class UserView extends StatelessWidget {
  const UserView({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.text.userProfile)),
      body: BlocBuilder<UserCubit, UserState>(
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox.shrink(),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            success: (user) => UserContent(user: user),
            error: (exception) => ErrorWidget(
              exception: exception,
              onRetry: () => context.read<UserCubit>().loadUser(user.id),
            ),
          );
        },
      ),
    );
  }
}
```

### BlocListener for Side Effects
```dart
BlocListener<UserCubit, UserState>(
  listener: (context, state) {
    state.whenOrNull(
      success: (user) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.text.userLoadedSuccessfully)),
        );
      },
      error: (exception) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(exception.message)),
        );
      },
    );
  },
  child: UserContent(),
)
```

### BlocConsumer for Both State and Side Effects
```dart
BlocConsumer<UserCubit, UserState>(
  listener: (context, state) {
    // Handle side effects
  },
  builder: (context, state) {
    // Build UI based on state
  },
)
```

## State Persistence

### Hydrated Cubit Setup
```dart
class UserCubit extends HydratedCubit<UserState> {
  @override
  UserState? fromJson(Map<String, dynamic> json) {
    try {
      if (json['type'] == 'success') {
        final user = User.fromJson(json['user']);
        return UserState.success(user);
      }
      return const UserState.initial();
    } catch (e) {
      return const UserState.initial();
    }
  }
  
  @override
  Map<String, dynamic>? toJson(UserState state) {
    return state.maybeWhen(
      success: (user) => {
        'type': 'success',
        'user': user.toJson(),
      },
      orElse: () => null,
    );
  }
}
```

## Testing BLoCs

### Cubit Testing
```dart
group('UserCubit', () {
  late UserCubit cubit;
  late MockGetUserUseCase mockGetUserUseCase;
  
  setUp(() {
    mockGetUserUseCase = MockGetUserUseCase();
    cubit = UserCubit(mockGetUserUseCase);
  });
  
  blocTest<UserCubit, UserState>(
    'emits success state when user is loaded',
    build: () => cubit,
    act: (cubit) => cubit.loadUser('user-id'),
    expect: () => [
      const UserState.loading(),
      UserState.success(mockUser),
    ],
    setUp: () {
      when(() => mockGetUserUseCase.call(any()))
          .thenAnswer((_) async => Right(mockUser));
    },
  );
});
```

## Error Handling in BLoC

### Always Handle Errors
```dart
Future<void> performAction() async {
  emit(const FeatureState.loading());
  
  try {
    final result = await useCase.call(params);
    
    result.fold(
      (error) => emit(FeatureState.error(error)),
      (data) => emit(FeatureState.success(data)),
    );
  } catch (e) {
    emit(FeatureState.error(AppException.fromException(e)));
  }
}
```

## Performance Considerations

### Use Equatable for State Comparison
States with Freezed automatically implement equality checking.

### Avoid Rebuilds with BlocSelector
```dart
BlocSelector<UserCubit, UserState, String>(
  selector: (state) => state.maybeWhen(
    success: (user) => user.name,
    orElse: () => '',
  ),
  builder: (context, userName) {
    return Text(userName);
  },
)
```