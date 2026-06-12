import Foundation
import SwiftUI
import WidgetKit

enum MeupWidgetType {
  case inProgress
  case streak
  case suggestCourse

  var kind: String {
    switch self {
    case .inProgress: "MeupInProgressWidget"
    case .streak: "MeupStreakWidget"
    case .suggestCourse: "MeupSuggestCourseWidget"
    }
  }

  var payloadKey: String {
    switch self {
    case .inProgress: "meup_home_widget_in_progress_v1"
    case .streak: "meup_home_widget_streak_v1"
    case .suggestCourse: "meup_home_widget_suggest_course_v1"
    }
  }

  var defaultTitle: String {
    switch self {
    case .inProgress: "Pick a course and stay in the loop"
    case .streak: "Start your streak today"
    case .suggestCourse: "You crushed every course!"
    }
  }

  var fallbackImageName: String {
    switch self {
    case .inProgress: "meup_widget_book"
    case .streak: "meup_widget_flame_star"
    case .suggestCourse: "meup_widget_certificate"
    }
  }

  var fallbackImageKey: String {
    switch self {
    case .inProgress: "meup_home_widget_book_asset"
    case .streak: "meup_home_widget_flame_asset"
    case .suggestCourse: "meup_home_widget_certificate_asset"
    }
  }

  var defaultDeeplink: String {
    switch self {
    case .inProgress: "meup://home?source=home_widget&widgetType=in_progress_course"
    case .streak: "meup://course-roadmap?source=home_widget&widgetType=weekly_streak"
    case .suggestCourse: "meup://home?source=home_widget&widgetType=suggest_course"
    }
  }
}

struct MeupWidgetPayload {
  let state: String
  let deeplink: String
  let data: [String: Any]

  var isReady: Bool { state == "ready" }

  func string(_ key: String, fallback: String = "") -> String {
    (data[key] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? fallback
  }

  func title(for type: MeupWidgetType, defaults: MeupWidgetTextDefaults) -> String {
    if !isReady {
      switch type {
      case .inProgress: return defaults.inProgressEmptyTitle
      case .streak: return type.defaultTitle
      case .suggestCourse: return defaults.suggestExhaustedTitle
      }
    }

    let value = string("title", fallback: type.defaultTitle)
    if type == .suggestCourse && legacySuggestLabels.contains(value) {
      return defaults.suggestExhaustedTitle
    }
    return value
  }

  func int(_ key: String, fallback: Int = 0) -> Int {
    if let value = data[key] as? Int { return value }
    if let value = data[key] as? NSNumber { return value.intValue }
    return fallback
  }

  func double(_ key: String, fallback: Double = 0) -> Double {
    if let value = data[key] as? Double { return value }
    if let value = data[key] as? NSNumber { return value.doubleValue }
    return fallback
  }

  func boolArray(_ key: String, size: Int) -> [Bool] {
    var values = (data[key] as? [Bool]) ?? []
    while values.count < size { values.append(false) }
    return Array(values.prefix(size))
  }

  func stringArray(_ key: String, fallback: [String], size: Int) -> [String] {
    var values = (data[key] as? [String]) ?? fallback
    while values.count < size { values.append(fallback[safe: values.count] ?? "") }
    return Array(values.prefix(size))
  }

}

struct MeupWidgetEntry: TimelineEntry {
  let date: Date
  let type: MeupWidgetType
  let payload: MeupWidgetPayload
}

struct MeupWidgetProvider: TimelineProvider {
  let type: MeupWidgetType

  func placeholder(in context: Context) -> MeupWidgetEntry {
    MeupWidgetEntry(date: Date(), type: type, payload: fallbackPayload())
  }

  func getSnapshot(in context: Context, completion: @escaping (MeupWidgetEntry) -> Void) {
    completion(MeupWidgetEntry(date: Date(), type: type, payload: readPayload()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<MeupWidgetEntry>) -> Void) {
    completion(Timeline(entries: [MeupWidgetEntry(date: Date(), type: type, payload: readPayload())], policy: .atEnd))
  }

  private func readPayload() -> MeupWidgetPayload {
    guard let rawPayload = widgetDefaults.string(forKey: type.payloadKey),
      let data = rawPayload.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return fallbackPayload() }

    return MeupWidgetPayload(
      state: (json["state"] as? String) ?? "empty",
      deeplink: (json["deeplink"] as? String) ?? type.defaultDeeplink,
      data: (json["data"] as? [String: Any]) ?? [:]
    )
  }

  private func fallbackPayload() -> MeupWidgetPayload {
    let localeCode = currentWidgetLocaleCode
    let defaults = MeupWidgetTextDefaults.forLocale(localeCode)
    let state = type == .suggestCourse ? "exhausted" : "empty"
    let title: String
    switch type {
    case .inProgress:
      title = defaults.inProgressEmptyTitle
    case .streak:
      title = type.defaultTitle
    case .suggestCourse:
      title = defaults.suggestExhaustedTitle
    }
    var data: [String: Any] = ["localeCode": localeCode, "title": title, "staticAssetKey": type.fallbackImageKey]
    if type == .suggestCourse {
      data["subtitle"] = defaults.suggestExhaustedSubtitle
    }
    if type == .streak {
      data["currentStreak"] = 0
      data["countText"] = defaults.streakCountText(0)
      data["subtitle"] = defaults.streakEmptySubtitle
      data["weekStudy"] = Array(repeating: false, count: 7)
      data["weekLabels"] = defaults.weekLabels
    }
    return MeupWidgetPayload(
      state: state,
      deeplink: type.defaultDeeplink,
      data: data
    )
  }
}

let widgetDefaults = UserDefaults(suiteName: currentWidgetAppGroup) ?? .standard

var currentWidgetAppGroup: String {
  let bundleId = Bundle.main.bundleIdentifier ?? ""
  if bundleId.hasPrefix("com.eup.meup.dev") { return "group.com.eup.meup.dev.homewidget" }
  if bundleId.hasPrefix("com.eup.meup.stg") { return "group.com.eup.meup.stg.homewidget" }
  return "group.com.eup.meup.homewidget"
}

extension String {
  var nonEmpty: String? { isEmpty ? nil : self }
}
