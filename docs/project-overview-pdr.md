# Meup Project Overview & Product Development Requirements

**Version:** 1.0
**Last Updated:** 2026-01-13
**Project Type:** Mobile Language Learning Platform
**Platform:** Flutter (iOS + Android)
**Scale:** ~140K LOC across 13 feature modules

## Product Vision

Meup delivers an interactive, gamified language-learning platform focused on practical conversation skills through roleplay scenarios, interactive exercises, and AI-powered feedback. The app combines structured course progression with personalized learning experiences to maximize user engagement and learning outcomes.

## Target Users

### Primary Personas

**1. Young Professionals (25-35 years)**
- Goal: Career advancement through language skills
- Usage: 15-30 min daily during commute
- Motivation: Professional development, international opportunities
- Pain points: Limited time, need practical conversation skills

**2. Students (18-24 years)**
- Goal: Academic requirements + real-world fluency
- Usage: 30-60 min daily, typically evening
- Motivation: Exam preparation, study abroad preparation
- Pain points: Traditional methods boring, need interactive content

**3. Lifelong Learners (35-55 years)**
- Goal: Personal enrichment, travel preparation
- Usage: Flexible schedule, weekend focus
- Motivation: Cultural interest, travel confidence
- Pain points: Fear of speaking mistakes, need low-pressure environment

### User Needs
- Bite-sized lessons that fit busy schedules
- Real-world conversation practice
- Immediate feedback on pronunciation and grammar
- Visual progress tracking and achievement recognition
- Offline learning capability for commuters
- Multi-device synchronization

## Core Features

### 1. Authentication & User Management
**Module:** `auth`, `profile`
**Priority:** P0 (Critical)

**Capabilities:**
- Email/password authentication
- Social login (Google, Apple, Anonymous)
- Token-based session management with auto-refresh
- User profile with customizable settings
- Account deletion and data privacy controls

**Success Metrics:**
- 95% authentication success rate
- \<2s token refresh time
- Zero data leaks in security audits

### 2. Course Catalog & Learning Paths
**Module:** `course`, `progress`
**Priority:** P0 (Critical)

**Capabilities:**
- Multi-tab course browsing (All Courses, My Courses, Categories)
- Visual roadmap showing learning progression
- Course enrollment and tracking
- Lesson strength indicators (weak/medium/strong)
- Multi-level course structure (Course → Roadmap → Lessons → Keypoints → Exercises)

**Success Metrics:**
- 70% course completion rate for enrolled users
- Average 4+ lessons per session
- 80% user engagement with roadmap feature

### 3. Interactive Lesson System
**Module:** `lesson`
**Priority:** P0 (Critical)

**Capabilities:**
- 6 exercise types:
  - Theory/reading content with document viewer
  - Multiple choice questions
  - Drag-and-drop sentence building
  - Sequence arrangement
  - Pause mark (cues) placement
  - Stress word marking
  - Speaking exercises with voice recording
- Real-time voice feedback with waveform visualization
- Exercise result scoring with detailed feedback
- Progress tracking at keypoint and exercise levels
- Lottie animations for engagement

**Success Metrics:**
- 85% exercise completion rate
- Average score improvement 15% over 30 days
- Voice feedback latency \<3s

### 4. Roleplay Conversations
**Module:** `roleplay`
**Priority:** P1 (High)

**Capabilities:**
- Avatar-driven conversation scenarios
- Mission-based roleplay progression
- Real-time conversation feedback
- Contextual responses with transitions
- Scoring system for conversation quality

**Success Metrics:**
- 60% roleplay completion rate
- Average 3+ roleplay sessions per week for active users
- Positive feedback rating 80%+

### 5. Progress Tracking & Analytics
**Module:** `progress`, `achievement`
**Priority:** P1 (High)

**Capabilities:**
- Granular progress tracking (course → lesson → keypoint → exercise)
- Visual progress dashboard with charts
- Achievement system with badges
- Course-level progress indicators
- Recent courses tracking
- Learning streaks and milestones

**Success Metrics:**
- 90% data accuracy across all progress levels
- \<1s dashboard load time
- 50% users check progress weekly

### 6. In-App Purchases & Subscriptions
**Module:** `monetization`
**Priority:** P1 (High)

**Capabilities:**
- Multi-tier subscription plans
- Platform IAP integration (iOS/Android)
- Server-side purchase verification
- Transaction restoration
- Subscription management and renewal
- Premium feature gating

