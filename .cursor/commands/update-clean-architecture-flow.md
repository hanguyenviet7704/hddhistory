# Update Clean Architecture Module Command

This command provides a complete guide for creating or updating Clean Architecture modules in the Flutter project. The approach uses API definitions in `@remote` folders as the source of truth and creates complete flows through all architecture layers.

## Command Usage

To work with any Clean Architecture module, provide the path to the module's remote datasource folder:

```
update-clean-architecture-flow @remote
```

Or specify a specific module:
```
update-clean-architecture-flow lib/src/[module_name]/data/datasources/remote
```

Examples:
```
update-clean-architecture-flow @remote
update-clean-architecture-flow lib/src/course/data/datasources/remote
update-clean-architecture-flow lib/src/auth/data/datasources/remote
```

## Core Principles

1. **API as Source of Truth**: All API files in `data/datasources/remote/` define the application's needs
2. **One API = One Flow**: Each API file should have its own repository, use cases, and cubit
3. **Read-Only First**: Most apps only need GET endpoints; avoid adding POST/PUT/DELETE unless explicitly defined in API
4. **Avoid Naming Conflicts**: Use specific enum names (e.g., `CoursePublishStatus` not `CourseStatus`) to avoid conflicts with state status enums
5. **Consistent Patterns**: Follow the same structure across all modules for maintainability

## Agent Instructions

When this command is invoked, follow these steps:

### 1. Analyze API Files in @remote

1. **Locate all API files** in `lib/src/[module_name]/data/datasources/remote/`
2. **For each API file**, identify:
   - API name (e.g., `CourseApi`, `CourseLessonApi`)
   - Endpoints defined (GET, POST, PUT, DELETE)
   - Response types (models returned)
   - Request parameters

3. **Determine what needs to be created/updated**:
   - Each API file should have its own complete flow
   - Example: `CourseApi` → `CourseRepository` → `CourseCubit`
   - Example: `CourseLessonApi` → `CourseLessonRepository` → `CourseLessonCubit`

### 2. Verify or Create Models and Entities

For each response type used in the API:

**Check if models exist** in `lib/src/[module_name]/data/models/`:
- If model exists in another module (e.g., `LessonModel` in lesson module), reuse it
- If model doesn't exist, create it following the pattern below

**Model Structure**:
```dart
@freezed
abstract class [Name]Model with _$[Name]Model {
  const factory [Name]Model({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default([Name]PublishStatus.published) [Name]PublishStatus status,
  }) = _[Name]Model;

  factory [Name]Model.fromJson(Map<String, dynamic> json) => _$[Name]ModelFromJson(json);
}

enum [Name]PublishStatus {
  @JsonValue('published') published,
  @JsonValue('draft') draft,
  @JsonValue('inactive') inactive,
}
```

**Entity Structure** (mirrors model in domain layer):
```dart
@freezed
abstract class [Name]Entity with _$[Name]Entity {
  const factory [Name]Entity({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default([Name]PublishStatus.published) [Name]PublishStatus status,
  }) = _[Name]Entity;

  factory [Name]Entity.fromJson(Map<String, dynamic> json) => _$[Name]EntityFromJson(json);
}
```

**Model Extension**:
```dart
extension [Name]ModelExtension on [Name]Model {
  [Name]Entity toEntity() => [Name]Entity(
    id: id,
    title: title,
    description: description,
    image: image,
    status: status,
  );
}
```

### 3. Create Local Data Source (for each API)

For each API, create a corresponding local data source for offline caching:

**File**: `lib/src/[module_name]/data/datasources/local/[api_name]_local_data_source.dart`

