# Phase 04 - Admin Feedback Analytics Dashboard

## Context Links

- `src/modules/courses/src/modules/feedback/in-app-survey`
- `/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/components/setting/in-app-survey`
- `/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/services/inAppSurveyService.ts`

## Overview

- Priority: High
- Status: Complete
- Replace simple feedback list with analytics dashboard matching provided UI: By response, By user, Export data.

## Requirements

- Backend stores response snapshots for easy reporting: user, branch score, branch label, branch index.
- Backend tracks survey start sessions to calculate completion rate.
- By response shows date-range metrics, rating distribution, branch option distribution, and recent Q3 feedback.
- Branch detail shows searchable/paginated feedback with Q2 option filters.
- By user shows searchable/paginated user response cards with branch filters.
- Export returns user id, user snapshot, emoji/rating level, selected Q2 options, Q3 feedback, submitted date.

## Architecture

- Keep canonical data in `in_app_survey_responses`.
- Add `in_app_survey_sessions` for started/completed funnel tracking.
- Use Mongo aggregate with date-range indexes; no summary table until volume requires it.
- Admin service consumes analytics endpoints under `/courses-in-app-survey/statistics`.

## Related Code Files

- Modify `src/modules/courses/src/modules/feedback/in-app-survey/**`
- Modify `/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/in-app-survey.interface.ts`
- Modify `/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/services/inAppSurveyService.ts`
- Modify `/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/components/setting/in-app-survey/**`

## Implementation Steps

1. Add session schema/repository and register in module.
2. Add response snapshot fields and indexes.
3. Add DTOs for analytics range, response list, branch detail, export.
4. Add service/repository aggregate methods.
5. Add controller endpoints for sessions, overview, branch detail, by-user, export.
6. Replace admin feedback tab with dashboard controls and split components.
7. Run backend and admin build checks.

## Todo List

- [x] Backend session tracking.
- [x] Backend analytics endpoints.
- [x] Admin By response dashboard.
- [x] Admin branch detail view.
- [x] Admin By user view.
- [x] Export data.
- [x] Verification.

## Success Criteria

- Admin feedback screen has By response, By user, Export data.
- Metrics support 30 days, 60 days, and custom range.
- Statistics derive from snapshots, not mutable current config.
- Backend compiles.
- Admin production build compiles.

## Risk Assessment

- Historical responses do not have `ratingScore` or user snapshot; service must fallback to branch index and user id.
- Completion rate is exact only for app versions calling session start.
- Large response volume may require future daily summary collection.

## Security Considerations

- Use existing `AuthGuard`.
- Do not expose password/provider data from users.
- Export only survey fields required by admin.
