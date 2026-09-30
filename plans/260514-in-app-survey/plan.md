# In-App Survey Implementation Plan

## Status

- Phase 01: Implement backend API - Complete

## Scope

Implement `src/modules/courses/src/modules/feedback/in-app-survey` for global in-app survey.

## Decisions

- One config document per emoji in `in_app_survey_configs`.
- One response document per user submission in `in_app_survey_responses`.
- Survey is global app-level; no course, lesson, screen, or feature context.
- Config has `index`, no `status`.
- `selectedOptionIds` requires at least one item.
- Responses store snapshots of emoji, selected options, and question.
- Frontend submits `configId`, `selectedOptionIds`, and optional `feedback`.

## APIs

- `POST /courses-in-app-survey/configs`
- `GET /courses-in-app-survey/configs`
- `GET /courses-in-app-survey/configs/:id`
- `PUT /courses-in-app-survey/configs/:id`
- `DELETE /courses-in-app-survey/configs/:id`
- `POST /courses-in-app-survey/responses`
- `GET /courses-in-app-survey/responses/me`
- `GET /courses-in-app-survey/responses/users/:userId`

## Dependencies

- Mongoose
- Existing `AuthGuard`
- Existing `RequestService`
- Existing `ITranslation`

## Verification

- Run TypeScript compile check.
- Run lint check if compile check passes.