```dart
part of '../../../[module_name].dart';

abstract class [ApiName]LocalDataSource {
  Future<List<[Model]>> getCached[Models]();
  Future<void> cache[Models](List<[Model]> models);
  Future<[Model]?> getCached[Model](String id);
  Future<void> cache[Model]([Model] model);
  Future<void> clearCache();
}

@LazySingleton(as: [ApiName]LocalDataSource)
class [ApiName]LocalDataSourceImpl implements [ApiName]LocalDataSource {
  static const String _cacheKey = '[snake_case]_cache';
  static const String _cacheListKey = '[snake_case]_list_cache';

  final ILocalStoreService _localStoreService;

  [ApiName]LocalDataSourceImpl(this._localStoreService);

  @override
  Future<List<[Model]>> getCached[Models]() async {
    try {
      final data = await _localStoreService.getMap(key: _cacheListKey);
      if (data.isEmpty) return [];
      final List<dynamic> jsonList = data['items'] ?? [];
      return jsonList.map((json) => [Model].fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cache[Models](List<[Model]> models) async {
    try {
      final jsonList = models.map((model) => model.toJson()).toList();
      await _localStoreService.setMap(key: _cacheListKey, value: {'items': jsonList});
    } catch (e) {}
  }

  @override
  Future<[Model]?> getCached[Model](String id) async {
    try {
      final cacheKey = '${_cacheKey}_$id';
      final data = await _localStoreService.getMap(key: cacheKey);
      if (data.isEmpty) return null;
      return [Model].fromJson(data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cache[Model]([Model] model) async {
    try {
      final cacheKey = '${_cacheKey}_${model.id}';
      await _localStoreService.setMap(key: cacheKey, value: model.toJson());
    } catch (e) {}
  }

  @override
  Future<void> clearCache() async {
    try {
      await _localStoreService.remove(key: _cacheListKey);
    } catch (e) {}
  }
}
```

### 4. Create Repository Interface

**File**: `lib/src/[module_name]/domain/repositories/i_[api_name]_repository.dart`

```dart
part of '../../[module_name].dart';

abstract class I[ApiName]Repository {
  TaskEither<AppException, BasePageBreak<[Entity]>> getAll[Entities](PageBreakRequest request);
  TaskEither<AppException, [Entity]> get[Entity](String id);
}
```

### 5. Create Repository Implementation

**File**: `lib/src/[module_name]/data/repositories/[api_name]_repository.dart`

```dart
part of '../../[module_name].dart';

@LazySingleton(as: I[ApiName]Repository)
class [ApiName]Repository with RestfulRequestHandlerMixin implements I[ApiName]Repository {
  final [ApiName]Api _api;
  final [ApiName]LocalDataSource _localDataSource;

  [ApiName]Repository(this._api, this._localDataSource);

  @override
  TaskEither<AppException, [Entity]> get[Entity](String id) {
    return callApiWithTransform<[Model], [Entity]>(
      apiCall: () => _api.get[Entity](id),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cache[Model](data ?? [Model]()),
      onError: () async {
        final cachedModel = await _localDataSource.getCached[Model](id);
        return cachedModel?.toEntity();
      },
      defaultValue: [Entity](),
    );
  }

  @override
  TaskEither<AppException, BasePageBreak<[Entity]>> getAll[Entities](PageBreakRequest request) {
    return callApiPageBreak<[Model], [Entity]>(
      apiCall: () => _api.getAll[Entities](request),
      transform: (model) => model.toEntity(),
      onSuccess: (pageData) async {
        await _localDataSource.cache[Models](pageData.items);
      },
      onError: () async {
        final cachedModels = await _localDataSource.getCached[Models]();
        if (cachedModels.isNotEmpty) {
          return BasePageBreak<[Entity]>(
            currentPage: 1,
            totalPages: 1,
            itemsPerPage: cachedModels.length,
            items: cachedModels.map((model) => model.toEntity()).toList(),
          );
        }
        return null;
      },
    );
  }
}
```

### 6. Create Use Cases

For each repository method, create a corresponding use case:

**Files**: 
- `lib/src/[module_name]/domain/usecases/get_all_[entities]_usecase.dart`
- `lib/src/[module_name]/domain/usecases/get_[entity]_usecase.dart`

```dart
part of '../../[module_name].dart';

@lazySingleton
class GetAll[Entities]UseCase implements UseCaseWithParams<PageBreakRequest, BasePageBreak<[Entity]>> {
  final I[ApiName]Repository _repository;

  GetAll[Entities]UseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<[Entity]>> call(PageBreakRequest params) {
    return _repository.getAll[Entities](params);
  }
}
```

```dart
part of '../../[module_name].dart';

@lazySingleton
class Get[Entity]UseCase implements UseCaseWithParams<String, [Entity]> {
  final I[ApiName]Repository _repository;

  Get[Entity]UseCase(this._repository);

  @override
  TaskEither<AppException, [Entity]> call(String params) {
    return _repository.get[Entity](params);
  }
}
```

### 7. Create State

**File**: `lib/src/[module_name]/presentation/blocs/[api_name]_state.dart`

