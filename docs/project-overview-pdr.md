# Meup: Project Overview & Product Development Requirements

**Last Updated:** Feb 10, 2026
**Project:** Meup Flutter Mobile Application
**Status:** Active Development (feature/MEUP-637)

---

## 1. Product Vision

**Meup** is an intelligent, interactive language-learning mobile application designed to make language acquisition engaging, personalized, and effective through AI-driven conversational practice combined with structured exercises.

**Mission:** Empower learners globally to master new languages through adaptive exercises, real-world conversational roleplay, and progress tracking.

---

## 2. Target Users & Use Cases

### Primary User Segments
| Segment | Profile | Use Case |
|---------|---------|----------|
| **Self-Learners** | Adults (18-45) learning for career/travel | Complete courses at own pace with daily practice |
| **Career Professionals** | Non-native speakers improving work communication | Focused roleplay scenarios (business meetings, presentations) |
| **Students** | Secondary/tertiary students | Structured courses aligned with curricula |
| **Casual Learners** | Hobby language enthusiasts | Explore skillsets, achieve badges, gamified progress |

### Core Learning Journeys
1. **Onboarding Flow:** Motivation questions → Language selection → Skills assessment → Goal setting
2. **Daily Practice:** Select course → Theory → Exercises (choice, drag-drop, speaking) → Roleplay scenarios
3. **Progress Tracking:** View course roadmap → Keypoint milestones → Achievement badges → Subscription insights
4. **Social/Competitive:** Optional sharing, leaderboards, achievement visibility in profile

---

## 3. Key Features & Modules

### Core Learning Features
| Feature | Module | Purpose |
|---------|--------|---------|
| **Course Catalog** | `course` | Browse, enroll, roadmap visualization |
| **Interactive Lessons** | `lesson` | Theory content + 8 exercise types (choice, drag-drop, cues, stress, speaking, sequence, etc.) |
| **AI Roleplay** | `roleplay` | Contextual dialogue with ML feedback (grammar, pronunciation, vocabulary) |
| **Progress Dashboard** | `progress` | Course completion %, keypoint mastery, achievement badges |
| **User Profile** | `profile` | Profile editing, avatar upload, subscription status, achievements |

### Gamification & Engagement
| Feature | Module | Purpose |
|---------|--------|---------|
| **Keypoints** | `lesson` | Sub-lesson learning objectives with mastery tracking |
| **Achievements** | `achievement` | Badges for milestones (course completion, speed records) |
| **Subscriptions** | `monetization` | Premium tiers, paywall, in-app purchase management |
| **User Settings** | `setting` | Theme, language (EN/VI/ZH), notification preferences |

### Platform Features
| Feature | Purpose |
|---------|---------|
| **Multi-Language UI** | English, Vietnamese, Chinese (Google Sheets workflow) |
| **Analytics** | Firebase, Sentry, custom event tracking |
| **Push Notifications** | AwesomeNotifications, Firebase Cloud Messaging |
| **Deep Linking** | App/web URL navigation, universal links |
| **Offline Readiness** | Cached content, local storage fallback |

---

## 4. Technical Architecture Overview

### Architectural Pattern: Clean Architecture + BLoC
```
Presentation (Pages, Widgets, Cubits)
    ↓
Domain (Entities, Repositories, Use Cases)
    ↓
Data (APIs, Local Storage, Models)
```

### Technology Stack
| Layer | Technology |
|-------|-----------|
| **UI Framework** | Flutter 3.24.0 (Dart 3.10.0) |
| **State Management** | BLoC/Cubit with flutter_bloc 9.1.1 |
| **Networking** | Retrofit + Dio (REST), graphql_flutter (GraphQL) |
| **Persistence** | Firebase, SharedPreferences, HydratedBloc |
| **Error Handling** | fpdart TaskEither (functional programming) |
| **DI Container** | GetIt + injectable |
| **Navigation** | go_router with type-safe code generation |
| **Localization** | slang_flutter with Google Sheets integration |
| **Analytics** | Firebase Analytics, Sentry, custom tracking |
| **Backend Auth** | Firebase Auth, optional Supabase |

