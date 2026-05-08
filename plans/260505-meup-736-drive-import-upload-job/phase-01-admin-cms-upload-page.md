# Phase 01 - Admin CMS Upload Page

## Context Links

- Admin CMS root: `/Users/macbook/Documents/eUp Group/admin-ai-tutor`
- Routes: `/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/routes/index.tsx`
- Header: `/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/components/layout/Header.tsx`
- Axios client: `/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/services/axiosClient.ts`

## Overview

Priority: High
Status: Completed

Add `Import File From Drive` page. Header opens page in new tab. Page creates/resumes jobs and shows progress using backend polling.

## Requirements

- Header button opens `/drive-upload` in a new tab.
- Page title: `Import File From Drive`.
- On page load, fetch user's jobs and resume active job if exists.
- User can submit Drive folder URL.
- Submit receives existing active job or new job.
- Poll job detail every 5s while `queued` or `processing`.
- Reduce polling when browser tab is hidden.
- Show total progress, uploaded count, failed count, uploaded items, failed files.
- Show Cancel button for active job.

## Related Code Files

Create:

- `/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/pages/drive-upload/DriveUploadPage.tsx`
- `/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/services/driveImportService.ts`
- `/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/types/interface/files/drive-import.interface.ts`

Modify:

- `/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/routes/index.tsx`
- `/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/components/layout/Header.tsx`

## Implementation Steps

1. Add TypeScript interfaces:
   - `DriveImportJobStatus`
   - `DriveImportUploadedItem`
   - `DriveImportFailedFile`
   - `DriveImportJob`
2. Add service methods:
   - `create(folderUrl)`
   - `list()`
   - `getById(jobId)`
   - `cancel(jobId)`
3. Add route `/drive-upload`.
4. Add Header action:
   - button text `Import File From Drive`
   - `window.open('/drive-upload', '_blank')`
5. Build page:
   - form with URL input
   - start button
   - active job summary
   - progress bar
   - uploaded items section
   - failed files section
   - cancel button
6. Polling behavior:
   - fetch immediately after job starts/resumes
   - poll every 5s while page visible
   - poll every 30s or pause when hidden
   - fetch immediately on visibility return
   - stop on terminal status

## Todo List

- [x] Create types
- [x] Create service
- [x] Create page
- [x] Add route
- [x] Add Header button
- [x] Implement polling
- [x] Add cancel action

## Success Criteria

- Admin opens import page from Header in new tab.
- Existing active job resumes automatically.
- New Drive link starts a job.
- Progress updates without page refresh.
- Terminal job stops polling.
- Cancel updates UI after backend confirms.

## Risk Assessment

- Polling too frequent can add load.
  Mitigation: 5s visible, 30s hidden or pause.
- Long uploaded item lists can clutter UI.
  Mitigation: use collapsible or capped list if needed.

## Security Considerations

- Use existing authenticated axios client.
- Do not expose tokens or backend env in UI.

## Next Steps

Validate CMS build after implementation.