```dart
part of '../../[module_name].dart';

enum [ApiName]Status { initial, loading, success, failure }

@freezed
abstract class [ApiName]State with _$[ApiName]State {
  const factory [ApiName]State({
    @Default([ApiName]Status.initial) [ApiName]Status status,
    @Default(BasePageBreak<[Entity]>()) BasePageBreak<[Entity]> pageData,
    [Entity]? selected[Entity],
    String? errorMessage,
  }) = _[ApiName]State;

  factory [ApiName]State.initial() => [ApiName]State();

  factory [ApiName]State.fromJson(Map<String, dynamic> json) => _$[ApiName]StateFromJson(json);
}
```

### 8. Create Cubit

**File**: `lib/src/[module_name]/presentation/cubits/[api_name]_cubit.dart`

```dart
part of '../../[module_name].dart';

@lazySingleton
class [ApiName]Cubit extends Cubit<[ApiName]State> with CubitUseCaseHandlerMixin<[ApiName]State> {
  final GetAll[Entities]UseCase _getAll[Entities]UseCase;
  final Get[Entity]UseCase _get[Entity]UseCase;

  [ApiName]Cubit(
    this._getAll[Entities]UseCase,
    this._get[Entity]UseCase,
  ) : super([ApiName]State.initial());

  void loadAll[Entities]({bool isInit = false}) async {
    if (!isInit && state.status == [ApiName]Status.loading) return;
    if (!isInit && state.pageData.isLastPage) return;

    PageBreakRequest pageRequest = isInit 
      ? const PageBreakRequest() 
      : PageBreakRequest(page: state.pageData.nextPage);

    await runUseCasePageBreak<[Entity]>(
      usecase: () => _getAll[Entities]UseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: [ApiName]Status.loading),
      onFailure: (error) {
        emit(state.copyWith(status: [ApiName]Status.failure, errorMessage: error));
      },
      onSuccess: (pageData) {
        emit(state.copyWith(status: [ApiName]Status.success, pageData: pageData));
      },
    );
  }

  void load[Entity](String id) async {
    await runUseCase<[Entity]>(
      usecase: () => _get[Entity]UseCase(id),
      buildLoadingState: () => state.copyWith(status: [ApiName]Status.loading),
      onFailure: (error) {
        emit(state.copyWith(status: [ApiName]Status.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(state.copyWith(status: [ApiName]Status.success, selected[Entity]: item));
      },
    );
  }
}
```

### 9. Update Module Parts

Ensure all new files are added to the module's main file in the correct order:

```dart
library;

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:meup/meup.dart';
import 'package:retrofit/retrofit.dart';

part '[module_name].freezed.dart';
part '[module_name].g.dart';

//* Data Layer - Models, Datasources, Repositories
part 'data/datasources/local/[api1_name]_local_data_source.dart';
part 'data/datasources/local/[api2_name]_local_data_source.dart';
part 'data/datasources/remote/[api1_name].dart';
part 'data/datasources/remote/[api2_name].dart';
part 'data/models/[model1]_model.dart';
part 'data/models/[model2]_model.dart';
part 'data/repositories/[api1_name]_repository.dart';
part 'data/repositories/[api2_name]_repository.dart';

//* Domain Layer - Entities, Repositories, Use Cases
part 'domain/entities/[entity1]_entity.dart';
part 'domain/entities/[entity2]_entity.dart';
part 'domain/repositories/i_[api1_name]_repository.dart';
part 'domain/repositories/i_[api2_name]_repository.dart';
part 'domain/usecases/get_all_[entities1]_usecase.dart';
part 'domain/usecases/get_[entity1]_usecase.dart';
part 'domain/usecases/get_all_[entities2]_usecase.dart';
part 'domain/usecases/get_[entity2]_usecase.dart';

//* Presentation Layer - States, Cubits
part 'presentation/blocs/[api1_name]_state.dart';
part 'presentation/blocs/[api2_name]_state.dart';
part 'presentation/cubits/[api1_name]_cubit.dart';
part 'presentation/cubits/[api2_name]_cubit.dart';

//* Presentation Layer - Pages
part 'presentation/pages/[module_name]_page.dart';
```

### 10. Regenerate Generated Files

Run the build runner to regenerate Freezed and JSON serialization files:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 11. Verify and Fix Linter Errors

Check for any lint errors and fix them:

```bash
flutter analyze
```

Common fixes needed:
- Enum naming conflicts (use specific names like `[Name]PublishStatus` instead of `[Name]Status`)
- Missing imports in module file
- Incorrect part paths
- Empty catch blocks (acceptable for cache operations)

## Important Considerations

### API as Source of Truth

- **Always start with API definitions**: The API files in `@remote` define what the app needs
- **Don't add endpoints that don't exist**: Only implement what's defined in the API
- **One API file = One complete flow**: Each API should have its own repository, use cases, and cubit

