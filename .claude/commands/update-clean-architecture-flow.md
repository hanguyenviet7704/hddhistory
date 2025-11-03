Description: Update existing Clean Architecture module when data models change

# Update Clean Architecture Flow

## What This Does
Updates an existing Clean Architecture module when API contracts or data models change by:
- **Finding all related files** across Domain, Data, Presentation layers
- **Updating models** with new/changed fields
- **Updating entities** to match models
- **Updating extensions** for model-to-entity conversion
- **Updating repositories** to handle new data structure
- **Regenerating code** and validating changes

**Uses intelligent exploration** to find all files in the architectural flow.

## When to Use
- API contract changes requiring model updates
- Adding/removing fields from existing models
- Changing data types in models
- Need to propagate changes through all architecture layers

**After API changes** - When backend changes require frontend updates.

## Required Context
Provide ONE of:
- Path to model file that needs updating
- Path to any file in the module (will find all related)
- API documentation with changes
- Feature module name

## Command Flow

### 1. Ask Questions
Uses `AskUserQuestion` to gather:
```
1. What changed:
   - New fields added to model
   - Fields removed from model
   - Field types changed
   - Complete restructure

2. Module/feature name: (if not provided in context)
   e.g., "user_profile", "notifications"

3. Update approach:
   - Automatic (try to infer changes)
   - Guided (ask about each change)
```

### 2. Find All Related Files
Spawns **Task agent (Explore)** to find:
```
Task: "Find all files related to [module] feature:
      - Domain: entities in lib/src/[module]/domain/entities/
      - Domain: repository interfaces
      - Data: models in lib/src/[module]/data/models/
      - Data: repository implementations
      - Data: model extensions (toEntity)
      - Presentation: cubits (if state needs updating)
      Return complete file paths for all related files."
```

Example output:
```
Found [module] architecture files:
Domain:
  - lib/src/notifications/domain/entities/notification_entity.dart
  - lib/src/notifications/domain/repositories/i_notification_repository.dart

Data:
  - lib/src/notifications/data/models/notification_model.dart
  - lib/src/notifications/data/repositories/notification_repository.dart

Presentation:
  - lib/src/notifications/presentation/cubits/notification_cubit.dart
```

### 3. Read Current Implementation
Uses `Read` tool to read all related files in parallel.

Analyzes:
- Current model fields and types
- Current entity fields and types
- Extension mapping logic
- Repository method signatures

### 4. Track Update Process
Uses `TodoWrite` to track:
```
☐ Update model with new fields
☐ Update entity to match model
☐ Update model extension (toEntity)
☐ Update repository interface (if signatures change)
☐ Update repository implementation
☐ Update cubit (if state structure changes)
☐ Run code generation
☐ Validate changes
```

### 5. Update Model
Updates data model in `lib/src/[module]/data/models/`:

**Before:**
```dart
@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    @Default('') String id,
    @Default('') String title,
    @Default('') String body,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
}
```

**After (with new fields):**
```dart
@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    @Default('') String id,
    @Default('') String title,
    @Default('') String body,
    @Default('') String imageUrl,        // NEW
    @Default(false) bool isRead,         // NEW
    DateTime? readAt,                    // NEW
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
}
```

### 6. Update Entity
Updates domain entity to match:

```dart
@freezed
class NotificationEntity with _$NotificationEntity {
  const factory NotificationEntity({
    @Default('') String id,
    @Default('') String title,
    @Default('') String body,
    @Default('') String imageUrl,        // NEW
    @Default(false) bool isRead,         // NEW
    DateTime? readAt,                    // NEW
  }) = _NotificationEntity;

  factory NotificationEntity.fromJson(Map<String, dynamic> json) =>
      _$NotificationEntityFromJson(json);
}
```

### 7. Update Model Extension
Updates `toEntity()` conversion:

**Before:**
```dart
extension NotificationModelExtension on NotificationModel {
  NotificationEntity toEntity() => NotificationEntity(
    id: id,
    title: title,
    body: body,
  );
}
```

**After:**
```dart
extension NotificationModelExtension on NotificationModel {
  NotificationEntity toEntity() => NotificationEntity(
    id: id,
    title: title,
    body: body,
    imageUrl: imageUrl,            // NEW
    isRead: isRead,                // NEW
    readAt: readAt,                // NEW
  );
}
```

### 8. Update Repository (If Needed)
If method signatures change:

```dart
abstract interface class INotificationRepository {
  Future<Either<AppException, NotificationEntity>> getNotification(String id);
  Future<Either<AppException, List<NotificationEntity>>> getNotifications();
  // NEW method if needed:
  Future<Either<AppException, void>> markAsRead(String id);
}
```

And implementation:
```dart
@LazySingleton(as: INotificationRepository)
class NotificationRepository implements INotificationRepository {
  // Update implementation to handle new fields
  @override
  Future<Either<AppException, NotificationEntity>> getNotification(String id) async {
    return callGraphQL(
      queryCall: () => graphqlClient.query$GetNotification(...),
      dataExtractor: (data) => data?.notification?.toModel()?.toEntity(),
    );
  }

  // NEW method implementation:
  @override
  Future<Either<AppException, void>> markAsRead(String id) async {
    return callGraphQL(
      queryCall: () => graphqlClient.mutate$MarkAsRead(...),
      dataExtractor: (_) => null,
    );
  }
}
```

