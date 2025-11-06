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
import UserProgressList from "../pages/user-progress/UserProgressList";
import TheoryList from "../pages/theories/TheoryList";
import EntranceList from "../pages/entrances/EntranceList";
import EntranceCreate from "../pages/entrances/EntranceCreate";
import EntranceDetail from "../pages/entrances/EntranceDetail";
import OutputList from "../pages/output/OutputList";
import OutputCreate from "../pages/output/OutputCreate";
import OutputDetail from "../pages/output/OutputDetail";
import TheoryDocumentList from "../pages/theories/TheoryDetail";
import TheoryCreate from "../pages/theories/TheoryCreate";
import ExerciseList from "../pages/exercises/ExerciseList";
import ExerciseCreate from "../pages/exercises/ExerciseCreate";
import ExerciseDetail from "../pages/exercises/ExerciseDetail";
import OnboardingManagement from "../pages/onboardings/OnboardingManagemant";
import KeypointDetail from "../pages/keypoints/KeypointDetail";
import SettingsPage from "../pages/setting/Setting";
import SkillsetList from "../pages/skillsets/skillsetList";
import RoleplayList from "../pages/roleplays/RoleplayList";
import RoleplayDetail from "../pages/roleplays/RoleplayDetail";
import RoleplayCreate from "../pages/roleplays/RoleplayCreate";

export default function AppRouter() {
  return (
    <BrowserRouter>
      <Provider store={store}>
        <Routes>
          {/* Public route */}
          <Route path="/login" element={<LoginPage />} />

          {/* Protected routes */}
          <Route element={<ProtectedRoute />}>
            <Route path="/" element={<Layout />}>
              {/* Redirect from "/" to "/course" */}
              <Route index element={<Navigate to="/course" replace />} />

              <Route path="skillset" element={<SkillsetList />} />

              <Route path="course" element={<CourseList />} />
              <Route path="course/:courseId" element={<CourseDetail />} />

              <Route path="lesson" element={<LessonList />} />
              <Route path="lesson/create" element={<LessonCreate />} />
              <Route path="lesson/:lessonId" element={<LessonDetail />} />

              <Route path="entrance" element={<EntranceList />} />
              <Route path="entrance/create" element={<EntranceCreate />} />
              <Route path="entrance/:lessonId" element={<EntranceDetail />} />

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
              <Route path="roleplay/:roleplayId" element={<RoleplayDetail />} />
              <Route path="roleplay/create" element={<RoleplayCreate />} />

              <Route path="onboarding" element={<OnboardingManagement />} />

              <Route path="progress" element={<UserProgressList />} />

              <Route path="settings" element={<SettingsPage />} />
            </Route>
          </Route>
        </Routes>
      </Provider>
    </BrowserRouter>
  );
}
