# Setup New Feature

## Overview
Systematically set up a new feature following Clean Architecture principles, from initial planning through implementation structure creation.

## Steps

### 1. **Define Requirements**
- [ ] Clarify feature scope and goals
- [ ] Identify user stories and acceptance criteria
- [ ] Define API requirements and data models
- [ ] Plan UI/UX flow and wireframes

### 2. **Create Feature Branch**
```bash
# Create and switch to feature branch
git checkout -b feature/ARTLEXIS-XXX/feature-description

# Ensure latest dependencies
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 3. **Plan Architecture**

#### Domain Layer Planning:
- [ ] Define entities (business objects)
- [ ] Create repository interfaces
- [ ] Plan use cases (business logic)
- [ ] Define parameter classes for use cases

#### Data Layer Planning:
- [ ] Design API models with JSON serialization
- [ ] Plan data sources (remote/local)
- [ ] Design repository implementations
- [ ] Consider caching strategy

#### Presentation Layer Planning:
- [ ] Design BLoC/Cubit states
- [ ] Plan page and widget structure
- [ ] Design routing and navigation
- [ ] Plan localization keys

### 4. **Create Feature Structure**

#### Domain Layer:
```bash
# Create domain structure
mkdir -p lib/src/domain/entities/[feature]
mkdir -p lib/src/domain/repositories/[feature]  
mkdir -p lib/src/domain/usecases/[feature]
```

#### Data Layer:
```bash
# Create data structure
mkdir -p lib/src/data/models/[feature]
mkdir -p lib/src/data/datasources/[feature]
mkdir -p lib/src/data/repositories/[feature]
```

#### Presentation Layer:
```bash
# Create presentation structure  
mkdir -p lib/src/presentation/pages/[feature]
mkdir -p lib/src/presentation/widgets/[feature]
mkdir -p lib/src/presentation/blocs/[feature]
```

### 5. **Implement Base Classes**

#### Create Entity:
```dart
// lib/src/domain/entities/[feature]/[entity].dart
@freezed
class [Entity] with _$[Entity] {
  const factory [Entity]({
    required String id,
    required String name,
    // Add other properties
  }) = _[Entity];
}
```

#### Create Repository Interface:
```dart
// lib/src/domain/repositories/[feature]/i_[feature]_repository.dart
abstract class I[Feature]Repository {
  TaskEither<AppException, [Entity]> get[Entity](String id);
  TaskEither<AppException, List<[Entity]>> get[Entity]List();
}
```

#### Create Use Case:
```dart
// lib/src/domain/usecases/[feature]/get_[entity]_usecase.dart
@lazySingleton
class Get[Entity]UseCase extends UseCaseWithParams<[Entity], Get[Entity]Params> {
  final I[Feature]Repository repository;
  
  Get[Entity]UseCase(this.repository);
  
  @override
  TaskEither<AppException, [Entity]> call(Get[Entity]Params params) {
    return repository.get[Entity](params.id);
  }
}

@freezed
class Get[Entity]Params with _$Get[Entity]Params {
  const factory Get[Entity]Params({
    required String id,
  }) = _Get[Entity]Params;
}
```

#### Create Data Model:
```dart
// lib/src/data/models/[feature]/[entity]_model.dart
@freezed
class [Entity]Model with _$[Entity]Model {
  const factory [Entity]Model({
    required String id,
    required String name,
    // Add other properties
  }) = _[Entity]Model;
  
  const [Entity]Model._();
  
  factory [Entity]Model.fromJson(Map<String, dynamic> json) => 
      _$[Entity]ModelFromJson(json);
  
  [Entity] toEntity() => [Entity](
    id: id,
    name: name,
    // Map other properties
  );
}
```

#### Create Repository Implementation:
```dart
// lib/src/data/repositories/[feature]/[feature]_repository.dart
@LazySingleton(as: I[Feature]Repository)
class [Feature]Repository implements I[Feature]Repository {
  final [Feature]RemoteDataSource remoteDataSource;
  
