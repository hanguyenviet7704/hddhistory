# Daily Warm-up Question Auto-Tagging (Admin Tool)

## Status

- Not started

## Scope

Give admins a way to bulk-apply a deterministic rule for the `isDailyWarmUp`
flag on exercise questions, from the hddhistory-admin UI — no direct DB scripts.
Existing content has inconsistent/missing tagging; this needs to be
re-runnable going forward too (new lessons/exercises keep getting added).
Touches `hddhistory-api` (`learning-item` module) and `hddhistory-admin` (Setting →
Warm-up tab).

## Rule

For each `Lesson`:

1. Build its ordered list of "Exercise folders" = `LearningItem` docs with
   `type: EXERCISE`, ordered by (position of their `keypointId` in
   `lesson.keypoints`, then their own `index` within that keypoint).
2. 0 folders → skip the lesson.
3. Exactly 1 folder → set `isDailyWarmUp: true` on every question in it.
4. ≥2 folders → set `isDailyWarmUp: true` on every question in the LAST
   folder (last keypoint in `lesson.keypoints`, highest `index` within it);
   set `isDailyWarmUp: false` on every question in every other folder.

This is a full sync, not additive: re-running always drives the DB to match
the rule exactly, including un-ticking questions that don't belong — it can
overwrite manual edits made outside this rule. Idempotent: running twice in
a row produces zero further changes.

## Decisions

- **Scope of a run:** whole system — every lesson/keypoint/exercise in the
  DB, one click, no per-course/per-lesson picker.
- **Reusable, not one-shot:** ships as a permanent button in Setting →
  Warm-up tab, safe to click anytime.
- **Preview before apply:** a dry-run pass computes and returns counts
  without writing; admin sees them before confirming the real write.
- **Update mechanism:** mirror the existing `LearningItemService.update`
  convention (full-array replace, `PUT /courses-learning-items/:id`) rather
  than introduce Mongo `arrayFilters`/positional updates — for the apply
  step, one `bulkWrite` `updateOne` per `LearningItem` whose `questions`
  array changes (every question in a given folder always moves together, so
  no per-question granularity is needed within one `bulkWrite` op).
- Both preview and apply run the exact same computation function; preview
  just skips the `bulkWrite` call.

## APIs

- `GET /api/v1/courses-learning-items/daily-warm-up-tagging/preview` — dry
  run. Response: `{ lessonsScanned, foldersChanged, questionsToTickOn,
  questionsToTickOff }`. No writes.
- `POST /api/v1/courses-learning-items/daily-warm-up-tagging/apply` — same
  computation, then persists via `bulkWrite`. Response: same shape, but
  reflecting what was actually written.

Both live on the existing `learning-item.controller.ts`, alongside the
existing `PUT /courses-learning-items/indexs` bulk-write route — same
module, same auth guard, same repository.

## Admin UI

New card in `hddhistory-admin/src/components/setting/` (rendered in the Warm-up
tab below the existing `WarmUpManagement` "Lesson Warm-up" card): a "Preview"
button calls the preview endpoint and displays the counts; an "Apply" button
(shown after preview, or disabled until a preview has run) calls the apply
endpoint and shows a success toast with the final counts.

## Dependencies

- `LearningItemRepository` / `LessonRepository` (existing)
- `AbstractRepository.bulkWrite` (existing, already used by the index
  bulk-update route)
- No schema changes — `questions[].isDailyWarmUp` already exists.

## Verification

- hddhistory-api: TypeScript build (`npm run build`), lint on touched files.
- hddhistory-admin: TypeScript compile check, `npm run build`.
- Manual: run preview twice in a row with no data changes in between →
  identical counts. Run apply once, then preview again → all counts should
  be zero (idempotency check). Spot-check one lesson with 1 exercise folder
  and one with 2+ folders against the DB after apply.
