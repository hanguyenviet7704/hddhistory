// Result of a daily warm-up auto-tagging run. Mirrors the meup-api
// DailyWarmUpTaggingResultDto returned by both the preview and apply endpoints.
export interface DailyWarmUpTaggingResult {
  // Total lessons examined across the whole catalog.
  lessonsScanned: number;
  // Exercise folders (LearningItems) whose questions actually change.
  foldersChanged: number;
  // Questions currently untagged that will be / were set to isDailyWarmUp=true.
  questionsToTickOn: number;
  // Questions currently tagged that will be / were set to isDailyWarmUp=false.
  questionsToTickOff: number;
}
