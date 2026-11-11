# Phase 01 - Data Contract And Admin Flag

## Context Links

- API question schema: `src/modules/courses/src/modules/learning-item/schema/learning-item.schema.ts`
- API question interfaces: `src/modules/courses/src/modules/learning-item/interface/excercises/*.interface.ts`
- API question DTOs: `src/modules/courses/src/modules/learning-item/dto/excercises/*.dto.ts`
- API import builder: `src/modules/courses/src/modules/import/exercise-import.util.ts`
- Admin exercise form: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/exercises/ExerciseForm.tsx`
- Admin learning item types: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/learning-item/learning-item.interface.ts`

## Overview

- Priority: High
- Status: Pending
- Goal: Store a boolean Daily Warm-up flag per exercise question and expose it in the admin Exercise create/edit flow.

## Key Insights

- `learning_item.questions` is stored as `SchemaTypes.Array`, so no migration is required for old rows.
- Old questions missing the field should behave as `false`.
- The admin form already preserves unknown fields via object spread in `convertQuestionsToPayload`; explicit types/UI still need updating.

## Requirements

- Add `isDailyWarmUp?: boolean` to every exercise question interface and DTO in API.
- Add Swagger metadata and `@IsOptional() @IsBoolean()` validation.
- Add `isDailyWarmUp: false` in admin `createEmptyQuestion` defaults for all question types.
- Add a checkbox in `QuestionForm` labeled `Daily Warm-up`.
- Show a small badge in question list when a question is flagged.
- Preserve the field in save/update payload.
- Optional Excel import support: read a `daily_warm_up` or `is_daily_warm_up` column when present.

## Architecture

- Keep the flag inside each question object:

```ts
{
  exerciseId: string;
  type: ExerciseType;
  isDailyWarmUp?: boolean;
}
```

- Do not add a top-level `learning_item` flag; selection is question-level.

## Related Code Files

- Modify: `src/modules/courses/src/modules/learning-item/interface/excercises/single-choice.interface.ts`
- Modify: `src/modules/courses/src/modules/learning-item/interface/excercises/multiple-choice.interface.ts`
- Modify: `src/modules/courses/src/modules/learning-item/interface/excercises/single-choice-no-correct-answer.interface.ts`
- Modify: `src/modules/courses/src/modules/learning-item/interface/excercises/drag-drop.interface.ts`
- Modify: `src/modules/courses/src/modules/learning-item/interface/excercises/record.interface.ts`
- Modify: `src/modules/courses/src/modules/learning-item/dto/excercises/*.dto.ts`
- Modify: `src/modules/courses/src/modules/import/exercise-import.util.ts`
- Modify: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/learning-item/excercises/*.interface.ts`
- Modify: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/exercises/ExerciseForm.tsx`

## Implementation Steps

1. Add `isDailyWarmUp?: boolean` to API interfaces for all exercise question types.
2. Add DTO validation and Swagger docs to all exercise question DTO classes.
3. In Excel import builder, parse optional boolean from `daily_warm_up` / `is_daily_warm_up`, defaulting to existing value or `false`.
4. Add admin type fields in every exercise question interface and payload interface.
5. Add checkbox to `QuestionForm` common fields.
6. Add default `isDailyWarmUp: false` in each `createEmptyQuestion` branch.
7. Add visual badge in `renderQuestionsSection` for flagged questions.

## Todo List

- [ ] API interfaces updated
- [ ] API DTOs updated
- [ ] Import parser supports optional flag
- [ ] Admin TS interfaces updated
- [ ] Admin modal checkbox added
- [ ] Admin question list badge added

## Success Criteria

- Existing questions without flag continue to save correctly.
- Admin can create/update a question with Daily Warm-up checked.
- API payloads preserve `isDailyWarmUp`.
- `npm run build` passes in both API and admin repos.

## Risk Assessment

- Admin `ExerciseForm.tsx` is very large; keep changes minimal and avoid unrelated refactor.
- If Excel template must expose the column, update template separately only after confirmation.

## Security Considerations

- No new sensitive data.
- Keep auth behavior unchanged.

## Next Steps

- Implement backend API once the data field is in place.