### Platform Support
- **Android:** minSdk 21, targetSdk 34, APK + App Bundle distributions
- **iOS:** iOS 12+, IPA via Xcode, StoreKit in-app purchases
- **Environments:** dev, stg, prod with environment-specific configs

---

## 5. Functional Requirements

### F1: User Onboarding & Authentication
- Email/password registration and login
- OAuth login (Google, Apple)
- Anonymous guest mode
- OTP-based 2FA
- Password recovery flow

### F2: Course Management
- Browse paginated course catalog (with filtering by skillset)
- View course details, roadmap visualization, lesson list
- Track course progress (completion %, current lesson)
- Enroll/unenroll from courses

### F3: Interactive Lessons
- Display theory content (text, video, audio)
- Support 8+ exercise types with strongly-typed payloads:
  - Single/multiple choice with optional answer explanation
  - Single choice (no correct answer) with document review
  - Drag-and-drop sentence building
  - Pronunciation cue placement
  - Word stress marking
  - Speaking (voice recording + ML evaluation)
  - Sequence arrangement
  - Gap-filling, custom exercises
- Submit answers with immediate feedback & detailed explanation
- Lesson review with timeline navigation
- Track exercise results, retry capability
- Graceful handling of unsupported question types

### F4: AI-Driven Roleplay
- Engage in dialogue scenarios with contextual narrative
- Receive ML-scored feedback (grammar, pronunciation, vocabulary)
- Embedded exercises within roleplay dialogue
- Voice recording in roleplay sessions

### F5: Progress & Achievements
- Dashboard showing enrolled courses with completion %
- Keypoint milestones and mastery levels
- Achievement badges for course/skill completion
- Progress history and statistics

### F6: User Profile & Settings
- Edit profile (name, email, avatar, age, gender, language, country)
- Manage subscription status
- View achievements and badges
- Change language, theme, notification preferences
- Account deletion

### F7: Monetization
- Display paywall with subscription tiers
- In-app purchase integration (StoreKit iOS, Google Play Android)
- Receipt verification via backend
- Purchase history and restore functionality

### F8: Analytics & Tracking
- Screen view tracking and session analytics
- 170+ comprehensive event tracking categorized by user journey:
  - Onboarding (motivation questions, goal setting, language selection)
  - Course selection (browsing, enrollment, category filtering)
  - Lesson/keypoint (theory view, exercise type interactions, results)
  - Roleplay (dialogue engagement, feedback, performance scoring)
  - Progress (completion %, milestone achievements)
  - Premium/paywall (viewing, package selection, purchase events)
- Error/exception logging to Crashlytics and Sentry
- Automatic parameter enrichment (course, lesson, skill context)

---

## 6. Non-Functional Requirements

### NFR1: Performance
- Lesson load time: < 2s
- Exercise result submission: < 3s
- Page navigation: < 500ms
- Minimize app startup time with lazy initialization

### NFR2: Reliability
- Graceful offline handling with cache fallback
- Retry logic for network requests (exponential backoff)
- Error boundary pages for critical failures
- Automatic error reporting to Sentry

### NFR3: Security
- HTTPS/TLS for all API communication
- Token-based authentication (JWT)
- Secure local storage for auth tokens
- Obfuscation enabled in release builds
- Data encryption for sensitive user information

### NFR4: Scalability
- Support 100K+ concurrent users
- Pagination for large datasets (courses, lessons, exercises)
- Efficient state management to prevent memory leaks
- Async/await patterns for long-running operations

### NFR5: Maintainability
- Code generation for boilerplate (freezed, retrofit, injectable)
- Consistent Clean Architecture across all modules
- Comprehensive error type definitions
- Modular feature-based code organization

### NFR6: Localization
- Support 3+ languages (EN, VI, ZH)
- No hardcoded strings in code
- Dynamic language switching without app restart
- Right-to-left (RTL) support consideration

### NFR7: Testing
- Unit test coverage for use cases and repositories
- Widget tests for critical UI components
- Integration tests for key user journeys
- Mock services for offline testing

---

## 7. System Constraints & Dependencies