### Naming Conventions

**Avoid Enum Conflicts**:
```dart
// ❌ BAD - Conflicts with state status enum
enum CourseStatus { initial, loading, success, failure }

// ✅ GOOD - Specific to domain
enum CoursePublishStatus { published, draft, inactive }
```

**Consistent Naming Patterns**:
- API: `[Name]Api` (e.g., `CourseApi`, `CourseLessonApi`)
- Repository: `[ApiName]Repository` (e.g., `CourseRepository`, `CourseLessonRepository`)
- Interface: `I[ApiName]Repository` (e.g., `ICourseRepository`, `ICourseLessonRepository`)
- Local Data Source: `[ApiName]LocalDataSource`
- State: `[ApiName]State` with `[ApiName]Status` enum
- Cubit: `[ApiName]Cubit`

### Default Values

Always provide default values for non-nullable fields in Freezed models and entities:

```dart
@Default('') String stringValue,
@Default(false) bool boolValue,
@Default([]) List<Type> listValue,
@Default(0) int intValue,
@Default(BaseMultiLanguage()) BaseMultiLanguage multiLang,
```

### Model Reuse Across Modules

When an API uses models from another module (e.g., `CourseLessonApi` uses `LessonModel`):
- Import the model from its original module
- Don't duplicate the model
- The repository in the current module can still use it

### List Field Conversion

When converting between models and entities with list fields, always map each item individually:

```dart
// Model to Entity
options: options.map((model) => model.toEntity()).toList(),

// Entity to JSON for API
'options': entity.options.map((e) => {
  'id': e.id,
  'icon': e.icon,
  'label': e.label.toJson(),
}).toList(),
```

### Multi-language Support

For fields that support multiple languages, use the BaseMultiLanguage type:

```dart
@Default(BaseMultiLanguage()) BaseMultiLanguage label,
```

And when converting to JSON:

```dart
'label': e.label.toJson(),
```

### DateTime Fields

For DateTime fields, use nullable types and convert to ISO 8601 strings when serializing to JSON:

```dart
DateTime? createdAt,
DateTime? updatedAt,

// In JSON conversion
'createdAt': entity.createdAt?.toIso8601String(),
'updatedAt': entity.updatedAt?.toIso8601String(),
```

### Error Handling

Maintain consistent error handling patterns in repositories:

**For single item GET requests** (with offline fallback):
```dart
return callApiWithTransform<[Model], [Entity]>(
  apiCall: () => _api.get[Entity](id),
  transform: (model) => model.toEntity(),
  onSuccess: (data) async => await _localDataSource.cache[Model](data ?? [Model]()),
  onError: () async {
    final cachedModel = await _localDataSource.getCached[Model](id);
    return cachedModel?.toEntity();
  },
  defaultValue: [Entity](),
);
```

**For paginated GET requests** (with offline fallback):
```dart
return callApiPageBreak<[Model], [Entity]>(
  apiCall: () => _api.getAll[Entities](request),
  transform: (model) => model.toEntity(),
  onSuccess: (pageData) async {
    await _localDataSource.cache[Models](pageData.items);
  },
  onError: () async {
    final cachedModels = await _localDataSource.getCached[Models]();
    if (cachedModels.isNotEmpty) {
      return BasePageBreak<[Entity]>(
        currentPage: 1,
        totalPages: 1,
        itemsPerPage: cachedModels.length,
        items: cachedModels.map((model) => model.toEntity()).toList(),
      );
    }
    return null;
  },
);
```

### Offline Support

Always implement local caching for read operations:
- Cache successful API responses
- Return cached data when API fails
- Clear cache when appropriate (logout, data invalidation)

## Common Issues and Solutions

### Issue: "There's no constant named 'loading' in '[Name]Status'"

**Problem**: Enum naming conflict between state status and domain status.

**Solution**: Rename domain status enums to be more specific:
```dart
// Change CourseStatus to CoursePublishStatus
enum CoursePublishStatus { published, draft, inactive }
```

### Issue: "The parameter 'field' is non-nullable but is neither required nor marked with @Default"

**Solution**: Add `@Default` annotation to all non-nullable fields in Freezed models and entities.

### Issue: "The argument type 'List<Model>' can't be assigned to the parameter type 'List<Entity>'"

**Solution**: Use `.map()` to convert each item in the list:
```dart
items.map((model) => model.toEntity()).toList()
```

### Issue: Model exists in different module

**Problem**: `CourseLessonApi` needs `LessonModel` but it's in the lesson module.

