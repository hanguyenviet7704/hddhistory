import ActivityKit
import Foundation

// Shared between the Runner app target (starts/updates/ends the Activity) and
// MeupHomeWidgetsExtension (renders it) — must carry Target Membership in BOTH.
@available(iOS 16.2, *)
struct MeupLessonActivityAttributes: ActivityAttributes {
  // Fixed for the lifetime of the Activity — set once at start(). All display
  // copy is localized on the Dart side (slang, 5 locales) and passed in, so the
  // widget itself holds no hardcoded, English-only strings. Locale-only labels
  // that don't change with progress live here; done/progress-dependent copy is
  // in ContentState so it re-localizes on each update().
  let courseId: String
  let courseName: String
  let courseImagePath: String
  let inLessonLabel: String
  let continueLearningLabel: String

  struct ContentState: Codable, Hashable {
    var progress: Double // 0...1
    var isDone: Bool
    var resumeLabel: String // "Resume lesson" / "Next lesson"
    var primaryNudge: String // lock-screen footer: "~3 min to finish…" / "Tap to start…"
    var footerNudge: String // Dynamic Island footer: "~3 min to finish…" / "Course complete"

    /// Keypoint the card should reopen, or nil/empty when the card belongs to
    /// the roadmap rather than an open lesson. Lives here, not in the fixed
    /// attributes, because the target moves as the reader advances through a
    /// course while one card stays alive.
    ///
    /// Optional on purpose: a card started by an older build has no such key,
    /// and a synthesized `Codable` would fail to decode a non-optional one.
    var keypointId: String?
  }
}
