# Phase 01 - Implement Backend API

## Context Links

- `src/modules/courses/src/modules/feedback/user-feedback`
- `src/modules/courses/src/modules/courses.module.ts`
- `src/base/database/mongodb/abstract.repository.ts`
- `src/base/service/request.service.ts`

## Overview

- Priority: High
- Status: Complete
- Implement MongoDB schemas, DTOs, repositories, service, controller, and module for in-app survey.

## Requirements

- BTV can create, read, update, delete survey configs.
- App can read ordered configs.
- User can submit survey responses multiple times.
- User can read own response history.
- BTV can read response history for one user.

## Architecture

- Controller handles routes and DTO binding.
- Service validates config existence and selected option ids.
- Repository owns MongoDB reads/writes.
- Schema stores config and response snapshots.

## Related Code Files

- Create `src/modules/courses/src/modules/feedback/in-app-survey/**`
- Modify `src/modules/courses/src/modules/courses.module.ts`

## Implementation Steps

1. Add interfaces and domain types.
2. Add schemas for config and response collections.
3. Add DTOs with Swagger metadata and validation.
4. Add repositories.
5. Add service business logic and validation.
6. Add controller routes under `courses-in-app-survey`.
7. Register module in `CoursesModule`.
8. Run verification.

## Todo List

- [x] Create schema/interface/dto files.
- [x] Create repositories.
- [x] Create service/controller/module.
- [x] Register module.
- [x] Verify compile.

## Success Criteria

- TypeScript compile check completes.
- Existing feedback module remains compatible.
- Response submit stores config snapshots and rejects invalid option ids.

## Risk Assessment

- Route ordering must keep `/responses/me` before `/responses/users/:userId`.
- Mongo ObjectId validation needed before DB calls.

## Security Considerations

- Use `AuthGuard`.
- Derive `/responses/me` user id from request user.
- Do not trust client-sent option objects or question.
