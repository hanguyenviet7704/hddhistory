# Phase 01 - Backend Job Persistence And API

## Context Links

- Backend root: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api`
- Existing file module: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/src/modules/file/file.module.ts`
- Existing Cloudflare controller: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/src/modules/file/cloudflare/cloudflare.controller.ts`
- Existing repository pattern: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/src/modules/courses/src/modules/skillset/repository/skillset.repository.ts`
- Existing Mongoose schema pattern: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/src/modules/user/src/modules/auth/schema/user.schema.ts`

## Overview

Priority: High
Status: Completed

Add persistent `drive_import_jobs` collection and API endpoints needed by CMS.

## Key Insights

- This is not multipart browser upload. FE sends only Drive URL.
- `folderUrl` is persisted; parsed folder id is runtime only.
- Keep schema simple. No per-folder progress object.
- Use current authenticated user from request context.

## Requirements

- Store one active job per user.
- Active statuses: `queued`, `processing`.
- Create API returns active job if one already exists.
- List API returns jobs owned by current user.
- Detail API rejects access to other users' jobs.
- Cancel API marks job cancelled; worker checks before next file.

## Architecture

```text
DriveImportController
-> DriveImportService
-> DriveImportJobRepository
-> MongoDB drive_import_jobs
```

## Related Code Files

Create:

- `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/src/modules/file/cloudflare/drive-import/drive-import.controller.ts`
- `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/src/modules/file/cloudflare/drive-import/drive-import.service.ts`
- `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/src/modules/file/cloudflare/drive-import/repository/drive-import-job.repository.ts`
- `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/src/modules/file/cloudflare/drive-import/schema/drive-import-job.schema.ts`
- `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/src/modules/file/cloudflare/drive-import/dto/create-drive-import.dto.ts`
- `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/src/modules/file/cloudflare/drive-import/enum/drive-import-job-status.enum.ts`
- `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/src/modules/file/cloudflare/drive-import/interface/drive-import-job.interface.ts`

Modify:

- `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/src/modules/file/file.module.ts`

## Data Model

Collection name: `drive_import_jobs`

```ts
{
  createdBy: string;
  folderUrl: string;
  status: 'queued' | 'processing' | 'completed' | 'completed_with_errors' | 'failed' | 'cancelled';
  totalFiles: number;
  uploadedFiles: number;
  failedCount: number;
  percent: number;
  uploadedItems: Array<{
    path: string;
    url: string;
    uploadedAt: Date;
  }>;
  failedFiles: Array<{
    path: string;
    message: string;
    failedAt: Date;
  }>;
  startedAt?: Date;
  completedAt?: Date;
  cancelledAt?: Date;
  lastError?: string;
  createdAt: Date;
  updatedAt: Date;
}
```

## API Contract

```http
POST /api/v1/cloudflares/drive-imports
GET /api/v1/cloudflares/drive-imports
GET /api/v1/cloudflares/drive-imports/:jobId
POST /api/v1/cloudflares/drive-imports/:jobId/cancel
```

## Implementation Steps

1. Add enum and interfaces.
2. Add schema with defaults:
   - `status = queued`
   - counts default `0`
   - arrays default `[]`
3. Add index on `{ createdBy: 1, status: 1 }`.
4. Add repository methods:
   - `findActiveByUser(createdBy)`
   - `findByUser(createdBy, limit)`
   - `findOwnedJob(jobId, createdBy)`
   - `markCancelled(jobId, createdBy)`
5. Add controller endpoints.
6. Add service create/list/detail/cancel logic.
7. Wire schema, repository, service, controller in `FileModule`.

## Todo List

- [x] Create schema and interface
- [x] Create repository
- [x] Create DTO and enum
- [x] Create service API methods
- [x] Create controller
- [x] Register providers and Mongoose feature

## Success Criteria

- User can create a job with `folderUrl`.
- Second create while active returns the same active job.
- User can list own jobs.
- User can fetch only own job detail.
- User can cancel own queued/processing job.

## Risk Assessment

- Race condition can create two active jobs for same user.
  Mitigation: repository check before create; optional partial unique index later.
- In-process worker may continue after cancel until current file finishes.
  Mitigation: document cancel semantics.

## Security Considerations

- Every list/detail/cancel query must filter by `createdBy`.
- Do not expose job data across users.
- Validate `folderUrl` as URL and expected Drive folder URL format.

## Next Steps

Proceed to Drive processing once job persistence exists.
