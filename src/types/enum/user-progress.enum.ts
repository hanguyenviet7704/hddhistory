export enum GradeResultType {
  COURSE = "course",
  LESSON = "lesson",
  KEYPOINT = "keypoint",
  EXERCISE = "exercise",
}

export enum ProcessEnum {
  DONE = "done",
  IN_PROGRESS = "in_progress",
  NOT_STARTED = "not_started",
}

export enum UserProgressExportStatus {
  PENDING = "pending",
  PROCESSING = "processing",
  COMPLETED = "completed",
  FAILED = "failed",
}

export enum StatisticsUsersLearningCoursesOrderBy {
  STARTED_USER_COUNT = "startedUserCount",
  ROLEPLAY_KEYPOINT_PASSED_COUNT = "roleplayKeypointPassedCount",
  LESSON_KEYPOINT_PASSED_COUNT = "lessonKeypointPassedCount",
  COMPLETED_USER_COUNT = "completedUserCount",
}