### 9. Update Cubit (If Needed)
If state structure changes:

```dart
@freezed
class NotificationState with _$NotificationState {
  const factory NotificationState.initial() = _Initial;
  const factory NotificationState.loading() = _Loading;
  const factory NotificationState.success({
    required List<NotificationEntity> notifications,
    @Default(0) int unreadCount,  // NEW - if tracking unread
  }) = _Success;
  const factory NotificationState.error(AppException error) = _Error;
}
```

### 10. Run Code Generation
```bash
dart run build_runner build --delete-conflicting-outputs
```

Regenerates:
- Freezed files for updated models/entities
- JSON serialization
- DI configuration (if new dependencies)

### 11. Validate Changes
Checks:
- ✅ All files compile
- ✅ Model and entity fields match
- ✅ Extension maps all fields
- ✅ Repository handles new structure
- ✅ No missing @Default annotations
- ✅ flutter analyze passes

## Output Format

```
✅ Clean Architecture Module Updated: [Module Name]

📦 Files Updated

Domain Layer:
✓ [Module]Entity - Added 3 fields
  - imageUrl: String
  - isRead: bool
  - readAt: DateTime?

Data Layer:
✓ [Module]Model - Added 3 fields (matching entity)
✓ [Module]ModelExtension - Updated toEntity() to map new fields
✓ [Module]Repository - [Updated/No changes needed]

Presentation Layer:
✓ [Module]Cubit - [Updated state/No changes needed]

🔧 Code Generation
✓ Freezed files regenerated
✓ JSON serialization updated
✓ All files compile successfully

✅ Validation
✓ Model ↔ Entity fields match
✓ Extension maps all fields correctly
✓ Repository handles new structure
✓ No analyze errors

⚠️ Important Notes
- New fields have @Default annotations where needed
- Nullable fields (DateTime?) don't need @Default
- Repository implementation handles new fields
- [Any breaking changes noted]

🎯 Next Steps
1. Test with updated API endpoints
2. Update tests to cover new fields
3. Update UI to display new data (if applicable)
```

## Example Usage

### Example 1: Add Fields to Existing Module
```
User: /update-clean-architecture-flow
      lib/src/notifications/data/models/notification_model.dart
      "API now returns imageUrl, isRead, and readAt fields"

Claude: Questions:
        1. What changed? → New fields added
        2. Module? → notifications (auto-detected)
        3. Approach? → Automatic

        [Finds all related files]
        [Updates model, entity, extension]
        [Runs code generation]
        [Validates everything]

        ✅ Complete
        - 3 new fields added to model and entity
        - Extension updated
        - All layers in sync
```

### Example 2: Change Field Types
```
User: /update-clean-architecture-flow
      "user_profile"
      "age field changed from int to String in API"

Claude: Questions:
        1. What changed? → Field types changed
        2. Module? → user_profile
        3. Approach? → Guided

        [Shows current field: @Default(0) int age]
        [Confirms new type: @Default('') String age]
        [Updates across all layers]

        ✅ Complete
        - age field type changed int → String
        - ⚠️ Breaking change - may affect UI
```

## Advanced Features

### Smart Field Detection
Automatically detects:
- Which fields are new
- Which fields were removed
- Which fields changed type
- Which fields changed from required to optional

### Default Value Inference
Suggests appropriate defaults:
```
String → @Default('')
int → @Default(0)
bool → @Default(false)
List<T> → @Default([])
Optional (DateTime?) → No @Default needed
```

### Breaking Change Detection
Flags breaking changes:
```
⚠️ Breaking Changes Detected:
1. Field 'email' renamed to 'emailAddress'
   → Update all usages in UI layer

2. Field 'age' type changed: int → String
   → Update display logic and validation

3. Field 'phone' removed
   → Remove from UI, update tests
```

### Consistency Validation
Ensures:
- Model and entity have same fields
- Extension maps all fields
- No orphaned fields
- Proper nullability handling

## Common Issues and Solutions

### Issue: Missing @Default
```
Error: Non-nullable field without @Default
```
**Solution:** Automatically adds:
```dart
@Default('') String newField,  // for String
@Default(0) int newField,       // for int
@Default(false) bool newField,  // for bool
```

### Issue: Complex Nested Objects
```
Model has nested List<OptionModel>
```
**Solution:** Also updates nested models:
```dart
// Updates both:
- NotificationModel with options field
- NotificationOptionModel if it exists
// And their entities + extensions
```

### Issue: Repository Method Signatures
```
New field requires new repository method
```
**Solution:** Prompts:
```
⚠️ New functionality detected
Would you like to add repository method:
  markAsRead(String id)
in INotificationRepository?
```

---

*See CLAUDE.md: Clean Architecture for layer relationships*
*See CLAUDE.md: Data Model Patterns for Freezed usage*
