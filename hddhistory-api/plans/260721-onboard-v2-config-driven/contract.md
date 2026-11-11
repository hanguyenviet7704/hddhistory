# onboard_v2 ← onboarding-config (data contract)

Goal: keep onboard_v2's shipped UI 100% unchanged, but drive its content from the
`onboarding-config` singleton (the nice admin) instead of the legacy `/onboardings`
module. Lowest-risk shape: **onboard_v2 keeps consuming `OnboardEntity`**; we only
swap the loader to fetch `GET /onboarding-config` and **map the config → OnboardEntity**.

## Hard invariant (do not break)
onboard_v2 selection + course recommendation round-trip path/symptom **keys through
the Dart enums** `OnboardingPath` / `OnboardingSymptom` (`trackingId == key`). So the
config's path/symptom `key`s MUST be exactly these enum values:

Paths (6): `FEEL_BETTER THINK_BETTER WORK_BETTER CONNECT_BETTER LEARN_BETTER EXPLORE_BETTER`

Symptoms (18, 3 per path, in this order):
- FEEL_BETTER: `MOTIVATION_DISAPPEARS`, `LIFE_FEELS_OVERWHELMING`, `ENDLESS_SCROLLING_FEELS_EMPTY`
- THINK_BETTER: `OVERTHINKING`, `TRYING_TO_DO_TOO_MUCH`, `RUSHED_DECISIONS`
- WORK_BETTER: `DIFFICULTY_BUILDING_HABITS`, `TIME_SLIPS_AWAY`, `STRUGGLING_TO_BREAK_BAD_HABITS`
- CONNECT_BETTER: `ANXIETY_AROUND_HARD_CONVERSATIONS`, `WANT_TO_LISTEN_MORE_DEEPLY`, `REGRET_SAYING_THINGS_IN_EMOTION`
- LEARN_BETTER: `LEARNING_DOES_NOT_STICK`, `FORGETTING_AFTER_STUDYING`, `LOSING_TRAIN_OF_THOUGHT`
- EXPLORE_BETTER: `CURIOUS_ABOUT_BODY`, `LOVE_LEARNING_FROM_GREAT_MINDS`, `AMAZED_BY_HUMAN_BODY`

If the config is empty/unavailable (first run / offline), the mapper yields an
OnboardEntity with empty paths → `OnboardV2PathResolver` already falls back to the
bundled enums. So onboard_v2 never breaks; the config only overrides.

## 1. Backend (hddhistory-api) — add symptoms to a path item
Add nested `symptoms[]` to the paths section item. New shapes:

```ts
export interface IOnboardingPathSymptom {
  key: string;          // must equal an OnboardingSymptom enum value (see above)
  label: ITranslation;
  order: number;
}
// IOnboardingPathItem gains:
symptoms: IOnboardingPathSymptom[];
```
- interface: add `IOnboardingPathSymptom`, add `symptoms` to `IOnboardingPathItem`.
- dto: add `OnboardingPathSymptomDto` ({ key, label @IsMultiLangString, order }) and
  `@Type(() => OnboardingPathSymptomDto) symptoms?: OnboardingPathSymptomDto[]` on
  `OnboardingPathItemDto` (mirror how `items` is typed on the paths section).
- schema: nested array `@Prop`, default `[]`.
- Singleton find-or-create + PartialType update DTO already handle it; no new route.

## 2. Admin (hddhistory-admin) — symptom sub-editor
On `OnboardingConfigPage` under each path item, add a small dnd-kit sortable list of
symptoms with a MultilangField for `label` + add/remove/reorder. Update the TS
interface (`onboarding-config.interface.ts`) `symptoms: OnboardingPathSymptom[]` and
the service (already reads `res.data.data`). No new endpoint.

## 3. Flutter (hddhistory-flutter) — swap loader, keep UI
- Reuse the existing `lib/src/onboarding/` **data+domain** layer (it already fetches
  `GET /onboarding-config` → `OnboardingContentConfigEntity` via
  `GetOnboardingConfigUseCase`). Add `symptoms` to the config path-item entity+model
  (mirror backend JSON: `symptoms: [{ key, label, order }]`).
- **DELETE the `onboarding` presentation layer** (the abandoned redesign UI:
  pages/cubit/widgets/shell/deck/progress-header + its route). Keep domain+data.
  Remove OnboardingRoute from the route tree. (splash already points to OnboardV2Route.)
- Add mapper `OnboardV2ConfigMapper.toOnboardEntity(OnboardingContentConfigEntity)`:
  - `age` = config.age.options → OnboardOptionEntity(id: index, label: o.label,
    title: o.label, trackingLabel: o.key)
  - `paths` = config.paths.items → OnboardPathEntity(key: p.key, title: p.label,
    shortTitle: OnboardV2PathResolver.matchPath(p.key)?.shortTitle ?? '',
    iconKey: p.iconKey, iconUrl: p.iconUrl, trackingLabel: p.key, order: p.order,
    symptoms: p.symptoms → OnboardSymptomEntity(key: s.key, title: s.label,
    trackingLabel: s.key, order: s.order))
  - `copy` = emit these keys (value from config; blanks are fine — `onbCopy` falls
    back to l10n): 
    - onboardingV2P1TitlePrefix ← welcome.titlePrefix
    - onboardingV2P1TitleBrand ← welcome.titleBrand (String → wrap in BaseMultiLanguage)
    - onboardingV2P1SubtitleLine1 ← welcome.subtitle
    - onboardingV2P1GetStartedCta ← welcome.ctaLabel
    - onboardingV2P2HeadingPrefix ← name.heading
    - onboardingV2P2HeadingHighlight ← name.headingHighlight
    - onboardingV2P2Subtitle ← name.helper
    - onboardingV2P2InputHint ← name.inputHint
    - onboardingV2P6HeadingPrefix ← notif.heading
    - onboardingV2P6HeadingHighlight ← notif.headingHighlight
    - onboardingV2P6Subtitle ← notif.subtitle
    - onboardingV2NotificationCardTitle ← notif.cardTitle
    - onboardingV2NotificationCardBody ← notif.cardBody
    - onboardingV2NotificationCardTimestamp ← notif.cardTimestamp
    - onboardingV2NotifyCta ← notif.ctaLabel
    - (onboardingV2P1SubtitleLine2 has no config source → omit, l10n fallback.)
- onboard_v2 cubit: replace `_getAllOnboardsUseCase` with `_getOnboardingConfigUseCase`
  + map in `loadOnboardData()` (fold success → `OnboardV2ConfigMapper.toOnboardEntity`).
  Everything else in the cubit/pages/resolvers stays byte-identical.
- Ensure `OnboardV2IconResolver` resolves config iconKeys (cat_feel…cat_explore) OR
  seed uses iconKeys onboard_v2 already knows; icons must render on P5/P6.
- build_runner + slang + `flutter analyze lib/` clean.

## 4. Seed (user runs — needs short-lived admin bearer token)
`onboarding-config-seed.json` (this dir) = full welcome/name/age/paths(+symptoms)/
notif content EN+VI, keys per the invariant above. `seed.sh` PUTs it to
`/api/v1/onboarding-config`. Do NOT touch Mongo directly.
