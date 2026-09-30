# The 11:45 nudge for readers with nothing unfinished

2026-08-06. Source: the "Noti" sheet, Version 3
(`1jyrm_9wmEuqWglebACW6RC2-WyJv-Bwg0gHRiP8325M`, gid 1834029623).

Row "2. Progress finish" in the sheet is one campaign split into two segments:

| Segment | Reader | Destination |
|---|---|---|
| 1 — *User có lesson đang học dở* | at least one lesson left unfinished | the course roadmap |
| 2 — *User không có lesson học dở nào* | D0, or finished everything started | Explore |

Only segment 1 was ever built. Segment 2 was the `return null` at the top of the
`PROGRESS_FINISH` branch of `resolveContext` — a reader with nothing unfinished
qualified for no 11:45 notification at all. This adds it.

## Decisions taken before implementing

| Question | Decision |
|---|---|
| One type or two | **Two.** `deeplink` and the seven wordings both live on the template document, and the two segments differ in both. A single type would have to push the condition down to each variant. |
| Type name | **`progress_start`**, paired with `progress_finish`. The value is written into every `notification_logs` row, so renaming it later rewrites history. |
| Sheet's "exclude anyone already sent segment 1 today" | **No code.** The two conditions are complements of each other computed from the same `findRecentStopAts` read, so exactly one holds for any reader. A cross-type suppression rule was deliberately removed from `dispatchToUser` earlier and is not being reintroduced. |
| `{topic_name}` source | **Two tiers**: the skillset of the course the reader last touched (`stops[0]`, already sorted newest-first — no extra query), else the newest published course's skillset. Failing both, the picker drops the two wordings that need it and the other five still go out. |
| Empty catalog | `resolveSharedContext` returning `null` aborts the whole template. That is right for `new_course` and wrong here, so `progress_start` returns `{}` instead — no topic is not a reason to stay silent. |
| Seeded deeplink | **`home`, not `explore`.** See below. |
| Daily cap | Unchanged at 4. Five types now exist, but the two at 11:45 are mutually exclusive, so the most any reader can qualify for in a day is still four. |
| Locales seeded | vi/en/ko/zh/ja, as the other types. id/ms/fil keep falling back to `en`. |

## Why the deeplink ships as `home`

The sheet asks for Explore. The app resolves destinations through a `switch` on
the raw string in `deeplink_cubit.dart` and logs anything it does not recognise
as unsupported — the tap then brings the app to the foreground and navigates
nowhere. Shipping `explore` today would do that on every install currently out
there.

So three things, rather than a guess:

1. `NotificationDeeplink.EXPLORE` exists on the server now, and the update DTO
   validates it.
2. `progress_start` is seeded pointing at `HOME`, which every build handles.
3. The admin screen gained a **deeplink selector**. `PUT
   /notifications/templates/:type` already accepted `deeplink`; only the UI was
   missing. Flipping to `explore` once the app release is live is a click, not a
   deploy — which matters because `seedMissing` uses `$setOnInsert` and would
   never rewrite the value in an environment that already has the document.

**Still open, tracked separately:** the Flutter case mapping `explore` →
`CourseRoute` (`/course`, shell branch 3). Until it ships, leave the selector on
`home`.

## Content

Seven wordings, transcribed from segment 2 of the sheet. Titles are shared with
`PROGRESS_FINISH` on purpose — the sheet writes them identically and the two
never reach the same reader on the same day, so the pair reads as one campaign
whose second sentence adapts.

No `{course_name}` anywhere, unlike segment 1: the tap lands on the catalog, so
naming a course would promise a screen the reader never sees. Variants 3 and 6
use `{topic_name}`; variant 4 uses no placeholder at all and is therefore always
eligible. The rest use only `{user_name}`, which is optional — five wordings can
always render, comfortably clearing the three-day cooldown even when no topic
resolves.

### Emoji: the earlier guesses corrected

The earlier design
(`plans/260804-notification-variants-new-course/design.md`) recorded that the
sheet's emoji arrived mangled (`ð±`, `ð§ `, `ð¹`) and that the substitutions in
`PROGRESS_FINISH` were therefore guesses. Exporting the sheet as CSV rather than
reading the text dump recovers them intact, so the guesses are now replaced by
what the sheet actually says:

| Variant | Sheet | Was seeded |
|---|---|---|
| v1 | 🍔 | 🍜 |
| v6 | 🌟 | 🚀 |
| v7 (segment 1) | 🍹 | 🎧 |
| v7 (segment 2) | 🍵 | — |

The two halves of v7 deliberately differ, as they do in the sheet. `daily_remind`,
`habit_tracking` and all three `new_course` wordings already matched.

Only the emoji were corrected. The prose deviations the earlier design justified
stand: `PROGRESS_FINISH` still says `{course_name}` and *"khoá học"* where the
sheet writes `{lesson_name}` and *"bài học"*, because the tap lands on a course
roadmap and the sheet's noun promises a screen the reader never sees.

### Applying it to an environment that already runs this

`seedMissing` uses `$setOnInsert`, so a deploy never rewrites a live
`progress_finish` document — the corrected emoji reach a fresh environment only.
`notification-templates-11h45.json` in this folder carries both types in the
admin screen's import shape, generated from the seed constants rather than
retyped. It omits `enabled`, so importing corrects the copy without switching
anything on or off: `progress_finish` keeps whatever state it is in, and
`progress_start` arrives disabled.

## Changes

| File | Change |
|---|---|
| `notification.enum.ts` | `NotificationType.PROGRESS_START`, `NotificationDeeplink.EXPLORE` |
| `notification.defaults.ts` | `PROGRESS_START_VARIANTS` (7 × 5 locales), seed entry at 11:45 / `HOME`, cap comment |
| `notification-dispatch.service.ts` | `resolveSharedContext` also loads the newest course for the new type and tolerates an empty catalog; new `resolveContext` branch |
| admin `notification.interface.ts` | both unions |
| admin `NotificationsPage.tsx` | labels 2a/2b, condition hints, variable hints, deeplink selector wired through the draft and the save payload |

Ships `enabled: false`, like every other type. `seedMissing` inserts a type that
has no document yet, so an existing environment picks `progress_start` up the
next time the admin screen is opened — no import file needed for this one.

## Verification

`npx tsc --noEmit` clean in both repos. The variant picker's "drop a wording
whose content placeholder is empty" path — which is what makes the missing-topic
case safe — is already covered by `notification-variant.helper.spec.ts`.
