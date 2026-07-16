import ActivityKit
import Flutter
import UIKit

// Bridges Dart (LessonCubit) to ActivityKit. Activity.request()/.update()/.end()
// must run in the main app process — the widget extension can only RENDER an
// Activity, not start one — hence this lives in Runner, not
// MeupHomeWidgetsExtension. Only one lesson can be open at a time, so a single
// tracked Activity is sufficient (no keyed registry).
final class LiveActivityChannel {
  static let channelName = "meup/live_activity"

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

    // A lesson start while another is already live (shouldn't normally happen —
    // only one lesson can be open at once — but cheap to guard) replaces it
    // rather than stacking two Activities.
    endCurrentActivity(dismissImmediately: true)

    let attributes = MeupLessonActivityAttributes(
      courseId: courseId,
      courseName: args["courseName"] as? String ?? "",
      courseImagePath: args["courseImagePath"] as? String ?? "",
      inLessonLabel: args["inLessonLabel"] as? String ?? "",
      continueLearningLabel: args["continueLearningLabel"] as? String ?? ""
    )
    let state = contentState(from: args)

    do {
      let activity = try Activity<MeupLessonActivityAttributes>.request(
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
    guard let activity = Activity<MeupLessonActivityAttributes>.activities.first(where: { $0.id == currentActivityId }) else {
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
    endCurrentActivity(dismissImmediately: false)
    result(nil)
  }

  @available(iOS 16.2, *)
  private func endCurrentActivity(dismissImmediately: Bool) {
    guard let activity = Activity<MeupLessonActivityAttributes>.activities.first(where: { $0.id == currentActivityId }) else { return }
    currentActivityId = nil
    let policy: ActivityUIDismissalPolicy = dismissImmediately ? .immediate : .after(.now + 4)
    Task {
      await activity.end(activity.content, dismissalPolicy: policy)
    }
  }

  @available(iOS 16.2, *)
  private func contentState(from args: [String: Any]) -> MeupLessonActivityAttributes.ContentState {
    MeupLessonActivityAttributes.ContentState(
      progress: args["progress"] as? Double ?? 0,
      isDone: args["isDone"] as? Bool ?? false,
      resumeLabel: args["resumeLabel"] as? String ?? "",
      primaryNudge: args["primaryNudge"] as? String ?? "",
      footerNudge: args["footerNudge"] as? String ?? ""
    )
  }
}
