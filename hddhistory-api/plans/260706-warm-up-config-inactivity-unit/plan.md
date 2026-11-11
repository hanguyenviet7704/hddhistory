# Warm-up Config: Configurable Inactivity Unit

## Status

- Not started

## Scope

Admin's "Lesson Warm-up" settings card currently only lets admins set an
inactivity threshold in whole days (`inactivityDays`). Purpose is to let QA
dial the threshold down to seconds/minutes/hours for fast testing without
waiting a full day, while production keeps using days by default. Touches
`hddhistory-api` (courses → warm-up-config, warm-up) and `hddhistory-admin` (Setting →
Warm-up tab).

## Decisions

- Replace `inactivityDays: number` with a value+unit pair everywhere:
  `inactivityValue: number` (`@IsInt() @Min(1)`, default 3) and
  `inactivityUnit: WarmUpInactivityUnit` (`'seconds' | 'minutes' | 'hours' |
  'days'`, default `'days'`).
- New enum `WarmUpInactivityUnit` + a `toMilliseconds(value, unit)` helper
  live in the `warm-up-config` module (interface/enum file) and are imported
  by `warm-up.service.ts` — mirrors the existing dependency direction
  (`warm-up` already reads `warm-up-config`'s config).
- `warm-up.service.ts` drops the hardcoded `MS_PER_DAY` float-division
  comparison in favor of direct millisecond comparison:
  `inactiveMs = Date.now() - lastActivity.getTime(); isDue = inactiveMs >=
  toMilliseconds(config.inactivityValue, config.inactivityUnit)`.
- Backward compatibility: no DB migration script. Keep the old
  `inactivityDays` field declared (optional, deprecated) in the Mongoose
  schema so any pre-existing document still round-trips it. In
  `WarmUpConfigService.getConfig()`, if the fetched doc has no
  `inactivityUnit`, fall back to `{ value: doc.inactivityDays ?? 3, unit:
  'days' }`. The next admin "Save changes" persists the new fields going
  forward; no other code path touches this document.
- Admin UI (`WarmUpManagement.tsx`): pair the existing number input with a
  unit `<select>` (Seconds/Minutes/Hours/Days, default Days), matching the
  existing input's styling. Update `IWarmUpConfig` /
  `WarmUpConfigPayload` (hddhistory-admin) to `{ inactivityValue: number;
  inactivityUnit: 'seconds' | 'minutes' | 'hours' | 'days' }`. Keep the
  `>= 1` integer validation, now applied regardless of chosen unit. Update
  the card's helper copy to no longer say "days" specifically (e.g. "Amount
  of inactivity time before a returning user is offered the lesson
  warm-up.").
- No change to the public contract of `GET
  /api/v1/warm-up/for-course/{courseId}` — it still only returns `isDue`
  (boolean) and `previousLesson`; hddhistory-flutter is unaffected.

## APIs

- `GET /api/v1/warm-up-config` — response shape changes:
  `inactivityDays` → `inactivityValue` + `inactivityUnit`.
- `PUT /api/v1/warm-up-config` — request body changes the same way.
- `GET /api/v1/warm-up/for-course/:courseId` — unchanged response contract;
  internal comparison logic changes only.

## Dependencies

- Mongoose (`warm-up-config` schema)
- Existing `WarmUpConfigService` ↔ `WarmUpService` dependency
- hddhistory-admin `warmUpConfigService`, `WarmUpManagement.tsx`

## Verification

- hddhistory-api: TypeScript compile check (`tsc --noEmit` or `npm run build`),
  lint check.
- hddhistory-admin: TypeScript compile check, `npm run build`.
- Manual: set inactivity threshold to a short value (e.g. 30 seconds) via
  the admin UI, wait it out, confirm `GET
  /api/v1/warm-up/for-course/{courseId}` flips `isDue` to `true` for a
  qualifying course/user.
