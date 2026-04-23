# Meup Project Overview & Product Development Requirements

**Last Updated:** 2026-04-22
**Project Type:** Flutter mobile application  
**Status:** Active development

## 1. Product Summary
Meup is a language-learning app focused on structured lessons, roadmap-driven read/listen lesson entry, first-slice video-lesson entry/completion flow, output-practice conversation flows, roleplay practice, daily streak continuity, and progress visibility.
The product combines course content, interactive exercise formats, AI-assisted speaking/roleplay feedback, learning-streak surfaces, and subscription features.

## 2. Scope and Users
### Primary user groups
- Self-paced learners improving daily communication.
- Learners preparing for study/work communication.
- Returning users tracking learning continuity and milestones.

### Core user journeys
1. Onboarding and account setup.
2. Course discovery and roadmap lesson entry.
3. Output-practice intro sheet and conversation launch from course output lessons.
4. Video-lesson intro sheet, mounted player shell, and completion handoff from roadmap lessons.
5. Exercise completion and feedback review.
6. Roleplay practice and performance feedback.
7. Progress and profile review.
8. Subscription purchase and management.
9. Scenario-branching onboarding handoff and recommendation-based course entry.
10. Daily streak check/commit from home and lesson-completion moments.

## 3. Current Module Scope (Code-Verified)
`lib/src` currently contains 18 feature modules:

| Module | Primary responsibility |
| --- | --- |
| `achievenment` | Achievement listing and detail flows |
| `auth` | Login/register/session lifecycle |
| `common` | Shared page state and common screens |
| `course` | Course listing, roadmap, course lesson views |
| `data_collect` | Onboarding survey and profile intake steps |
| `feedback` | User feedback submission/view |
| `home` | Skillset and dashboard entry |
| `learning_streak` | Home streak popup and completion streak success overlays |
| `lesson` | Learning-item and exercise flows |
| `monetization` | Paywall, products, purchase verification |
| `onboard` | Intro/onboarding screens |
| `onboard_branching` | Branching onboarding scenario module |
| `output_practice` | Course-shell output practice conversation flow, intro sheet, socket room, and retryable history |
| `profile` | User profile and upload flows |
| `progress` | User progress, course and achievement progress |
| `roleplay` | Roleplay flow and AI feedback integration |
| `setting` | Language/theme/settings screens |
| `video_lesson` | Course-shell video lesson intro sheet, mounted player shell, notes/summary/share overlays, timed-question flow, end/completion, and tracking |

Notes:
- Naming intentionally follows code paths, including `achievenment`.
- `feedback`, `learning_streak`, `onboard_branching`, and `video_lesson` are part of the current module map.

## 4. Functional Requirements
1. Authentication and session handling
- Support credential and provider-based login paths.
- Support anonymous/guest entry path.
- Handle refresh/logout/delete-account flows.

2. Course and lesson delivery
- Retrieve paginated course and lesson data.
- Support learning item sequencing and item detail retrieval.
- Allow navigation between lesson-related pages using typed routes, including the course-shell output-practice route, the video-lesson route, and the single lesson route with read/listen entry mode.
- Resolve roadmap lesson popup CTAs between read-only and read/listen states before navigation based on usable keypoint audio availability.

3. Output-practice conversation flow
- Open output lessons through an intro sheet, then navigate into the typed `output-practice/:sectionId` route.
- Fetch an existing conversation first, create one when needed, and load history scoped to the current conversation id.
- Join or rejoin the socket room, reconcile optimistic sends with canonical messages, and expose retry actions for history, room join, and failed message resend.
- Emit dedicated tracking events for popup view, popup close, start click, screen view, option click, send click, and exit click.

4. Video-lesson course-shell flow
- Resolve roadmap `openingVideo` / `closingVideo` lessons to a unique `nodeId`.
- Show a tracked intro sheet before playback starts.
- Keep the player shell mounted through play/pause, seek, notes, summary, question, result, exit, and end/completion states.
- Support scoped notes CRUD with session-local draft restore while the route stays open.
- Support summary and share actions from the paused player shell.
- Support crossed-time timed questions with backward re-arm, forward queue drain, unsupported fallback, and local result state.
- Persist completion through progress update and refresh roadmap state after success.
- Run the shared completion streak gate after progress success and before auto-exit; fail open on streak timeout/failure/non-positive response.

5. Exercise and speaking experience
- Render multiple exercise types via typed payloads.
- Support speaking/voice feedback endpoints.
- Persist progress updates for lesson/keypoint/exercise outcomes.