### Constraints
- Minimum Flutter SDK: 3.24.0
- Dart SDK: 3.10.0+
- Requires internet for initial setup, feature flags, ML evaluation
- Firebase project required for production
- Apple/Google developer accounts for app store deployment

### External Dependencies
| Service | Purpose | Status |
|---------|---------|--------|
| Firebase | Auth, Analytics, Crashlytics, Remote Config | Required |
| Google Cloud Speech-to-Text | Voice recording evaluation | Required |
| Google Sheets API | Localization master data | Required |
| Supabase (Optional) | Alternative backend | Optional |
| Facebook Analytics | Event tracking | Optional |
| TikTok Analytics | Cross-promotion tracking | Optional |
| Sentry | Error tracking | Optional |

### Platform Constraints
- iOS: StoreKit 2 for in-app purchases
- Android: Google Play Billing Library v7+
- Both platforms require app store account for distribution

---

## 8. Success Metrics & KPIs

### User Engagement
- Daily Active Users (DAU)
- Session length (target: 15-20 min)
- Course completion rate (target: > 60%)
- Lesson pass rate on first attempt (target: > 70%)

### Retention
- 7-day retention rate (target: > 40%)
- 30-day retention rate (target: > 25%)
- Churn rate (target: < 5% monthly)

### Monetization
- Conversion to paid (target: 5-10% of new users)
- Average revenue per user (ARPU)
- Subscription lifetime value
- In-app purchase acceptance rate

### Quality
- Crash-free session rate (target: > 99%)
- API error rate (target: < 0.5%)
- User error reports (target: < 100/week)

### Adoption
- App store rating (target: > 4.5 stars)
- Install-to-first-lesson ratio (target: > 80%)
- Feature adoption (roleplay: > 50% of active users)

---

## 9. Roadmap & Phases

### Phase 1: MVP Launch (Current)
- Core auth, course catalog, basic exercises
- User profile and progress tracking
- Basic analytics and error tracking
- iOS + Android build pipeline

### Phase 2: Engagement (Next)
- AI roleplay with voice feedback
- Achievement system and gamification
- Subscription model and paywall
- Advanced analytics dashboard

### Phase 3: Scale (Future)
- Community features (forums, leaderboards)
- Adaptive course recommendations
- Teacher/admin dashboard
- Content marketplace

### Phase 4: Expansion (Long-term)
- Additional languages and courses
- B2B licensing model
- Offline-first mobile experience
- Desktop/web companion apps

---

## 10. Module Dependencies & Integration

### Module Dependency Graph
```
common (global state)
    ↓
auth (authentication)
    ↓
profile (user info)
    ↓
course → lesson → roleplay
    ↓
progress → achievement
    ↓
monetization
    ↓
setting (theme, language)
```

### Cross-Module Integrations
- **Auth** → All modules require authenticated user context
- **Monetization** → Integrates with Profile (subscription status)
- **Progress** → Aggregates lesson, roleplay, keypoint results
- **Common** → Provides global theme, locale, connectivity states
- **Setting** → Theme/locale persist via HydratedCubit

---

## 11. Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| API downtime → Poor UX | Medium | High | Offline cache, error graceful handling |
| Voice recognition latency | Medium | Medium | Timeout limits, fallback text input |
| Mobile platform policy changes | Medium | Medium | Proactive OS version updates, sandbox testing |
| User churn due to difficulty | High | High | Adaptive difficulty, suggestion system |
| Data privacy compliance | Low | Critical | Regular GDPR/CCPA audits, clear policies |

---

## 12. Success Criteria & Definition of Done

### Feature Complete When:
✓ All use cases implemented and tested
✓ UI matches design specifications
✓ Error handling covers edge cases
✓ Performance benchmarks met (< 3s for user actions)
✓ Analytics events captured
✓ Documentation updated
✓ Code review approved
✓ Integration tests passing
✓ Deployed to staging environment

### Release Ready When:
✓ Feature complete + QA verified
✓ Crash-free rate > 99%
✓ No critical bugs
✓ Performance profiled
✓ Security audit passed
✓ Deployment checklist completed

---

**Document Maintained By:** Documentation Team
**Last Review:** Feb 10, 2026
**Next Review Date:** Mar 22, 2026
