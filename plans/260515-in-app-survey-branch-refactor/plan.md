# In-App Survey Branch Refactor Plan

## Status

- Phase 01: Backend singleton branch survey - Complete
- Phase 02: Admin config editor - Complete
- Phase 03: Admin user history display - Complete
- Phase 04: Admin feedback analytics dashboard - Complete

## Scope

Refactor in-app survey from multiple emoji configs to one singleton survey config with intro question and ordered branches.

## Decisions

- Keep collection names: `in_app_survey_configs`, `in_app_survey_responses`.
- Store one config document with `configKey: "default"`.
- No status, no config id in app submit payload.
- Branch has emoji, closed question with options, and open question.
- Responses store snapshots of intro question, selected branch, selected options, and feedback.

## Backend API

- `GET /courses-in-app-survey/config`
- `PUT /courses-in-app-survey/config`
- `POST /courses-in-app-survey/responses`
- `GET /courses-in-app-survey/responses/me`
- `GET /courses-in-app-survey/responses/users/:userId`

## Admin UI

- Settings → In-App Survey becomes a singleton config editor.
- Main action is `Save Survey Config`.
- BTV manages intro question and branch list.
- Branch options support drag reorder and option icon uploads.

## Verification

- Backend TypeScript compile and lint.
- Admin production build.
