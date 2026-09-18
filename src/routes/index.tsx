import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { Provider } from "react-redux";
import Layout from "../components/layout/Layout";
import LoginPage from "../pages/users/LoginPage";
import CourseList from "../pages/courses/CourseList";
import LessonList from "../pages/lessons/LessonList";
import ProtectedRoute from "./ProtectedRoute";
import { store } from "../store";
import LessonDetail from "../pages/lessons/LessonDetail";
import LessonCreate from "../pages/lessons/LessonCreate";
import CourseDetail from "../pages/courses/CourseDetail";
import KeypointList from "../pages/keypoints/KeypointList";
import UserProgressSummaryList from "../pages/user-progress/UserProgressSummaryList";
import UserProgressDetail from "../pages/user-progress/UserProgressDetail";
import CourseDropOffPage from "../pages/user-progress/CourseDropOffPage";
import TheoryList from "../pages/theories/TheoryList";
import RoleplayList from "../pages/roleplays/RoleplayList";
import RoleplayCreate from "../pages/roleplays/RoleplayCreate";
import RoleplayDetail from "../pages/roleplays/RoleplayDetail";
import OutputList from "../pages/output/OutputList";
import OutputCreate from "../pages/output/OutputCreate";
import OutputDetail from "../pages/output/OutputDetail";
import TheoryDocumentList from "../pages/theories/TheoryDetail";
import TheoryCreate from "../pages/theories/TheoryCreate";
import ExerciseList from "../pages/exercises/ExerciseList";
import ExerciseCreate from "../pages/exercises/ExerciseCreate";
import ExerciseDetail from "../pages/exercises/ExerciseDetail";
import OnboardingManagement from "../pages/onboardings/OnboardingManagemant";
import OnboardingManagemantScenarioBranching from "../pages/onboardings/OnboardingManagemantScenarioBranching";
import KeypointDetail from "../pages/keypoints/KeypointDetail";
import SettingsPage from "../pages/setting/Setting";
import SkillsetList from "../pages/skillsets/skillsetList";
import HabitList from "../pages/habits/HabitList";
import HabitCheckinList from "../pages/habit-checkins/HabitCheckinList";
import HabitCheckinDetail from "../pages/habit-checkins/HabitCheckinDetail";
import LearningImportList from "../pages/learning-imports/LearningImportList";
import LearningImportDetail from "../pages/learning-imports/LearningImportDetail";
import DownloadLinkList from "../pages/download-links/DownloadLinkList";
import DeeplinkGenerator from "../pages/deeplinks/DeeplinkGenerator";
import StreakConfigPage from "../pages/streak-config/StreakConfigPage";
import CoachConfigPage from "../pages/coach/CoachConfigPage";
import CoachSituationList from "../pages/coach/CoachSituationList";
import CoachRatingList from "../pages/coach/CoachRatingList";
import CoachContentList from "../pages/coach/CoachContentList";
import CoachUserThread from "../pages/coach/CoachUserThread";
import AdminAuditPage from "../pages/admin-audit/AdminAuditPage";
import CoachAiUsagePage from "../pages/coach/CoachAiUsagePage";
import CoachStatsPage from "../pages/coach/CoachStatsPage";
import CollectionsPage from "../pages/collections/CollectionsPage";
import HomeBannerPage from "../pages/home-banner/HomeBannerPage";
import HomePopupPage from "../pages/home-popup/HomePopupPage";
import CommunityChatGuidePage from "../pages/community/CommunityChatGuidePage";
import CommunityModerationPage from "../pages/community/CommunityModerationPage";
import CommunityRoomSuggestionList from "../pages/community/CommunityRoomSuggestionList";
import CommunitySanctionList from "../pages/community/CommunitySanctionList";
import CommunityOfficialProfilePage from "../pages/community/CommunityOfficialProfilePage";
import CommunityTopicList from "../pages/community/CommunityTopicList";
import CommunityWeeklyPage from "../pages/community/CommunityWeeklyPage";
import ReanchorReasonList from "../pages/reanchor-reasons/ReanchorReasonList";
import PaymentDashboard from "../pages/payments/PaymentDashboard";
import StatisticsPage from "../pages/statistics/Statistics";
import DashboardOverview from "../pages/dashboard/DashboardOverview";
import DashboardUsers from "../pages/dashboard/DashboardUsers";
import DashboardSessions from "../pages/dashboard/DashboardSessions";
import DashboardOnboarding from "../pages/dashboard/DashboardOnboarding";
import DashboardLearning from "../pages/dashboard/DashboardLearning";
import VideoList from "../pages/video/VideoList";
import VideoCreate from "../pages/video/VideoCreate";
import VideoDetail from "../pages/video/VideoDetail";
import DriveUploadPage from "../pages/drive-upload/DriveUploadPage";
import CourseImportJobDetail from "../pages/imports/CourseImportJobDetail";
import ReportList from "../pages/reports/ReportList";
import LessonFeedbackAnalytics from "../pages/lesson-feedback/LessonFeedbackAnalytics";
import ImageCompressionPage from "../pages/image-compression/ImageCompressionPage";
import VoiceoverBatch from "../pages/voiceover/VoiceoverBatch";
import StudyThemeList from "../pages/study-themes/StudyThemeList";
import OnboardingConfigPage from "../pages/onboarding-config/OnboardingConfigPage";
import OnboardingTaxonomyPage from "../pages/onboarding-taxonomy/OnboardingTaxonomyPage";
import ResetOnboardingPage from "../pages/users/ResetOnboardingPage";
import NotificationsPage from "../pages/notifications/NotificationsPage";
import PaywallConfigPage from "../pages/paywall-config/PaywallConfigPage";
import SegmentsPage from "../pages/segments/SegmentsPage";
import ContentExperimentsPage from "../pages/content-experiments/ContentExperimentsPage";
import VersionComparisonPage from "../pages/version-comparison/VersionComparisonPage";