  [Feature]Repository(this.remoteDataSource);
  
  @override
  TaskEither<AppException, [Entity]> get[Entity](String id) async {
    try {
      final model = await remoteDataSource.get[Entity](id);
      return Right(model.toEntity());
    } catch (e) {
      return Left(AppException.fromException(e as Exception));
    }
  }
}
```

#### Create BLoC/Cubit:
```dart
// lib/src/presentation/blocs/[feature]/[feature]_cubit.dart
@injectable
class [Feature]Cubit extends HydratedCubit<[Feature]State> {
  final Get[Entity]UseCase get[Entity]UseCase;
  
  [Feature]Cubit(this.get[Entity]UseCase) : super(const [Feature]State.initial());
  
  Future<void> load[Entity](String id) async {
    emit(const [Feature]State.loading());
    
    final result = await get[Entity]UseCase(Get[Entity]Params(id: id));
    
    result.fold(
      (error) => emit([Feature]State.error(error)),
      (entity) => emit([Feature]State.success(entity)),
    );
  }
}

@freezed
class [Feature]State with _$[Feature]State {
  const factory [Feature]State.initial() = _Initial;
  const factory [Feature]State.loading() = _Loading;  
  const factory [Feature]State.success([Entity] entity) = _Success;
  const factory [Feature]State.error(AppException exception) = _Error;
}
```

### 6. **Add Localization**
```bash
# Add feature-specific localization keys to ARB files
# Run localization generation
./tools/macos/localization/generate_localization.sh
```

### 7. **Create Tests**
```bash
# Create test structure
mkdir -p test/unit/domain/usecases/[feature]
mkdir -p test/unit/data/repositories/[feature]
mkdir -p test/unit/presentation/blocs/[feature]
mkdir -p test/widget/[feature]
```

### 8. **Generate Code**
```bash
# Generate all code (models, DI, etc.)
dart run build_runner build --delete-conflicting-outputs
```

## Feature Development Checklist

### Domain Layer:
- [ ] Entities created with proper validation
- [ ] Repository interfaces defined
- [ ] Use cases implemented with proper error handling
- [ ] Parameter classes created for use cases

### Data Layer:
- [ ] Models created with JSON serialization
- [ ] Data sources implemented
- [ ] Repository implementations created
- [ ] Proper error handling with AppException

### Presentation Layer:
- [ ] BLoC/Cubit created with proper state management
- [ ] Pages created following page-view separation
- [ ] Widgets created with responsive design
- [ ] Navigation routes added

### Testing:
- [ ] Unit tests for use cases
- [ ] Unit tests for repositories  
- [ ] Unit tests for BLoCs/Cubits
- [ ] Widget tests for UI components

### Integration:
- [ ] Dependency injection configured
- [ ] Routing added to app router
- [ ] Localization keys added
- [ ] Code generation completed

### Verification:
- [ ] Feature builds without errors
- [ ] All tests pass
- [ ] Code analysis passes
- [ ] Feature works in all flavors

## Common Patterns

### Error Handling:
```dart
result.fold(
  (error) => emit(State.error(error)),
  (data) => emit(State.success(data)),
);
```

### Dependency Injection:
```dart
// Get dependency
final useCase = AppDI.injector.get<GetEntityUseCase>();

// Register in module
@lazySingleton
class MyClass { /* ... */ }
```

### Responsive UI:
```dart
// Use ScreenUtil for responsive design
Container(
  width: 200.w,
  height: 100.h,
  padding: EdgeInsets.all(16.w),
  child: Text(
    'Hello',
    style: TextStyle(fontSize: 16.sp),
  ),
)
```

## Next Steps
1. Implement the feature following the created structure
2. Write comprehensive tests
3. Add proper error handling
4. Test across all flavors
5. Create pull request following GitFlow workflow