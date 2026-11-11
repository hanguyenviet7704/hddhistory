# Onboarding redesign — delete old, rebuild from design, admin-editable

- **Date:** 2026-07-21
- **Ticket:** HDDHISTORY-<TBD>
- **Stacks:** hddhistory-api + hddhistory-admin + hddhistory-flutter
- **Status:** PLAN — for user review before any deletion / code
- **Design source of truth:** claude.ai/design project "HDDhistory" →
  `design_handoff_hddhistory_app/README.md` + `1 · Onboarding.dc.html` +
  `HDDhistory App.dc.html` (live reference). Design tokens/flow/assets quoted below.

## 1. Goal

Replace the current tangled, partly-hardcoded onboarding with ONE clean
onboarding that (a) matches the new design pixel-for-pixel and (b) is fully
**admin-editable** (content served by the API, not baked into the app). No more
enum/l10n-hardcoded paths or copy.

## 2. Decisions (confirmed with user)

| Decision | Choice |
|---|---|
| Delete scope | **All 3 stacks** — remove every old onboarding implementation |
| New onboarding | **API-driven, admin-editable** (design content, editable in admin) |
| Approach | **Detailed plan first** (this doc), then implement after approval |
| Fidelity | **Pixel-perfect** to design (tokens/spacing/motion per README) |

## 3. What gets DELETED

### hddhistory-flutter
- `lib/src/onboard/` (v1)
- `lib/src/onboard_v2/`
- `lib/src/onboard_branching/`
- Their routes in `lib/config/routes/data/routes_onboard_data.dart` (+ any
  onboarding entries in `routes_common_data.dart`), DI registrations, and the
  `OnboardingPath`/`OnboardingSymptom` enums in
  `lib/src/course/data/models/course_model.dart`.
- Splash entry `_goOnboardingEntryByFlowConfig` → repoint to the new flow.
- Onboarding l10n YAML keys (`assets/i18n/*/onboarding.yaml`) — dropped once copy
  comes from the API (keep a minimal fallback set, see §6 safety).

### hddhistory-api
- `src/modules/user/src/modules/onboarding/` old shape: the v1 `Onboarding`
  schema fields we won't reuse, `onboarding-scenario-branching.*` (schema,
  controller, repository, interface, DTOs), and the `paths[]`/`copy[]` we bolted
  onto v1 last session. Replaced by a purpose-built onboarding-config schema (§5).
- Corresponding flutter/admin API clients for scenario-branching.

### hddhistory-admin
- `src/pages/onboardings/OnboardingManagemant.tsx` (old v1 + the Paths/Copy
  sections), `OnboardingManagemantScenarioBranching.tsx`, and the matching
  `src/types/interface/onboarding*.interface.ts`. Replaced by a new onboarding
  editor (§5).

> Deletion happens on a branch and the NEW flow lands before the old is removed
> from the splash entry, so first-run is never broken mid-migration (§7).

## 4. New onboarding flow (9 screens, from design)

Order (design `onb:` pins): `splash → welcome → name → age → paths → brain →
habit → notif → pick`.

| # | Screen | Content (admin-editable unless noted) | Notes / motion |
|---|---|---|---|
| 1 | **Splash** | logo, brand — static | bg `#F2F1FA` |
| 2 | **Welcome** | rotating deck of 6 cards (label + image per card), gradient H1, subhead, CTA label | deck auto-advances (interval); gradient text |
| 3 | **Name** | H1, helper, input hint, CTA | CTA disabled until non-empty |
| 4 | **Age** | H1 template (`Nice {name}`), 5 life-stage options (label) | single-select rows + check-circle |
| 5 | **Paths** | H1, helper, 6 paths (icon + label), multi-select cap 2 | icons `cat-*.svg` |
| 6 | **Brain science** | title, unlocked-paths pill copy, "N more waiting" copy | animated hexagon (SVG, static art) |
| 7 | **Habit** | framing copy | |
| 8 | **Notifications** | heading, subtitle, preview-card title/body/timestamp, CTA | system permission ask |
| 9 | **Pick course** | label/CTA copy — course list is **dynamic** (real courses API) | recommended by picked paths |

Design tokens (fonts Poppins/Mulish, palette `#554FF0` etc., 56px pill CTAs,
14px inputs, selectable rows, per-screen bg colors, motion keyframes) — per
README §Design Tokens; applied via the app's existing theme tokens where they
map, new tokens added where needed.

## 5. New architecture (API-driven, admin-editable)

