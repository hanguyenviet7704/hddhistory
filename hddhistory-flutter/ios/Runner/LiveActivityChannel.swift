import ActivityKit
import Flutter
import UIKit

// Bridges Dart (LessonCubit) to ActivityKit. Activity.request()/.update()/.end()
// must run in the main app process — the widget extension can only RENDER an
// Activity, not start one — hence this lives in Runner, not
// HDDhistoryHomeWidgetsExtension. Only one lesson can be open at a time, so a single
// tracked Activity is sufficient (no keyed registry).
final class LiveActivityChannel {
  static let channelName = "hddhistory/live_activity"

  private var currentActivityId: String?

  init(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard #available(iOS 16.2, *) else {
      result(FlutterError(code: "unsupported_os", message: "Live Activities require iOS 16.2+", details: nil))
      return
    }

    switch call.method {
    case "start":
      start(call.arguments as? [String: Any], result: result)
    case "update":
      update(call.arguments as? [String: Any], result: result)
    case "end":
      end(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @available(iOS 16.2, *)
  private func start(_ args: [String: Any]?, result: @escaping FlutterResult) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      result(FlutterError(code: "not_authorized", message: "User has disabled Live Activities", details: nil))
      return
    }
    guard let args,
      let courseId = args["courseId"] as? String, !courseId.isEmpty
    else {
      result(FlutterError(code: "invalid_args", message: "courseId is required", details: nil))
      return
    }

    // Only one lesson can be open at a time, so at most one of our Live
    // Activities should ever exist. End EVERY existing one before requesting a
    // new card — not just the id we tracked in memory. That in-memory id is
    // lost when the app is relaunched (or force-quit), so the previous
    // session's Activity stays alive on the Lock Screen and a fresh start
    // would stack a second card next to it. Ending them all here collapses any
    // such orphan back to a single card.
    endAllActivities(dismissImmediately: true)

    let attributes = HDDhistoryLessonActivityAttributes(
      courseId: courseId,
      courseName: args["courseName"] as? String ?? "",
      courseImagePath: args["courseImagePath"] as? String ?? "",
      inLessonLabel: args["inLessonLabel"] as? String ?? "",
      continueLearningLabel: args["continueLearningLabel"] as? String ?? ""
    )
    let state = contentState(from: args)

    do {
      let activity = try Activity<HDDhistoryLessonActivityAttributes>.request(
        attributes: attributes,
        content: ActivityContent(state: state, staleDate: nil),
        pushType: nil
      )
      currentActivityId = activity.id
      result(nil)
    } catch {
      result(FlutterError(code: "start_failed", message: error.localizedDescription, details: nil))
    }
  }

  @available(iOS 16.2, *)
  private func update(_ args: [String: Any]?, result: @escaping FlutterResult) {
    guard let args else {
      result(FlutterError(code: "invalid_args", message: "content state is required", details: nil))
      return
    }
    guard let activity = Activity<HDDhistoryLessonActivityAttributes>.activities.first(where: { $0.id == currentActivityId }) else {
      // Nothing running (e.g. app relaunched and lost the in-memory id) — a
      // silent no-op is correct here, not an error worth surfacing to Dart.
      result(nil)
      return
    }
    Task {
      await activity.update(ActivityContent(state: contentState(from: args), staleDate: nil))
      result(nil)
    }
  }

  @available(iOS 16.2, *)
  private func end(result: @escaping FlutterResult) {
    endAllActivities(dismissImmediately: false)
    result(nil)
  }

  /// Ends every live lesson Activity, not just `currentActivityId`. Because the
  /// tracked id doesn't survive an app relaunch, an orphaned card from a prior
  /// session would otherwise never be torn down — so both start and end sweep
  /// the full `activities` list to keep the invariant of at most one card.
  @available(iOS 16.2, *)
  private func endAllActivities(dismissImmediately: Bool) {
    currentActivityId = nil
    let activities = Activity<HDDhistoryLessonActivityAttributes>.activities
    guard !activities.isEmpty else { return }
    let policy: ActivityUIDismissalPolicy = dismissImmediately ? .immediate : .after(.now + 4)
    Task {
      for activity in activities {
        await activity.end(activity.content, dismissalPolicy: policy)
      }
    }
  }

  @available(iOS 16.2, *)
  private func contentState(from args: [String: Any]) -> HDDhistoryLessonActivityAttributes.ContentState {
    HDDhistoryLessonActivityAttributes.ContentState(
      progress: args["progress"] as? Double ?? 0,
      isDone: args["isDone"] as? Bool ?? false,
      resumeLabel: args["resumeLabel"] as? String ?? "",
      primaryNudge: args["primaryNudge"] as? String ?? "",
      footerNudge: args["footerNudge"] as? String ?? "",
      // Empty (roadmap card) is normalized to nil so the widget's deeplink
      // builder has a single "no keypoint" case to test.
      keypointId: (args["keypointId"] as? String).flatMap { $0.isEmpty ? nil : $0 }
    )
  }
}
