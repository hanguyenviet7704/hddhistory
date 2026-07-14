# Bulk actions for Habits & Re-anchor Reasons (meup-admin)

**Date:** 2026-07-14
**Scope:** meup-admin only (React CRA admin panel). No meup-api or meup-flutter changes.

## Problem

The Habits (`/habits`) and Re-anchor Reasons (`/reanchor-reasons`) admin list pages
only support one-row-at-a-time delete (a trash icon per row → single confirm dialog).
Editors managing dozens of rows have no way to act on many at once. They asked for
"bulk actions, e.g. delete all".

Two sibling list pages — `ExerciseList` and `TheoryList` — already implement a
bulk pattern (select-all-visible + "Delete selected"). Habits and Re-anchor Reasons
should get the same treatment, extended with bulk status change.

## Requirements (confirmed with user)

1. **Pages:** Habits and Re-anchor Reasons only. (Exercises/Theories already have bulk;
   other list pages are out of scope for now.)
2. **"Delete all" semantics:** select-all-of-currently-visible (filtered) rows, then
   delete the selected — NOT a "nuke the whole collection" button. Individual rows can
   be unchecked. This matches the existing `ExerciseList`/`TheoryList` behavior.
3. **Bulk actions:** Delete selected, **plus** bulk status change (Publish selected /
   Unpublish selected).

## Approach

**Chosen: Approach A — client-side, reuse the existing inline convention.**

- Bulk delete: `Promise.allSettled(ids.map((id) => service.remove(id)))`.
- Bulk status: `Promise.allSettled(ids.map((id) => service.update(id, { status })))`.
- No backend changes, no new endpoints, no deploy. Consistent with how
  `ExerciseList`/`TheoryList` already do bulk delete (client-side `Promise.all` over the
  existing single-item endpoints).

Both pages load their full dataset with `isAll=true` (no server pagination) and filter
client-side, so "all visible" is bounded to the filtered rows already on screen. The
lists are small (habits ~44, reanchor a few dozen), so N single requests is acceptable.

**Rejected: Approach B — backend bulk endpoints** (`POST /habits/bulk-delete`, etc.).
Faster for very large N and atomic, but requires controller/service/repository/DTO work
in meup-api plus a deploy, diverges from the established admin bulk convention, and is
over-engineered for these small lists. YAGNI.

## Design

### Files touched
- `src/pages/habits/HabitList.tsx`
- `src/pages/reanchor-reasons/ReanchorReasonList.tsx`

No changes to services, types, API, or shared components. The existing single-row
delete (trash icon + `HabitConfirm`/`ReanchorReasonConfirm`) stays as-is.

### State (added per page)
- `selectedIds: string[]` — currently selected row ids.
- `confirmBulkDelete: boolean` — controls the bulk-delete confirm dialog.
- `bulkBusy: boolean` — disables bulk buttons while a bulk op is running.

Derived:
- `selectedCount = selectedIds.length`.
- `allVisibleSelected` = every filtered row's id is in `selectedIds` (and there is ≥1 row).
- `someVisibleSelected` = ≥1 but not all → header checkbox shows `indeterminate`.

### UI
- A leading checkbox column on each row (MUI `Checkbox`, `TableCell padding="checkbox"`),
  bound to `selectedIds.includes(row._id)`.
- A header checkbox that toggles all *filtered* rows (select-all-visible), with the
  indeterminate state when only some are selected.
- A bulk-action bar shown only when `selectedCount > 0`, above/near the table:
  `{n} selected` + three buttons — **Delete selected** (red/destructive),
  **Publish selected**, **Unpublish selected**. All disabled while `bulkBusy`.

### Behavior
- **Delete selected:** opens a confirm dialog ("Delete {n} items? This action cannot be
  undone.") → on confirm, run the bulk delete, then clear selection, re-fetch the list,
  and toast `Deleted {n} …` (or `Deleted {ok}/{total} …` if some failed).
- **Publish/Unpublish selected:** non-destructive, runs immediately (no confirm) →
  `service.update(id, { status })` for each selected id, then clear selection, re-fetch,
  toast the result. **Publish** sets `status = PUBLISHED`, **Unpublish** sets
  `status = DRAFT` (per `HabitStatus` / `ReanchorReasonStatus`, which are both
  `{ DRAFT, PUBLISHED }`).
- **Partial failure:** use `Promise.allSettled` so one failing item doesn't abort the
  batch; report `{succeeded}/{total}` and show an error toast if any failed.
- **Selection reset:** clear `selectedIds` whenever the search term or any filter
  (status / skillset / course) changes, so a bulk action can never hit a row that has
  scrolled out of the current filter. Also clear after every completed bulk op.
- **Double-submit guard:** `bulkBusy` gates the bulk buttons and the confirm action.

### Error handling
- Each bulk op wrapped in try/finally to always reset `bulkBusy` and close the dialog.
- Toasts via the existing `useNotification()` (`showSuccess` / `showError`), matching the
  page's current single-delete messaging.

## Out of scope (YAGNI)
- No "delete entire collection" / nuke button.
- No backend/API changes.
- No refactor of `ExerciseList`/`TheoryList`. We deliberately replicate their inline
  pattern rather than extract a shared `BulkActionBar` now, to keep this change small.
  Extracting a shared component across all four pages is a possible future cleanup.
- No bulk actions on any other admin list page.

## Verification
- `npm run build` (tsc) clean; targeted lint on the two changed files clean.
- Manual/behavioral check: select-all toggles all filtered rows; changing a filter clears
  selection; bulk delete confirms then removes and refetches; bulk publish/unpublish flips
  status and refetches; buttons disabled mid-op; partial-failure toast reports the count.