export default function AppRouter() {
  return (
    <BrowserRouter>
      <Provider store={store}>
        <Routes>
          {/* Public route */}
          <Route path="/login" element={<LoginPage />} />

          {/* Protected routes */}
          <Route element={<ProtectedRoute />}>
            <Route path="/drive-upload" element={<DriveUploadPage />} />

            <Route path="/" element={<Layout />}>
              {/* Redirect from "/" to "/course" */}
              <Route index element={<Navigate to="/course" replace />} />

              {/* Product dashboard — one route per sidebar entry, so each page
                  fetches only the numbers it shows. */}
              <Route path="dashboard" element={<DashboardOverview />} />
              <Route path="dashboard/users" element={<DashboardUsers />} />
              <Route path="dashboard/sessions" element={<DashboardSessions />} />
              <Route
                path="dashboard/onboarding"
                element={<DashboardOnboarding />}
              />
              <Route path="dashboard/learning" element={<DashboardLearning />} />
              <Route path="dashboard/drop-off" element={<CourseDropOffPage />} />

              <Route path="skillset" element={<SkillsetList />} />

              <Route path="habits" element={<HabitList />} />

              <Route path="habit-checkins" element={<HabitCheckinList />} />
              <Route
                path="habit-checkins/user/:userId"
                element={<HabitCheckinDetail />}
              />

              <Route path="learning-imports" element={<LearningImportList />} />
              <Route
                path="learning-imports/:jobId"
                element={<LearningImportDetail />}
              />

              <Route
                path="reanchor-reasons"
                element={<ReanchorReasonList />}
              />

              <Route path="study-themes" element={<StudyThemeList />} />
              <Route path="download-links" element={<DownloadLinkList />} />
              <Route path="deeplinks" element={<DeeplinkGenerator />} />
              <Route path="streak-config" element={<StreakConfigPage />} />
              <Route path="coach-config" element={<CoachConfigPage />} />
              <Route path="coach-situations" element={<CoachSituationList />} />
              <Route path="coach-ratings" element={<CoachRatingList />} />
              <Route path="coach-contents" element={<CoachContentList />} />
              <Route
                path="coach-contents/users/:userId"
                element={<CoachUserThread />}
              />
              <Route path="coach-stats" element={<CoachStatsPage />} />
              <Route
                path="content-experiments"
                element={<ContentExperimentsPage />}
              />
              <Route
                path="version-comparison"
                element={<VersionComparisonPage />}
              />
              <Route path="coach-ai-usage" element={<CoachAiUsagePage />} />
              <Route path="admin-audit" element={<AdminAuditPage />} />
              <Route path="collections" element={<CollectionsPage />} />
              <Route path="home-banner" element={<HomeBannerPage />} />
              <Route path="home-popup" element={<HomePopupPage />} />
              <Route path="segments" element={<SegmentsPage />} />

              <Route
                path="community/moderation"
                element={<CommunityModerationPage />}
              />
              <Route path="community/topics" element={<CommunityTopicList />} />
              <Route
                path="community/official-profile"
                element={<CommunityOfficialProfilePage />}
              />
              <Route
                path="community/room-suggestions"
                element={<CommunityRoomSuggestionList />}
              />
              <Route path="community/weekly" element={<CommunityWeeklyPage />} />
              <Route
                path="community/sanctions"
                element={<CommunitySanctionList />}
              />
              <Route
                path="community/chat-guide"
                element={<CommunityChatGuidePage />}
              />

              <Route path="course" element={<CourseList />} />
              <Route path="course/:courseId" element={<CourseDetail />} />

              <Route path="lesson" element={<LessonList />} />
              <Route path="lesson/create" element={<LessonCreate />} />
              <Route path="lesson/:lessonId" element={<LessonDetail />} />

              <Route path="video" element={<VideoList />} />
              <Route path="video/create" element={<VideoCreate />} />
              <Route path="video/:videoId" element={<VideoDetail />} />

              <Route path="output" element={<OutputList />} />
              <Route path="output/create" element={<OutputCreate />} />
              <Route path="output/:lessonId" element={<OutputDetail />} />

              <Route path="keypoint" element={<KeypointList />} />
              <Route path="keypoint/:keypointId" element={<KeypointDetail />} />

              <Route path="theory" element={<TheoryList />} />
              <Route path="theory/:theoryId" element={<TheoryDocumentList />} />
              <Route path="theory/create" element={<TheoryCreate />} />

              <Route path="exercise" element={<ExerciseList />} />
              <Route path="exercise/:exerciseId" element={<ExerciseDetail />} />
              <Route path="exercise/create" element={<ExerciseCreate />} />

              <Route path="roleplay" element={<RoleplayList />} />
              <Route path="roleplay/create" element={<RoleplayCreate />} />
              <Route path="roleplay/:lessonId" element={<RoleplayDetail />} />

              <Route path="onboarding" element={<OnboardingManagement />} />
              <Route
                path="onboarding-branching"
                element={<OnboardingManagemantScenarioBranching />}
              />
              <Route
                path="onboarding-config"
                element={<OnboardingConfigPage />}
              />
              <Route
                path="onboarding-taxonomy"
                element={<OnboardingTaxonomyPage />}
              />

              <Route
                path="progress/user/:userId"
                element={<UserProgressSummaryList />}
              />
              <Route
                path="progress/user/:userId/course/:courseId"
                element={<UserProgressDetail />}
              />

              <Route path="reports" element={<ReportList />} />
              <Route path="lesson-feedback" element={<LessonFeedbackAnalytics />} />

              <Route
                path="image-compression"
                element={<ImageCompressionPage />}
              />

              <Route
                path="reset-onboarding"
                element={<ResetOnboardingPage />}
              />

              <Route path="settings" element={<SettingsPage />} />

              <Route path="statistics" element={<StatisticsPage />} />

              <Route path="payment" element={<PaymentDashboard />} />
              <Route path="paywall-config" element={<PaywallConfigPage />} />
              <Route path="notifications" element={<NotificationsPage />} />
              <Route path="voiceover" element={<VoiceoverBatch />} />
              <Route
                path="course-import-jobs/:jobId"
                element={<CourseImportJobDetail />}
              />
            </Route>
          </Route>
        </Routes>
      </Provider>
    </BrowserRouter>
  );
}
