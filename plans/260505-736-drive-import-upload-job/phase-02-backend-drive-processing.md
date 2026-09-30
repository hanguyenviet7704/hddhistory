# Phase 02 - Backend Drive Processing

## Context Links

- R2 upload service: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/src/modules/file/cloudflare/cloudflare.service.ts`
- R2 low-level service: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/src/modules/file/cloudflare/config/r2.config.ts`
- Package contains `googleapis`: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/package.json`

## Overview

Priority: High
Status: Completed

Implement background Drive import processing. Backend parses Drive folder URL at runtime, reads optional `images`, `videos`, `audios` child folders, uploads direct files to R2, and updates job progress.

## Key Insights

- User enters Drive folder URL; backend uses folder id internally for Google Drive API.
- Do not persist root folder id.
- Only direct files inside child folders are supported.
- Missing child folders are not errors.
- Preserve child folder path in result path, e.g. `images/a.png`.

## Requirements

- Parse Drive folder id from common folder URL formats.
- Find direct child folders named `images`, `videos`, `audios`.
- Skip missing child folders.
- Count total files before upload when possible.
- Upload sequentially first for stability.
- Update job after each file.
- Mark final status:
  - `completed` if no failures
  - `completed_with_errors` if one or more file failures
  - `failed` for unrecoverable job-level error before processing
  - `cancelled` if cancel requested

## Architecture

```text
create job
-> setImmediate/process.nextTick start worker
-> parse folder id
-> Google Drive API list children
-> Google Drive API download file stream
-> R2 upload stream
-> update drive_import_jobs
```

## Related Code Files

Modify:

- `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/src/modules/file/cloudflare/drive-import/drive-import.service.ts`
- `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/src/modules/file/cloudflare/drive-import/repository/drive-import-job.repository.ts`
- `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/src/modules/file/cloudflare/cloudflare.service.ts`

Maybe create:

- `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/src/modules/file/cloudflare/drive-import/service/google-drive.service.ts`
- `/Users/nguyenvietha/Source/HDDhistory/hddhistory-api/src/modules/file/cloudflare/drive-import/utils/drive-folder-url.util.ts`

Modify environment template with required Google Drive variables, if needed.

## Implementation Steps

1. Add Drive URL parser.
2. Add Google Drive client setup using project-approved auth method.
3. Add method to list child folders for root folder.
4. Add method to list direct files in a folder.
5. Add method to download file as stream.
6. Add R2 upload helper that accepts Drive stream, filename, mimetype, and target path.
7. In worker:
   - mark job `processing`
   - set `startedAt`
   - collect files from present folders
   - update `totalFiles`
   - loop files sequentially
   - before each file, reload job and stop if cancelled
   - upload file
   - push `uploadedItems`
   - on file failure, push `failedFiles`
   - recalculate counts and percent
8. Add job-level error handling.

## Todo List

- [x] Implement folder URL parser
- [x] Implement Google Drive list/download helpers
- [x] Implement R2 stream upload reuse
- [x] Implement worker loop
- [x] Update progress after each file
- [x] Implement cancel check between files

## Success Criteria

- Public Drive folder with only `images` imports image files.
- Folder missing `videos` or `audios` does not fail job.
- Failed individual files are recorded with path and message.
- Uploaded files are recorded with path and URL.
- Cancel stops further file processing.

## Risk Assessment

- Google Drive API auth for public folders may need API key or service account config.
  Mitigation: implement via `googleapis`; document required env vars.
- Public Drive files can still be blocked by quota/rate limits.
  Mitigation: record file-level failure and continue.
- Large files can take time.
  Mitigation: sequential upload and persistent status.

## Security Considerations

- Only allow Google Drive folder URLs.
- Avoid logging sensitive URLs beyond job-level admin context.
- Sanitize file names before R2 key construction.
- Do not overwrite arbitrary keys unless intended.

## Next Steps

After backend job processing works, implement admin CMS page and polling.