**Success Metrics:**
- 8-12% free-to-paid conversion
- \<1% failed transaction rate
- 70% subscription renewal rate (monthly)

### 7. Onboarding & Personalization
**Module:** `onboard`, `data_collect`
**Priority:** P1 (High)

**Capabilities:**
- Multi-step onboarding wizard
- Motivation and goal selection
- Age and skill level assessment
- Personalized course recommendations
- Notification permission handling
- First-time user experience optimization

**Success Metrics:**
- 80% onboarding completion rate
- \<60s onboarding duration
- 70% users engage with first recommended course

### 8. Settings & Preferences
**Module:** `setting`, `common`
**Priority:** P2 (Medium)

**Capabilities:**
- Language selection (English, Vietnamese, Chinese)
- Theme customization (light/dark mode)
- Notification preferences
- Account settings management
- App information and legal documents

**Success Metrics:**
- 95% preference persistence accuracy
- \<500ms settings page load time

### 9. Home & Navigation
**Module:** `home`
**Priority:** P2 (Medium)

**Capabilities:**
- Bottom navigation (Home, Course, Profile tabs)
- Skillset browsing and discovery
- Deep linking support
- Section-based content organization
- Quick access to recent courses

**Success Metrics:**
- \<200ms tab switch time
- 90% deep link resolution success
- 50% users access features via home shortcuts

## Technical Requirements

### Performance
- **Cold Start:** \<3s on mid-range devices (2020+)
- **API Response:** P95 \<500ms for course/lesson data
- **Voice Processing:** \<3s for feedback generation
- **Frame Rate:** Sustained 60fps during lessons
- **Memory:** \<200MB baseline, \<400MB peak during lessons

### Scalability
- Support 100K+ concurrent users
- Handle 1M+ course enrollments
- Process 500K+ daily lesson completions
- Store 10M+ exercise results

### Reliability
- **Uptime:** 99.9% availability
- **Error Rate:** \<0.1% for critical paths (auth, lesson loading)
- **Crash-Free Sessions:** 99.5%+
- **Data Loss:** Zero tolerance for user progress

### Security
- OAuth 2.0 + JWT for authentication
- Token refresh with 15-min access token TTL
- Encrypted local storage (flutter_secure_storage)
- HTTPS-only communication
- Server-side IAP receipt validation
- GDPR/CCPA compliance for data privacy

### Platform Support
- **iOS:** 12.0+ (deployment target)
- **Android:** API 21+ (min SDK), API 34 (target SDK)
- **Screen Sizes:** Phone-optimized, tablet responsive
- **Orientations:** Portrait primary, landscape adaptive
- **Offline Support:** Cached lessons, offline progress tracking

### Accessibility
- VoiceOver/TalkBack support for core flows
- Dynamic type/font scaling
- Color contrast WCAG AA compliant
- Touch target size ≥44x44pt

### Localization
- 3 languages: English (base), Vietnamese, Chinese
- RTL layout support (future)
- Number/date formatting per locale
- Google Sheets-based translation workflow

## Integration Requirements

### Third-Party Services

**Firebase Suite:**
- Authentication (email, Google, Apple)
- Cloud Messaging (push notifications)
- Crashlytics (error tracking)
- Analytics (user behavior)
- Remote Config (feature flags)
- App Distribution (beta testing)

**Analytics & Tracking:**
- Firebase Analytics (primary)
- Sentry (error monitoring)
- Facebook App Events (attribution)
- TikTok Events (marketing)

**Monetization:**
- In-App Purchase (iOS/Android native)
- Play Store Billing
- App Store StoreKit

**Backend APIs:**
- REST API (Dio + Retrofit)
- GraphQL API (graphql_flutter)
- AI Service API (voice feedback, streaming)

### Platform Permissions
- **Camera:** Profile photo upload, future AR features
- **Microphone:** Speaking exercises
- **Notifications:** Engagement reminders, streak notifications
- **Network:** Data sync, API communication
- **Storage:** Offline content, cache management

## Success Metrics & KPIs

### Engagement Metrics
- **DAU/MAU Ratio:** Target 30%+
- **Session Duration:** Average 20+ minutes
- **Sessions per Week:** 4+ for active users
- **Retention:**
  - D1: 60%+
  - D7: 40%+
  - D30: 25%+

