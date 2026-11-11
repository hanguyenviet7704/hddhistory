# Onboarding v2 — API-driven content (paths / symptoms / copy)

- **Date:** 2026-07-17
- **Ticket:** HDDHISTORY-<TBD>
- **Stacks:** hddhistory-api (lead) · hddhistory-admin · hddhistory-flutter
- **Status:** design approved — pending spec review → implementation plan

## 1. Problem

The active onboarding flow (`onboard_v2` in hddhistory-flutter) is partly hardcoded:

- **Paths + symptoms + branching mapping** are baked into Dart enums
  (`OnboardingPath` / `OnboardingSymptom` in
  `hddhistory-flutter/lib/src/course/data/models/course_model.dart`), with labels in
  slang l10n and icons as bundled assets.
- **Copy** for the intro / name / notification / motivation screens is read
  from slang l10n (also in-app), not from the API.
- Only `age`, the motivation payload, and recommended courses are already
  API-driven (`onboard_v2_cubit` already fetches `OnboardModel` via
  `GET /onboardings` → `onboardData`).

Changing any path, symptom, mapping, label or icon requires an app release. Goal:
serve **all** onboarding content from the API, fully editable in admin, while the
UX and content remain **identical** to what ships today.

## 2. Decisions (from brainstorming)

| Decision | Choice |
|---|---|
| Scope | **Full content** API-driven (paths/symptoms/mapping + copy + icons) |
| Content management | **Full admin CRUD** |
| Backend architecture | **Extend the existing `onboarding` module** (no new module/endpoint) |
| Icons | **Hybrid**: `iconKey` → bundled asset; optional `iconUrl` override |
| Offline safety | **Keep enum + l10n as offline fallback** (first-run critical) |
| Localisation | en/vi via existing `ITranslation` |

## 3. Data model (extend `Onboarding` schema)

`hddhistory-api/.../onboarding/schema/onboarding.ts` + `interface/onboarding.interface.ts`.
Add one field `paths: IOnboardingPath[]` — nesting encodes the path→symptom
mapping that the enum currently hardcodes.

```ts
export interface IOnboardingPath {
  key: string;              // stable, e.g. "FEEL_BETTER" — drives icon map, fallback, course match
  title: ITranslation;      // { en, vi }
  shortTitle: string;       // "Feel"
  iconKey: string;          // maps to a bundled asset (identical look, no upload)
  iconUrl?: string;         // optional override (admin upload → R2); app prefers it when present
  trackingLabel: string;    // "FEEL_BETTER"
  order: number;
  symptoms: IOnboardingSymptom[];
}

export interface IOnboardingSymptom {
  key: string;              // "MOTIVATION_DISAPPEARS"
  title: ITranslation;
  trackingLabel: string;
  order: number;
}
```

`IOnboarding` gains `paths: IOnboardingPath[]`. Existing fields (intro, age,
motivations, loading…) are unchanged and are the home for the copy migration
(§6). No v1 field is removed — v1 onboarding keeps working.

## 4. Backend API (extend, don't add endpoints)

- **`GET /onboardings`** — response gains `paths[]`. `onboard_v2` already calls
  this, so **no flutter fetch rewiring** and no new endpoint.
- **Admin CRUD** for paths/symptoms lives in the existing onboarding
  controller/service/repository. Strict layering preserved: controller
  (transport) → service (ordering, validation, dedup of `key`) → repository
  (only DB layer). Validation: unique `key` per path and per symptom; `order`
  normalised server-side.
- `iconUrl` upload reuses the existing R2 file-upload path (same as other admin
  image uploads).

## 5. Admin (full CRUD)

Add a **"Learning Paths"** section to `hddhistory-admin/src/pages/onboardings/OnboardingManagemant.tsx`:

- Reorderable list of paths (dnd-kit, matching existing admin lists).
- Path form: `title`/`shortTitle` (en/vi), icon (pick a bundled `iconKey` **or**
  upload an image → `iconUrl`), `order`.
- Nested reorderable symptom list per path: `title` (en/vi), add/edit/delete.
- Wire through `onboardingService.ts` → `axiosClient` (token refresh untouched).
- All states: loading / empty / error / saving; optimistic reorder with rollback.

## 6. Flutter

- `OnboardEntity` (+ model) gains `paths: List<OnboardPathEntity>` (freezed +
  json). `OnboardPathEntity` carries `key, title, shortTitle, iconKey, iconUrl,
  symptoms[]`. Rerun build_runner.
- **Path/symptom screens** read `onboardData.paths` instead of
  `OnboardingPath.values` / `path.symptoms`.
- **Copy screens** (intro, name, notification, motivation) read from
  `onboardData` (`intro`, `welcome`, `motivationOne/Two/Three`, `loading`) which
  is already fetched; seeded with the current v2 copy (§7).
- **Icon resolution:** `iconUrl` if non-empty, else map `iconKey`→bundled asset,
  else a neutral default.
- **Offline fallback (critical):** a resolver returns API paths when present;
  otherwise falls back to the existing enum (+ l10n labels). So a failed/empty
  first-run (no cache yet) still shows the exact current onboarding. The enum is
  demoted to fallback-only — not deleted.
- Course recommendation keeps matching on `key`/`trackingLabel` (unchanged
  contract), so recommended courses stay identical.

## 7. Seeding (identical content)

A **seed script/file the user runs themselves** (per standing rule) that writes
the exact current content into the DB:

- 6 paths (Feel/Think/Work/Connect/Learn/Explore Better) with their current
  `key`, `shortTitle`, `iconKey`, `order`, and en/vi titles taken verbatim from
  today's slang l10n (`assets/i18n/{en,vi}/onboarding.yaml`).
- 3 symptoms per path, in the current order, with en/vi titles from l10n.
- Copy fields (intro/motivation/…) seeded with current v2 l10n text.
- Delivered as a script that **POSTs to the admin onboarding endpoint with a
  bearer token** (not direct Mongo) — matches the dev DB topology
  (hosted api-dev uses a different Mongo than local `.env`).

## 8. Testing

- **Backend:** service unit tests — paths CRUD, unique-key validation, order
  normalisation; `GET /onboardings` includes `paths`.
- **Flutter:** onboard_v2 renders paths/symptoms from API; **fallback** test —
  API empty ⇒ enum content rendered; icon resolver (url > key > default).
- **Visual:** sim run before/after — onboarding must look **identical**; verify
  path selection → symptom selection → recommended courses unchanged.

## 9. Rollout / safety

- Backend + admin ship first (additive, backward-compatible: `paths` optional).
- Seed dev DB, verify in admin + app on dev build.
- Flutter reads paths from API with enum fallback ⇒ safe even before seeding
  (falls back to today's behaviour).
- No breaking change to v1 onboarding or the course-recommendation contract.

## 10. Out of scope

- Reworking onboarding into the generic `scenario-branching` engine.
- Removing the enum entirely (kept as fallback).
- Changing the recommended-course algorithm.
