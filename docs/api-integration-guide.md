# API Integration Guide

**Last Updated:** 2026-06-11
**Related:** `docs/system-architecture.md`, `lib/core/base/`, `lib/src/*/data/datasources/remote/`

## 1. Integration Stack
- HTTP client: Dio
- REST bindings: Retrofit (`@RestApi()` interfaces)
- Error/result style: `TaskEither<AppException, T>`
- Shared request helpers: the restful request handler mixin

## 2. API Layer Placement
All endpoint definitions and API clients must stay in feature data layer:
```text
lib/src/<feature>/data/datasources/remote/*_api.dart
```

Endpoint constants live in:
```text
lib/core/constants/manual/endpoint.dart
```

## 3. Core Response Contracts
### Base response wrappers
- `BaseResponse<T>`
- `BaseResponseList<T>`
- `BasePageBreak<T>`

### BasePageBreak fields
- `totalPages`
- `currentPage`
- `itemsPerPage`
- `items`

Use the base page break extension for `isLastPage` and `nextPage` helpers.

## 4. Pagination Request Contract
`PageBreakRequest<T extends JsonRequestConvertible>` is the standard paginated request type.

### App-side fields
- `page`
- `limit`
- `orderBy`
- `order`
- `search`
- `filter`

### Serialized query keys
- `page`
- `take` (serialized from `limit`)
- `orderBy`
- `order`
- `search`

### Example
```dart
final request = PageBreakRequest<LearningItemFilter>(
  page: 1,
  limit: 10,
  orderBy: 'index',
  order: PageBreakOrder.asc,
  filter: LearningItemFilter(type: LearningItemFilterType.exercise),
);
```

## 5. Existing Retrofit API Patterns
### Paginated read APIs
```dart
@GET(AppEndpoint.skillsets)
Future<BaseResponse<BasePageBreak<SkillsetModel>>> getAllSkillsets(
  @Queries() PageBreakRequest request,
);

@GET(AppEndpoint.courses)
Future<BaseResponse<BasePageBreak<CourseModel>>> getAllCourses(
  @Queries() PageBreakRequest request,
);

@GET(AppEndpoint.coursesLearningItems)
Future<BaseResponse<BasePageBreak<LearningItemModel>>> getAllLearningItems(
  @Queries() PageBreakRequest request,
);
```

### Detail/read APIs
```dart
@GET(AppEndpoint.skillsetsById)
Future<BaseResponse<SkillsetModel>> getSkillset(@Path('id') String id);

@GET(AppEndpoint.coursesById)
Future<BaseResponse<CourseModel>> getCourse(@Path('id') String id);
```

### Update/action APIs
```dart
@PUT(AppEndpoint.usersById)
Future<BaseResponse<UserModel>> updateUser(
  @Path('id') String id,
  @Body() Map<String, dynamic> body,
);

@POST(AppEndpoint.verify)
Future<BaseResponse<IapVerifyModel>> verify(@Body() Map<String, dynamic> params);
```

### Multipart upload
```dart
@MultiPart()
@POST(AppEndpoint.cloudflareUpload)
Future<BaseResponse<UploadModel>> uploadFile(
  @Part(name: 'file') MultipartFile file,
  @Part(name: 'key') String key,
  @Part(name: 'prefix') String prefix,
  @Part(name: 'folder') String folder,
);
```

## 6. DTO and Body Field Examples (Code-Verified)
### 6.1 Progress filter query object
`UserProgressFilter` fields:
- `userId`
- `grade` (`course|lesson|keypoint|exercise`)
- `courseId`, `lessonId`, `keypointId`, `exerciseId`

### 6.2 Update keypoint progress body
`UpdateUserProgressKeypointParams`:
- `userId`, `courseId`, `lessonId`
- `keypoints[]` with `keypointId`, `averageScore`, `passed`, `reviews`

### 6.3 Update exercise progress body
`UpdateUserProgressExerciseParams`:
- `userId`, `courseId`, `lessonId`, `keypointId`
- `exercises[]` with typed answer fields such as:
  - `exerciseId`, `type`, `form`, `passed`, `score`
  - `multipleAnswer`, `singleAnswer`, `dragDropAnswer`, `recordAnswer`

### 6.4 Purchase verify body
`VerifyParams.toJson()` fields:
- `platform`
- `productId`
- `packageName`
- `storeTransactionId`

