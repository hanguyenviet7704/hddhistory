# Change Background / Study Theme — Design Spec

**Ticket:** DC-20260720-01 · **Branch:** `feature/habit-builder` · **Status:** approved, in build

Personalization of the **study background** (color / gradient / image / live video+audio)
applied across several screens, with a readability **overlay**. This is NOT OS dark mode.

Scope (confirmed with user):
- **Full** feature: color/gradient + image + upload + **live (video + ambient audio)**.
- **No premium gate.**
- Preset list/groups/live are **SAMPLE** now (match design); official data from lynci later —
  build against a schema that maps cleanly to that data.

## Source of truth
- Change table DC-20260720-01 (13 items) — pasted by user.
- Claude Design project `9c326509-f453-4499-935b-40889a120b66` via DesignSync:
  - `HDDhistory App.dc.html` master — `app:home#changebg` pin, `cbPresets`/`_cbLoad`/`_cbPersist`,
    bottom-sheet markup, FAB markup. (Master is 264.8KB > 256KiB tool cap → the tail getters
    `cbGroups`/`warmCardBg`/`kpScreenBg`/`surveyBtnBg` were truncated; reconstruct from the
    change-table descriptions or refetch `design_handoff_hddhistory_app/HDDhistory App.dc.html`.)
  - `design/fig-tokens.css` — `--theme-*` palette (7 tones × light/mid/mid-40/dark/darker) =
    the sample color/overlay palette.
  - `assets/bg/*.jpg` (autumn/ocean-photo/ocean-sunset/pastel/rain-photo/water), `cb-theme-icon.svg`.

## Architecture (chosen: A — global host + per-screen wrapper)
Single source of truth `StudyThemeCubit` (HydratedCubit). One `ThemedBackground` widget used in:
1. **Shell** (`lib/core/utils/layouts/scaffod_layout.dart` `Stack`): a `Positioned.fill` behind
   `navigationShell`; tab pages (Home/Course/Explore/Habit/Profile) make their Scaffold
   transparent → background persists seamlessly across tabs (no reload/flicker).
2. **Per-screen wrapper** for full-screen routes that cover the shell: **Keypoint** learning +
   **Warm-up** intro/quiz.

Rejected (B): per-screen wrapper on every screen — background flickers/reloads on tab switch,
header+footer not seamless.

## Module (Clean Architecture) — `lib/src/study_theme/`
```
domain/entities/    study_theme_preset.dart (freezed) + enums (StudyThemeMode, category)
data/               preset_catalog.dart (SAMPLE presets, schema maps to lynci) + persistence
presentation/
  cubits/           study_theme_cubit.dart (HydratedCubit<StudyThemeState>)
  widgets/          themed_background.dart · themed_glass_card.dart ·
                    change_background_button.dart · change_background_sheet.dart
```

## Data model (mirrors design `cbPresets` + lynci schema)
```dart
StudyThemePreset { id, mode, category, name, gradient?, imageUrl?, videoUrl?, audioUrl?, thumb, isDark }
enum StudyThemeMode { defaultMode, color, image, video }   // 'live' = video (+audio)
```
Persist key `cb_bg3` via HydratedCubit: persist ONLY `default`/`color` presets; NOT image/video/
upload (design `_cbPersist`). Uploaded image kept in-memory (transient) only. Default fallback =
`{ id:'default', mode:default, name:'Default', isDark:false }`.

Sample presets (from design, extend when lynci ships data):
- default: gradient `#EFEEF9→#E6EBDE`
- Solid & Gradient: lavender `#EDE9FF→#D5D2F7`, peach `#FFE7D6→#FCD1C0`, mint `#DCF6EC→#C3EBDD`,
  midnight `#20244A→#141733` (dark)
- Nature (image): autumn, sunset, … (`assets/bg/*`)
- Live (video+audio): sample from `uploads/*.MP4` + ambient audio

## State (`StudyThemeState`)
`preset · soundOn(true) · scrimOn(true) · applying(loading) · uploadedFile(transient)`

## Tech mapping (deps already in pubspec)
| Mode | Impl |
|---|---|
| color/gradient | `Container` decoration |
| image / upload | `cached_network_image` / `FileImage` + `image_picker` (gallery, image-only) |
| video/live | `video_player` (loop, muted) + `just_audio` (ambient loop); pause on app-background, stop on leave |
| glass card (items 10/11/12) | `BackdropFilter(ImageFilter.blur ~8px)` + white ~60% |
| overlay (item 4) | dark ~18% for uploads / per-preset; "Applying theme…" (item 5) while video/audio warms |

## Per-screen wiring (13 items)
- **Home**: FAB in greeting header (2) + themed "Got ideas" button (13)
- **Course/Explore**: floating FAB (2)
- **Keypoint** learning: "Change theme" in 3-dot menu (1, icon `#554FF0`) + `kpScreenBg` + glass content cards (12)
- **Warm-up** intro/quiz: glass cards (10, 11)
- **Sheet** (3/5/6/8/9): near-full (`top:52px`), radius 28, scrim `rgba(11,11,16,.5)`, grab handle,
  header "Background" + ✕; **upload bar** (dashed `#C7C9D4`, `#FAFAFC`, image-only) at top; **groups**
  by `category` (uppercase heading) + **3-col grid**; tile `aspect 1/1.4` r16, `background = thumb`
  (true color, NO overlay), badges: live `▶`, selected ring `#554FF0` + `✓`; NO name labels.

### FAB spec
42px (Home) / 46px (Course), circle, bg `#F7F7FA`,
shadow `0 6px 16px rgba(37,37,37,.18)` + inset white hairline; icon stroke = theme-adaptive `cbBtnBg`.

## i18n
New slang keys (en/vi + zh/ja/ko): sheet title, upload label, group names, "Applying theme…", etc.

## Phasing
1. **Core**: cubit + model + persistence + `ThemedBackground` + Home shell + FAB + sheet (color/gradient/image)
2. **Glass & surfaces**: glass cards + `kpScreenBg` + Course/Keypoint/Warm-up + got-ideas + overlay
3. **Live & upload**: video bg + ambient audio + "Applying…" + `image_picker` upload

## Open items
- Truncated getter tail (`cbGroups`/`warmCardBg`/`kpScreenBg`/`surveyBtnBg`) — reconstruct from
  the change table; refetch handoff copy if exact values needed.
- Official preset/group/live data + per-preset overlays come from lynci later.
- Keypoint 3-dot menu location TBD (not in `lesson_page.dart` top level) — locate during Phase 2.