6. Roleplay learning flow
- Run roleplay sequence and capture roleplay feedback.
- Surface roleplay feedback breakdown in UI.

7. Progress tracking
- Retrieve user progress and paginated “my courses” data.
- Show achievement/course-level progress status.
- Show streak progress from home and completion-triggered success overlays.

8. Profile and settings
- Retrieve/update user profile.
- Upload files through cloudflare upload endpoint.
- Manage locale and theme preferences.

9. Monetization
- Load purchasable packages.
- Verify purchases with backend.
- Retrieve active subscription status.

10. Localization
- Pull and push localization via script wrappers.
- Regenerate localization code after localization sync.

11. Branching onboarding orchestration
- Allow remote-config flow switching between normal and branching onboarding.
- Preserve deep-link precedence over onboarding.
- Enforce deterministic fallback from malformed branching scenario data to normal onboarding.
- Prevent forced register redirects during active onboarding branching transition.

## 5. Non-Functional Requirements
1. Architecture consistency
- Maintain `presentation -> domain -> data` flow for feature work.
- Keep transport/network types inside data layer.

2. Reliability and resilience
- Use `TaskEither<AppException, T>` for recoverable failures.
- Keep standardized request handlers for transform/list/pagebreak calls.

3. Security
- Do not commit credentials/signing files.
- Keep release obfuscation and symbol workflows enabled in build scripts/CI.

4. Maintainability
- Keep generated files regenerated via tooling, not manual edits.
- Keep docs in sync with module count, runtime constraints, and script contracts.

5. Observability
- Preserve app-level error tracking and analytics service integrations.
- Keep the shipped video-lesson slice scoped to entry, playback shell, and completion; do not imply notes/summary/share/timed-question are complete until their slices land.

## 6. Technical Constraints (Code-Verified)
- Dart SDK: `>=3.11.0 <4.0.0` (`pubspec.yaml`).
- iOS minimum deployment target: `15.0` (`ios/Podfile`).
- Android minimum SDK: configured via `flutter.minSdkVersion` in `android/app/build.gradle.kts`.
- Flavors: `dev`, `stg`, `prod` with entrypoints `lib/main_<flavor>.dart`.

## 7. API and Data Contract Requirements
- Paginated requests use `PageBreakRequest` with fields:
  - app-side: `page`, `limit`, `orderBy`, `order`, `search`, `filter`
  - serialized query keys: `page`, `take`, `orderBy`, `order`, `search`
- Paginated responses use `BasePageBreak<T>` with:
  - `totalPages`, `currentPage`, `itemsPerPage`, `items`

## 8. Delivery Acceptance Criteria
1. A feature is complete when:
- It follows module layer boundaries.
- It exposes/consumes existing typed entities/use cases.
- It includes success/failure handling through `TaskEither` path.
- It updates docs if module behavior or operational contract changes.

2. A release candidate is complete when:
- `flutter analyze` and `flutter test` pass in CI.
- Required generated artifacts are refreshed.
- Build and distribution jobs satisfy CI variable contract.

## 9. Success Metrics (Product + Engineering)
- Stable CI completion for prepare/quality/build stages.
- No undocumented drift in runtime constraints (SDK/platform/flavor).
- No unresolved contract mismatch between scripts and deployment docs.
- Measurable learning-flow coverage across course, lesson, roleplay, learning_streak, and progress modules.

## 10. Requirement Version Notes
| Date | Change |
| --- | --- |
| 2026-04-13 | Added dual-mode lesson requirements for roadmap popup branching, single-route read/listen entry, route-session audio playback, shared completion handoff, and no-audio fallback behavior. |
| 2026-04-08 | Added first-slice video-lesson course-shell requirements (roadmap entry, intro sheet, player shell, completion handoff, and tracking) and synced module scope to 18 modules. |
| 2026-03-30 | Added output-practice course-shell flow (typed route, intro sheet, scoped history, socket retry/reconcile, tracking) and synced module scope to 17 modules. |
| 2026-03-05 | Added learning streak module scope and requirements (home streak popup + completion-triggered streak success gate). |
| 2026-03-02 | Added branching onboarding orchestration requirements (flow switch, fallback safety, no-register gate in transition). |
| 2026-02-27 | Removed branch/ticket-specific labels; synced module scope to 15 modules; synced SDK/iOS constraints; refreshed pagination and build contract references. |