### 6.5 Output practice conversation and message requests
`OutputPracticeApi` defines these feature-scoped REST endpoints:
- `getOutputPracticeConversation(sectionId)` -> `GET AppEndpoint.coursesOutputPracticeSectionConversations`
- `createOutputPracticeConversation(body)` -> `POST AppEndpoint.coursesOutputPracticeConversations`
- `getAllOutputPracticeMessages(request)` -> `GET AppEndpoint.coursesOutputPracticeMessages`
- `sendOutputPracticeMessage(body)` -> `POST AppEndpoint.coursesOutputPracticeMessagesSend`

Request payloads:
- `OutputPracticeMessagesRequestEntity` query fields: `conversationId`, `page`, `take`, `orderBy`, `order`
- Create conversation body: `sectionId`, `language`
- Send message body: `conversationId`, `type`, and either `message` for free text or `value` for action-chip sends

Runtime behavior:
- Conversation fetch is section-scoped.
- Message history is conversation-scoped and paginated.
- A missing conversation is treated as create-on-demand rather than a hard failure.

### 6.6 Home widget display payload requests
`HomeWidgetApi` defines feature-scoped read endpoints for native widget payload sync:
- `getInProgressWidget()` -> `GET /api/v1/courses-user-progress/widget/in-progress`
- `getSuggestCourseWidget()` -> `GET /api/v1/courses-user-progress/widget/suggest-course`
- `getLearningStreak()` -> `GET /api/v1/courses-user-progress/streak`

Runtime behavior:
- Payloads are display-only data written to native widget shared storage.
- Course cover images are cached best-effort; native widgets use bundled fallback art when image save fails.
- Suggested course is reused for the same local day after a successful sync.
- Logout/account reset clears widget payloads and image/static keys best-effort.

## 7. Repository Integration Pattern
Use repositories to isolate transport details from domain/presentation:
```text
UseCase -> Domain repository interface -> Data repository implementation -> Retrofit API
```

For transform-heavy calls, prefer:
- `callApiWithTransform`
- `callApiListWithTransform`
- `callApiPageBreak`
- `executeApiAction`

## 8. Cubit/Bloc Integration Pattern
Use mixins for consistent loading/failure behavior:
- `runUseCase`
- `runUseCaseList`
- `runUseCaseVoid`
- `runUseCasePageBreak`

This keeps endpoint/repository details out of UI state handling.

## 9. Auth and Session Flow (REST)
### 9.1 Request header injection
- `AppInterceptor.onRequest` injects:
  - `Authorization: Bearer <accessToken>` when missing and `AppGlobalValue.accessToken` is available.
  - `lang: <current locale code>`.

### 9.2 401 handling and retry flow
1. `AppInterceptor.onError` only enters unauthorized flow for HTTP `401`.
2. It reads `requestOptions.extra['retry_count']` and allows **one** refresh retry (`_maxRetryAttempts = 1`).
3. If no refresh token exists, it does not retry and directly triggers unauthorized handling.
4. It calls `AuthBloc.refreshAccessToken()`, which uses a shared completer to avoid duplicate parallel refresh calls.
5. Refresh request payload uses:
   - `userId`
   - `refreshToken`
   - `device.deviceId`
   - `device.deviceName`
6. On refresh success, interceptor updates the authorization header and retries the original request.
7. On refresh failure (or retry failure), unauthorized handling runs:
   - reset DI/runtime session state
   - clear user data
   - dispatch `AuthEvent.clearSession()`
   - navigate to register/login flow
   - show session-expired message

### 9.3 Error mapping and retry behavior
- `RestfulRequestHandlerMixin` intentionally suppresses duplicate user messages for `401` errors.
- For non-401 Dio errors, it surfaces user-facing message and maps to `AppException.fromDioException`.
- `BaseInterceptor` handles transient timeout retries (`connectionTimeout`, `receiveTimeout`) up to `maxRetries` (default `3`).

## 10. Deep Link and Platform Integration Notes
- Deep link assets are maintained under `.info/deeplink/`.
- Keep URL path contracts synchronized between route data and backend/deeplink metadata.

## 11. Contract Safety Checklist
Before updating docs/examples:
1. Verify endpoint path in the endpoint constants mixin.
2. Verify API method signature in `*_api.dart`.
3. Verify request DTO fields in `domain/usecases` or request models.
4. Verify pagination fields use `page` + `limit` app-side and `take` serialized.

## 12. Anti-Drift Rules
- Do not document endpoints that are not present in `AppEndpoint` + API clients.
- Do not show `executeUseCase*` names; current mixins are `runUseCase*`.
- Do not document `offset/per_page/pageSize` pagination for this codebase.
