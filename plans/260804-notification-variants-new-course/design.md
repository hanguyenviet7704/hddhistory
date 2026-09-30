# Notification variants + the daily new-course push

2026-08-04. Source: the "Noti" sheet, Version 3
(`1XOHsZPZJf7PnY2Eg6-mKWq3tesbJS3awEDUKw1JEOrg`).

Two changes to the scheduled notifications:

1. **Progress finish** carries seven wordings instead of one, and rotates them
   per user per day.
2. A fourth type, **Khoá học mới** (`new_course`), announces the newest published
   course at 20:00 local, every day.

## Decisions taken before implementing

| Question | Decision |
|---|---|
| New-course trigger | **Always send** the newest course by `createdAt`, re-announcing the same course on later days when nothing newer exists. (The sheet said "only when a course published today"; the product call was daily reach.) |
| Variant selection | **Random, avoiding the last three days per user** — for both types. The sheet's behaviour-based split for `new_course` was dropped. |
| `{topic_name}` | The **skillset title of the course the notification names** (`course.skillsetId` → `skillset.title`), not the reader's onboarding interests. |
| Locales seeded | **vi/en/ko/zh/ja**. id/ms/fil keep falling back to `en`, as they already did. |
| Deeplink | New symbolic value **`new_course`**, handled in the app; older builds log it as unsupported and just come to the foreground. |
| Daily cap | `MAX_NOTIFICATIONS_PER_DAY` **2 → 4**. |

Because wordings are picked at random, two claims in the sheet's `new_course`
copy were dropped — they assert behaviour a randomly-chosen reader may not have:

- variant 1 no longer says *"đã hoàn thành khóa học trước rất tốt"*;
- variant 3 no longer says *"đúng thứ bạn đang luyện"*.

Two more deliberate deviations from the sheet, both worth a content review:

- The sheet writes `{lesson_name}` and the noun *"bài học"*. The value has always
  been a **course** title (the tap lands on the course roadmap), so the seed uses
  `{course_name}` and says *"khoá học"*. `{lesson_name}` still renders, for copy
  saved before the rename.
- **The emoji are guesses.** The sheet's export mangles them (`ð±`, `ð§ `, `ð¹`),
  and the bytes are unrecoverable from the text dump. Substitutions used:
  🍜 (lunch), 🌱, ⏳, 🧠, ❓, 🚀, 🎧 for progress finish; 🎯, 🔥, ✨ for new course.

## Data model

`notification_templates` stays one document per type. Added:

```ts
variants: { key: string; copies: Record<locale, { title; body }> }[]
variantSeq: number
```

- `copies` (the old single map) is **kept and mirrored from the first variant**, so
  a document written before this change still reads, and nothing needs a Mongo
  migration — which matters because this collection has no migration mechanism.
  `variantsOf()` is the one place that decides which field to read.
- `key` — not an array index — is what the cooldown remembers. Deleting or
  reordering a wording must not make a log row point at a different sentence.
- `variantSeq` only ever increases, so a key is never recycled onto a different
  wording (a recycled key would let a deleted sentence's history suppress a
  brand-new one).

## Picking a wording

`notification-variant.helper.ts`, pure and unit-tested
(`notification-variant.helper.spec.ts`, 18 cases):

1. **Renderable** — has copy for the reader's locale (or `en`), a non-empty title,
   and every content placeholder (`course_name`, `topic_name`, `quote`) resolvable
   to a non-empty value. `{user_name}` is exempt but deprioritised: a wording that
   needs no name wins over greeting an unnamed reader.
2. **Cooldown** — drop keys sent to this reader within the last
   `VARIANT_COOLDOWN_DAYS` (3) local days, counting `sent` rows only.
3. **Relax rather than fail** — if that empties the pool, try "not yesterday",
   then allow anything. `new_course` has three wordings against a three-day
   window, so it would otherwise go silent from day four.
4. Uniform random from what survives. The chosen key is written to the log's
   `meta.variantKey`.

The dispatcher reads the log **once** per user per type
(`findByUserAndDateRange(userId, today-3, today)`): today's rows are the daily
rules, the earlier ones the cooldown memory. No extra query per tick.

## `new_course`

- `CourseRepository.findNewestPublished()` — newest `createdAt` among
  `status: published, numberOfLesson > 0`. Backed by a new
  `{ status: 1, createdAt: -1 }` index.
- Resolved **once per tick** in `resolveSharedContext`, not per user: the newest
  course is the same document for everybody. Returns null on an empty catalog,
  and the tick then skips the candidate query entirely.
- Payload carries `courseId`; `meta` records `courseId` + `courseName`.
- `{topic_name}` uses a 5-minute skillset-title cache, which also serves progress
  finish (there the course differs per reader, so it cannot be hoisted).

## Rolling the copy out

`seedMissing` uses `$setOnInsert`, so **a deploy does not give an existing
environment the new variants** — an editor's wording must never be reverted by a
release. Instead:

1. Admin → Thông báo định kỳ → **Import JSON** →
   `notification-templates-v3.json` (in this folder, generated from the seed in
   code so the two cannot drift).
2. The file deliberately omits `enabled`, and import now leaves that flag alone —
   importing content cannot switch a live notification off, and cannot switch one
   on either. Toggle it by hand.
3. It **does** set the schedule: progress finish moves to 11:45, new course to
   20:00.

## Admin

`NotificationsPage.tsx`: each type lists collapsible variants (seven wordings ×
eight locale rows is 56 inputs, so all but the first start closed), with add and
delete, a `key` badge, and the first non-empty title as the collapsed summary.
Also: the fourth type's label, per-type variable hints, a variant selector on the
test send (default random, and the response reports which one went out), and the
variant key shown on each monitor row.

Saving posts the whole list — a wording left out is deleted. A save with no
non-empty wording is refused rather than silently muting the type.

## Flutter

`deeplink_cubit.dart` gains `case 'new_course'` → the announced course's roadmap,
falling back to Home when the payload has no course or it can no longer be
selected. It does **not** reuse `openCourseRoadmapFromLiveActivity`, which keeps
a lesson that is already on screen — right for "resume", wrong for "open this new
course".

## Files touched

**hddhistory-api** — `notification.enum.ts`, `schema/notification-template.schema.ts`,
`notification-variant.helper.ts` + `.spec.ts` (new), `notification.defaults.ts`,
`dto/notification-template.dto.ts`, `notification-template.service.ts`,
`notification-dispatch.service.ts`, `notification.controller.ts`,
`notification.module.ts`, `repository/notification-log.repository.ts`,
`courses/.../course/repository/course.repository.ts`,
`courses/.../course/schema/course.schema.ts`.

**hddhistory-admin** — `types/interface/notification.interface.ts`,
`services/notificationService.ts`, `pages/notifications/NotificationsPage.tsx`.

**hddhistory-flutter** — `lib/src/common/presentation/cubits/deeplink/deeplink_cubit.dart`.

## Verification

- `npx tsc --noEmit` clean in hddhistory-api and hddhistory-admin.
- `npx jest src/modules/notification/notification-variant.helper.spec.ts` — 18/18.
- `dart analyze` clean on the touched Dart file.
- Manual, after deploy: import the JSON, then test-send each wording of both types
  to a real device (the selector makes each key reproducible), and check the
  monitor tab shows the variant key.
