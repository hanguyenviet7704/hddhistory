# System Architecture

**Last Updated:** Feb 10, 2026
**Architecture Pattern:** Clean Architecture + BLoC State Management + Factory Patterns
**Platforms:** iOS (12+) | Android (API 21+)
**Current Focus:** feature/MEUP-637 - Lesson refactoring with strongly-typed payloads

---

## 1. High-Level Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                       │
│  Pages (UI screens) → Widgets (UI components) → Cubits      │
│  ↑ State Management (BLoC/Cubit)                            │
│  ↓ Emits states, listens to domain layer                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                     DOMAIN LAYER                            │
│  Entities (data models) → Use Cases → Repository Interface  │
│  ↑ Platform-agnostic, business logic                        │
│  ↓ Returns TaskEither<Exception, T> (functional)            │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                      DATA LAYER                             │
│  Models (JSON) → Repository Implementation → Data Sources   │
│  ↑ REST API (Retrofit/Dio) | Local Storage | GraphQL        │
│  ↓ Implements domain repository interface                   │
└─────────────────────────────────────────────────────────────┘

CROSS-LAYER SERVICES:
┌────────────────────────────────────────────────────────────┐
│  DI Container (GetIt) → Service Locator Pattern            │
│  Config (theme, locale, settings) → App-wide state        │
│  Error Handling (AppException) → Centralized exceptions   │
│  Tracking (Analytics, Sentry) → Observability             │
│  Remote Config (Firebase) → Feature toggles & versions    │
│  Deep Linking (app_links) → Universal link navigation     │
└────────────────────────────────────────────────────────────┘
```

---

## 2. Layer Details & Responsibilities

### 2.1 Presentation Layer
**Files:** `lib/src/{feature}/presentation/` + `lib/core/utils/`

**Components:**
- **Pages:** Full-screen widgets (e.g., LoginPage, CoursePage)
- **Widgets:** Reusable UI components (buttons, cards, dialogs)
- **Cubits/BLoCs:** State machines managing UI state
- **Mixins:** CubitUseCaseHandlerMixin (boilerplate reduction)

**Key Patterns:**
- Immutable state classes via `@freezed`
- Status pattern (loading → success/failure)
- Unidirectional data flow: User Action → Cubit → State Emission

**Restrictions:**
- No direct REST/GraphQL calls (use repositories)
- No database queries (use repositories)
- No Business logic (only UI logic)

### 2.2 Domain Layer
**Files:** `lib/src/{feature}/domain/`

**Components:**
- **Entities:** Immutable domain models (e.g., CourseEntity)
- **Repository Interfaces:** Abstract contracts for data access
- **Use Cases:** Business logic orchestration (e.g., GetCoursesUseCase)
- **Value Objects:** Primitives wrapped in classes for type safety

**Key Patterns:**
- No external dependencies (no Flutter, no Dio)
- TaskEither<AppException, T> for functional error handling
- Single Responsibility: One use case = one business operation

**Restrictions:**
- No imports from presentation or data layer
- No platform-specific code
- No external service calls (delegated to repositories)

### 2.3 Data Layer
**Files:** `lib/src/{feature}/data/`

**Components:**
- **Models:** JSON-serializable domain model copies
- **Remote Data Sources:** REST/GraphQL API clients
- **Local Data Sources:** Cache, SharedPreferences, databases
- **Repository Implementations:** Implement domain interfaces, delegate to data sources

**Key Patterns:**
- Models extend domain entities (freezed + json_serializable)
- Repository pattern: Interface (domain) → Implementation (data)
- Data source abstraction (swap implementations for testing)

**Responsibilities:**
- Network requests (Retrofit/Dio)
- Local persistence (HydratedBloc, SharedPreferences)
- Data transformation (API response → domain entity)
- Error mapping (HTTP error → AppException)

---

## 3. Data Flow: User Action → UI Update

### Example: Loading Courses

```
1. USER ACTION (UI Interaction)
   └─ User taps "Load Courses" button

2. CUBIT METHOD CALL
   └─ CourseCubit.loadCourses()
   └─ Calls runUseCase() mixin method

3. EMIT LOADING STATE
   └─ emit(CourseState.loading())

4. USE CASE EXECUTION
   └─ GetCoursesUseCase(PageBreakRequest(page: 1, limit: 20))
   └─ Returns TaskEither<AppException, List<CourseEntity>>

5. REPOSITORY CALL
   └─ CourseRepository.getCourses(pageBreakRequest)
   └─ Returns TaskEither

6. DATA SOURCE REQUEST
   └─ CourseRemoteDataSource.getCourses()
   └─ Retrofit API: GET /courses?page=1&limit=20

7. API RESPONSE
   ├─ Success: JSON → Model → Entity mapping
   └─ Failure: HTTP error → AppException mapping

8. CUBIT STATE EMISSION
   ├─ Success: emit(CourseState.success(courses: courses))
   └─ Failure: emit(CourseState.failure(errorMessage: 'Failed to load'))