### Learning Metrics
- **Course Completion:** 70%+ for enrolled courses
- **Lesson Completion:** 85%+ per started lesson
- **Exercise Accuracy:** 70%+ average score
- **Voice Exercise Engagement:** 60%+ completion rate

### Monetization Metrics
- **Free-to-Paid Conversion:** 8-12%
- **ARPU (Monthly):** Target based on pricing tiers
- **Subscription Renewal:** 70%+ (monthly), 80%+ (annual)
- **Churn Rate:** \<5% monthly

### Quality Metrics
- **Crash-Free Rate:** 99.5%+
- **API Success Rate:** 99.9%+
- **Load Time P95:** \<2s for critical screens
- **User-Reported Bugs:** \<10 per 1000 DAU

## Development Constraints

### Technical Debt
- Migrate legacy UseCase handlers (`executeUseCase` → `runUseCase`)
- Consolidate deprecated `DText` widget to `AppText`
- Optimize large files in `lesson` module (\>200 LOC)
- Complete GraphQL schema documentation

### Resource Constraints
- Mobile team: 3-5 engineers
- Backend team: 2-3 engineers
- QA: 1-2 testers
- Release cycle: Bi-weekly sprints

### Compliance
- App Store Review Guidelines
- Google Play Store policies
- COPPA (if targeting users \<13)
- GDPR data protection requirements

## Roadmap & Milestones

### Phase 1: MVP (Completed)
- Core authentication flow
- Course catalog and enrollment
- 6 exercise types implementation
- Basic progress tracking
- iOS/Android builds

### Phase 2: Enhancement (Current)
- Roleplay system expansion
- Advanced analytics dashboard
- Subscription optimization
- Performance improvements
- Localization expansion

### Phase 3: Growth (Q1-Q2 2026)
- Social features (friend progress, leaderboards)
- Live tutoring integration
- AR pronunciation guidance
- Tablet-optimized UI
- Web platform support

### Phase 4: Scale (Q3-Q4 2026)
- AI-powered personalization
- Multi-language course expansion
- Enterprise/education partnerships
- Offline-first architecture
- Advanced speech recognition

## Risk Assessment

### High-Priority Risks

**1. Voice Feedback Performance**
- Risk: AI service latency affects user experience
- Mitigation: Caching, streaming responses, fallback mechanisms
- Owner: Backend + Mobile teams

**2. Monetization Optimization**
- Risk: Low conversion rates impact revenue
- Mitigation: A/B testing, paywall optimization, value prop clarity
- Owner: Product + Growth teams

**3. User Retention Drop**
- Risk: Post-onboarding engagement decline
- Mitigation: Push notifications, streak gamification, content variety
- Owner: Product + Analytics teams

**4. Platform-Specific Bugs**
- Risk: iOS/Android parity issues
- Mitigation: Platform-specific testing, device coverage
- Owner: QA + Mobile teams

### Medium-Priority Risks

**5. Backend Scalability**
- Risk: Traffic spikes degrade performance
- Mitigation: Load testing, auto-scaling, CDN caching
- Owner: Backend + DevOps teams

**6. Third-Party Service Outages**
- Risk: Firebase/Sentry downtime affects app
- Mitigation: Graceful degradation, offline modes
- Owner: Mobile + Backend teams

## Acceptance Criteria

### Feature Completeness
- All P0/P1 features implemented and tested
- Edge cases handled (network errors, auth failures)
- Accessibility compliance verified
- Localization complete for 3 languages

### Quality Gates
- Zero P0 bugs in production
- \<5 P1 bugs per release
- 80%+ unit test coverage for business logic
- 60%+ integration test coverage for critical flows

### Performance Benchmarks
- All performance targets met on reference devices
- Memory leaks resolved
- Battery consumption optimized

### User Acceptance
- Beta tester NPS ≥8/10
- App store rating target 4.5+/5
- Support ticket rate \<1% of DAU

## Appendix

### Glossary
- **Keypoint:** Learning objective within a lesson
- **Roadmap:** Visual course progression map
- **Roleplay:** Interactive conversation scenario
- **Skillset:** Group of related courses
- **Exercise:** Single interactive learning activity
- **Flavor:** Build variant (dev, stg, prod)

### Related Documentation
- `docs/system-architecture.md` - Technical architecture details
- `docs/code-standards.md` - Development guidelines
- `docs/codebase-summary.md` - Codebase overview
- `CLAUDE.md` - AI assistant instructions