### Backend (hddhistory-api) — one onboarding-config document
A singleton `OnboardingConfig` (Mongo) modeling the design's editable content:
```
OnboardingConfig {
  welcome: { titlePrefix: ML, titleBrand: string, subtitle: ML, ctaLabel: ML,
             deck: [{ key, label: ML, imageUrl }] }
  name:    { heading: ML, helper: ML, inputHint: ML, ctaLabel: ML }
  age:     { headingTemplate: ML, ctaLabel: ML,
             options: [{ key, label: ML, order }] }
  paths:   { heading: ML, helper: ML, maxSelect: number,
             items: [{ key, label: ML, iconKey, iconUrl, order }] }
  brain:   { heading: ML, unlockedPillTemplate: ML, moreTemplate: ML }
  habit:   { heading: ML, subtitle: ML, ctaLabel: ML }
  notif:   { heading: ML, subtitle: ML, cardTitle: ML, cardBody: ML,
             cardTimestamp: ML, ctaLabel: ML }
  pick:    { heading: ML, label: ML, primaryCta: ML, secondaryCta: ML }
}
// ML = { en, vi } (ITranslation). iconKey→bundled asset, iconUrl override.
```
- `GET /api/v1/onboarding-config` → returns the whole config (public-ish, auth as
  today). `PUT /api/v1/onboarding-config` → admin update (partial).
- Strict layering: controller → service → repository. Seed identical to design.

### Admin (hddhistory-admin)
- New page `OnboardingConfig` — one form, sections per screen (Welcome / Name /
  Age / Paths / Brain / Habit / Notifications / Pick), en/vi fields, image
  uploads for deck + path icons (CloudflareFileUpload), reorderable lists (age
  options, paths, deck). Saved via the config PUT.

### Flutter (hddhistory-flutter) — new `onboarding` feature
- Clean-architecture feature `lib/src/onboarding/`: data (model+datasource+repo),
  domain (entities+usecase), presentation (9 pages + one `OnboardingCubit` state
  machine mirroring the design's `screen` steps).
- Fetches `OnboardingConfig` once at flow start; each screen renders from it.
- Course-pick screen wires to the existing courses API (recommended by paths).
- go_router: one `onboarding` shell/stack with the 9 steps; splash routes here
  when the user hasn't onboarded.
- Assets: import the design SVGs/PNGs (`cat-*.svg`, hexagon, deck images, etc.)
  into `assets/` via flutter_gen.

## 6. Seed / migration
Seed script (user-run, via API + bearer token — not direct Mongo) that writes the
config with the **exact design copy** (en; vi translated to match current app
wording where it exists). Idempotent GET-merge-PUT like the last seed.

## 7. Safety / sequencing (first-run must never break)
1. Backend + admin land first (new config endpoint + editor), seed dev.
2. Flutter: build the new `onboarding` feature fully; only then repoint splash
   from the old flow to the new one and delete the old flutter features.
3. Fallback: if the config fetch fails on first run, ship a minimal bundled
   default (a trimmed asset/JSON) so onboarding still shows — then remove the old
   enums. (Keeps the "never blank on first run" guarantee.)
4. All on a branch; old code removed only after the new flow is verified on sim.

## 8. Phasing (proposed build order)
- **P1** Backend: `OnboardingConfig` schema/DTO/controller/service/repo + seed.
- **P2** Admin: `OnboardingConfig` editor page + service + route.
- **P3** Flutter: new `onboarding` feature — data/domain + `OnboardingCubit` +
  screens 1–9, screen-by-screen against the `.dc.html` reference, wired to API.
- **P4** Repoint splash + delete old onboarding (flutter/api/admin) + drop stale
  l10n/enums.
- **P5** Verify on sim (pixel check per screen) → dev build.

## 9. Open questions for review
1. **Age options / welcome deck / brain+habit copy** — confirm these should all
   be admin-editable too (plan assumes yes). If some are fixed, we can bake them.
2. **Symptoms** — the new design has NO symptom-selection step. Confirm we drop
   symptoms entirely (current app has it; design removed it).
3. **vi copy** — design README is en-only for some strings; reuse current app's
   vi wording where it exists, translate the rest. OK?
4. **Course recommendation** — keep matching recommended courses by picked path
   keys (as today)?

## 10. Out of scope
- The other design screens (Home/Course/Explore/Habit/Profile) — this plan is
  onboarding only.
- Changing the courses/recommendation backend beyond wiring the pick screen.