**Solution**: Reuse the model from its original module. Don't duplicate it.

### Issue: "The redirected constructor has incompatible parameters"

**Solution**: Run the build runner to regenerate the Freezed files:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Issue: Too many API endpoints in one file

**Problem**: API file has both CRUD and specialized endpoints mixed together.

**Solution**: Split into multiple API files, each with a focused purpose:
- `CourseApi` for basic course operations
- `CourseLessonApi` for lesson-specific operations
- Each gets its own repository and cubit

## Field Type Guidelines

### Supported Field Types

- `String` - Text fields with `@Default('')`
- `int` - Integer fields with `@Default(0)`
- `bool` - Boolean fields with `@Default(false)`
- `List<Type>` - List fields with `@Default([])`
- `DateTime?` - Nullable DateTime fields (no default needed)
- `BaseMultiLanguage` - Multi-language text fields with `@Default(BaseMultiLanguage())`

### Field Naming Conventions

- Use camelCase for field names (e.g., `userName`, `createdAt`)
- Use descriptive names that clearly indicate the field's purpose
- Avoid abbreviations unless they are widely understood

## Checklist

### For Each API File:

- [ ] **Step 1: Analyze API**
  - [ ] Identify all endpoints (GET, POST, PUT, DELETE)
  - [ ] Identify response models
  - [ ] Check if models exist or need creation

- [ ] **Step 2: Models & Entities**
  - [ ] Create or verify models in `data/models/`
  - [ ] Create or verify entities in `domain/entities/`
  - [ ] Add model extensions with `toEntity()`
  - [ ] Use specific enum names (e.g., `[Name]PublishStatus`)

- [ ] **Step 3: Local Data Source**
  - [ ] Create `[ApiName]LocalDataSource` interface
  - [ ] Implement `[ApiName]LocalDataSourceImpl`
  - [ ] Add cache methods (get, set, clear)

- [ ] **Step 4: Repository**
  - [ ] Create `I[ApiName]Repository` interface
  - [ ] Implement `[ApiName]Repository`
  - [ ] Add methods matching API endpoints
  - [ ] Implement offline fallback with local cache

- [ ] **Step 5: Use Cases**
  - [ ] Create use case for each repository method
  - [ ] Follow naming: `Get[Entity]UseCase`, `GetAll[Entities]UseCase`

- [ ] **Step 6: Presentation Layer**
  - [ ] Create `[ApiName]State` with `[ApiName]Status` enum
  - [ ] Create `[ApiName]Cubit`
  - [ ] Inject use cases into cubit
  - [ ] Implement load methods with pagination support

- [ ] **Step 7: Integration**
  - [ ] Add all new parts to module file
  - [ ] Run `dart run build_runner build --delete-conflicting-outputs`
  - [ ] Fix any lint errors
  - [ ] Verify no enum naming conflicts

### Quality Checks:

- [ ] All API endpoints have corresponding repository methods
- [ ] All repository methods have use cases
- [ ] All non-nullable fields have `@Default` values
- [ ] Enum names don't conflict with state status
- [ ] Local caching implemented for GET operations
- [ ] Error handling follows project patterns
- [ ] Module parts file is organized correctly
- [ ] No linter errors remain

## Real-World Example

### Scenario: Course Module with 2 APIs

**API Files**:
1. `CourseApi` - Basic course operations (getAllCourses, getCourse, getRoadmap)
2. `CourseLessonApi` - Lesson operations (getAllLessons, getLesson)

**Implementation**:
```
Course Module
├── CourseApi → CourseRepository → CourseCubit
│   ├── Uses: CourseModel, RoadmapModel
│   └── Endpoints: GET /courses, GET /courses/{id}, GET /courses/{id}/roadmap
│
└── CourseLessonApi → CourseLessonRepository → CourseLessonCubit
    ├── Uses: LessonModel (from lesson module)
    └── Endpoints: GET /courses-lessons, GET /courses-lessons/{id}
```

**Result**:
- 2 API files = 2 complete flows
- Shared models between modules (LessonModel reused)
- No CRUD operations (read-only APIs)
- Complete offline support through local caching

## Conclusion

Following this guide ensures that:
1. **API definitions drive implementation** - No unnecessary code
2. **Clean separation of concerns** - Each API has its own flow
3. **Offline-first approach** - Always cache and fallback
4. **Maintainable codebase** - Consistent patterns across modules
5. **No naming conflicts** - Specific enum names prevent issues

This approach can be applied to any module by analyzing the `@remote` folder and implementing complete flows for each API file.