9. UI REBUILD
   └─ BlocBuilder listens to state change
   └─ Rebuilds CourseList widget with new data

10. USER SEES
    ├─ Success: Course list displayed
    └─ Failure: Error message + retry button
```

### Code Implementation

```dart
// 1. Cubit method
void loadCourses() {
  runUseCase<List<CourseEntity>>(
    useCase: () => _getCoursesUseCase(const PageBreakRequest(page: 1, limit: 20)),
    onSuccess: (courses) => emit(CourseState.success(courses: courses)),
  );
}

// 2. Use case
class GetCoursesUseCase implements BaseUseCase<PageBreakRequest, List<CourseEntity>> {
  @override
  TaskEither<AppException, List<CourseEntity>> call(PageBreakRequest params) {
    return _repository.getCourses(params);
  }
}

// 3. Repository implementation
@override
TaskEither<AppException, List<CourseEntity>> getCourses(PageBreakRequest request) {
  return TaskEither.tryCatch(
    () async {
      final models = await _remoteDataSource.getCourses(request);
      return models.map((m) => m.toEntity()).toList();
    },
    (error, stackTrace) => AppException.server(statusCode: '500'),
  );
}

// 4. Remote data source (Retrofit)
@GET('/courses')
Future<List<CourseModel>> getCourses(
  @Query('page') int page,
  @Query('limit') int limit,
);

// 5. UI listening
BlocBuilder<CourseCubit, CourseState>(
  builder: (context, state) {
    return state.when(
      initial: () => SizedBox.shrink(),
      loading: () => LoadingIndicator(),
      success: (courses) => CourseList(courses),
      failure: (error) => ErrorWidget(error: error),
    );
  },
)
```

---

## 4. State Management Architecture

### Cubit Structure & Lifecycle

```
1. INITIALIZATION
   ├─ CourseCubit(GetCoursesUseCase) initialized
   ├─ Initial state: CourseState.initial()
   └─ Registered in GetIt dependency container

2. LISTEN FOR UI EVENTS
   ├─ Widget calls cubit.loadCourses()
   ├─ Cubit calls use case
   └─ runUseCase() mixin handles loading state

3. STATE EMISSION
   ├─ emit(CourseState.loading())
   ├─ UI rebuilds (shows spinner)
   ├─ Use case completes
   ├─ emit(CourseState.success(courses: data))
   └─ UI rebuilds (shows data)

4. PERSISTENCE (HydratedCubit)
   ├─ State automatically saved to local storage
   ├─ On app restart, loads from cache
   └─ Network call validates/refreshes data

5. CLEANUP
   ├─ Page dismissed
   ├─ Cubit listeners disposed
   └─ Memory released
```

### HydratedCubit Pattern (Persistent State)

```dart
class ThemeCubit extends HydratedCubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.light);

  void toggleTheme() => emit(
    state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
  );

  @override
  ThemeMode? fromJson(Map<String, dynamic> json) {
    return ThemeMode.values[json['index'] as int? ?? 0];
  }

  @override
  Map<String, dynamic>? toJson(ThemeMode state) {
    return {'index': state.index};
  }
}
```

**Flow:**
```
1. User changes theme → toggleTheme()
2. emit(new theme state)
3. HydratedCubit intercepts emit()
4. Saves state to local storage (toJson)
5. UI rebuilds with new theme
6. App restart → fromJson() loads cached state
```

### Mixin: CubitUseCaseHandlerMixin

**Purpose:** Reduce boilerplate for use case execution

```dart
mixin CubitUseCaseHandlerMixin<State> on Cubit<State> {
  void runUseCase<T>({
    required TaskEither<AppException, T> Function() useCase,
    required void Function(T) onSuccess,
    void Function(String)? onError,
  }) async {
    emit(state.copyWith(status: Status.loading) as State);

    final result = await useCase().run();

    result.fold(
      (error) {
        emit(state.copyWith(
          status: Status.failure,
          errorMessage: error.displayMessage,
        ) as State);
        onError?.call(error.displayMessage);
      },
      (data) {
        onSuccess(data);
      },
    );
  }
}
```

---

## 5. Error Handling Strategy

### AppException Sealed Class Hierarchy

```dart
sealed class AppException {
  // Generic errors (5xx, network, database)
  factory AppException.generic({String? message}) = _Generic;
  factory AppException.server({String? statusCode}) = _Server;
  factory AppException.connection() = _Connection;
  factory AppException.database() = _Database;
  factory AppException.cache() = _Cache;

  // Client errors (4xx)
  factory AppException.notFound() = _NotFound;
  factory AppException.unauthorized() = _Unauthorized;
  factory AppException.forbidden() = _Forbidden;
  factory AppException.invalidInput({String? field}) = _InvalidInput;

  // Pending/Async
  factory AppException.pending() = _Pending;

  // Conversion from external exceptions
  factory AppException.fromDioException(DioException e) { ... }
  factory AppException.fromGraphQLError(OperationException e) { ... }
}
```

### Error Handling in Repository

```dart
TaskEither<AppException, CourseEntity> getCourse(String id) {
  return TaskEither.tryCatch(
    () async {
      final model = await _remoteDataSource.getCourse(id);
      return model.toEntity();
    },
    (error, stackTrace) {
      // Map Dio/network errors to AppException
      if (error is DioException) {
        return AppException.fromDioException(error);
      }
      return AppException.generic(message: error.toString());
    },
  );
}
```

### User-Facing Error Display

```dart
extension on AppException {
  String get displayMessage {
    return switch (this) {
      _NotFound() => 'Resource not found. Please try again.',
      _Unauthorized() => 'Session expired. Please log in again.',
      _Connection() => 'No internet connection. Check your network.',
      _Server(:final statusCode) => 'Server error ($statusCode). Try later.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}
```

### Error Reporting

```dart
// Automatically sent to Sentry
void runUseCase<T>({...}) async {
  result.fold(
    (error) {
      // Log to Sentry with context
      getIt<TrackingService>().logException(
        error,
        extra: {'cubit': runtimeType.toString()},
      );
    },
    (data) { /* ... */ },
  );
}
```

---

## 6. Lesson Page Architecture (MEUP-637)

### Type-Safe Question Payload System

**Problem:** 8+ question types with different data structures required manual type checking, runtime errors, and boilerplate.

**Solution:** Union types (freezed) + factory pattern for type-safe routing

```
QuestionPayloadEntity (Union Type)
├── singleChoice(options, correctId)
├── singleChoiceNoCorrectAnswer(options, documentUrl) [NEW]
├── multipleChoice(options, correctIds)
├── dragAndDrop(sentences, words)
├── arrangeTheSequence(items, correctOrder)
├── cuesPlacement(cues, positions)
├── stressPlacement(words, stressMarks)
└── speaking(instruction, maxDuration)
```

### Factory Pattern for Body Routing

**LessonBodyFactory** - Single responsibility: map payload types to UI bodies

```dart
class LessonBodyFactory {
  static Widget createBody({
    required QuestionPayloadEntity payload,
    required QuestionEntity question,
    required void Function(AnswerSubmission) onAnswerSubmitted,
  }) {
    return payload.when(
      singleChoice: (options, correctId) => ChoiceQuestionBody(...),
      singleChoiceNoCorrectAnswer: (options, docUrl) => NoCorrectAnswerChoiceBody(...),
      speaking: (instruction, duration) => SpeakingQuestionBody(...),
      // exhaustive matching ensures all types handled
    );
  }
}
```

**Usage in ExerciseCubit:**
```dart
void loadQuestion(QuestionEntity question) {
  final body = LessonBodyFactory.createBody(
    payload: question.payload,
    question: question,
    onAnswerSubmitted: _onAnswerSubmitted,
  );
  emit(ExerciseState.loaded(questionBody: body));
}
```

### Page Structure

```
LessonPage
├── LessonCubit (overall lesson state)
├── Top Section: Theory/Document Display
│   └── DocumentWidget (displays lesson content)
├── Middle Section: Exercise
│   ├── ExerciseCubit (exercise-specific state)
│   └── LessonBodyFactory.createBody() → Exercise widget
├── Bottom Section: Review/Timeline
│   └── LessonTimelineBuilder (moved to common) → ReviewTimeline
└── Floating CTA: Submit Answer
    └── ChoiceSubmissionCubit → Result validation
```

### New Routes (MEUP-637)

```
/course/{courseId}/lesson/{lessonId}/
├── /exercise/{exerciseId}
├── /noCorrectAnswerDocument/:groupId  [NEW]
└── /review
```

**NoCorrectAnswerDocumentPage:** Special page for questions without correct answers
- Displays document/reference material
- No submission required
- Routes back to lesson after review

### Payload Mapping & Helpers

**Extracted from Exercise Cubits:**
- **ChoiceCorrectnessRules** - Validates answer correctness
- **ChoiceScoringRules** - Calculates score
- **ChoiceProgressMapper** - Maps to progress entity
- **ProgressPayloadMapper** - Normalizes progress payload

**Benefits:** Reduces duplication across exercise types, easier testing

### Tracking & Analytics

**LessonTrackingDelegate** - Centralized lesson event tracking
- Question view, answer submission, result feedback
- Integration with tracking service
- Automatic parameter enrichment (course, lesson, question type)

---

## Related Documentation

- **[API Integration Guide](./api-integration-guide.md)**: REST/GraphQL patterns, authentication, DI, analytics
- **[Code Standards](./code-standards.md)**: Naming conventions, patterns, quality gates
- **[Deployment Guide](./deployment-guide.md)**: Build commands, CI/CD, release process

---

**Document Maintained By:** Architecture Team
**Last Review:** Feb 10, 2026
**Next Review:** Mar 22, 2026
