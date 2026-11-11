import Foundation
import SwiftUI
import WidgetKit

enum HDDhistoryWidgetType {
  case inProgress
  case streak
  case suggestCourse

  var kind: String {
    switch self {
    case .inProgress: "HDDhistoryInProgressWidget"
    case .streak: "HDDhistoryStreakWidget"
    case .suggestCourse: "HDDhistorySuggestCourseWidget"
    }
  }

  var payloadKey: String {
    switch self {
    case .inProgress: "hddhistory_home_widget_in_progress_v1"
    case .streak: "hddhistory_home_widget_streak_v1"
    case .suggestCourse: "hddhistory_home_widget_suggest_course_v1"
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
    case .inProgress: "hddhistory_widget_book"
    case .streak: "hddhistory_widget_flame_star"
    case .suggestCourse: "hddhistory_widget_certificate"
    }
  }

  var fallbackImageKey: String {
    switch self {
    case .inProgress: "hddhistory_home_widget_book_asset"
    case .streak: "hddhistory_home_widget_flame_asset"
    case .suggestCourse: "hddhistory_home_widget_certificate_asset"
    }
  }

  var defaultDeeplink: String {
    switch self {
    case .inProgress: "hddhistory://home?source=home_widget&widgetType=in_progress_course"
    case .streak: "hddhistory://course-roadmap?source=home_widget&widgetType=weekly_streak"
    case .suggestCourse: "hddhistory://home?source=home_widget&widgetType=suggest_course"
    }
  }
}

struct HDDhistoryWidgetPayload {
  let state: String
  let deeplink: String
  let data: [String: Any]

  var isReady: Bool { state == "ready" }

  func string(_ key: String, fallback: String = "") -> String {
    (data[key] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? fallback
  }

  func title(for type: HDDhistoryWidgetType) -> String {
    let value = string("title", fallback: type.defaultTitle)
    if type == .suggestCourse && !isReady && legacySuggestLabels.contains(value) {
      return type.defaultTitle
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

  private var legacySuggestLabels: Set<String> {
    [
      "Today's suggestion",
      "Gợi ý hôm nay",
      "今日推荐",
      "今日のおすすめ",
      "오늘의 추천",
    ]
  }
}

struct HDDhistoryWidgetEntry: TimelineEntry {
  let date: Date
  let type: HDDhistoryWidgetType
  let payload: HDDhistoryWidgetPayload
}

struct HDDhistoryWidgetProvider: TimelineProvider {
  let type: HDDhistoryWidgetType

  func placeholder(in context: Context) -> HDDhistoryWidgetEntry {
    HDDhistoryWidgetEntry(date: Date(), type: type, payload: fallbackPayload())
  }

  func getSnapshot(in context: Context, completion: @escaping (HDDhistoryWidgetEntry) -> Void) {
    completion(HDDhistoryWidgetEntry(date: Date(), type: type, payload: readPayload()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<HDDhistoryWidgetEntry>) -> Void) {
    completion(Timeline(entries: [HDDhistoryWidgetEntry(date: Date(), type: type, payload: readPayload())], policy: .atEnd))
  }

  private func readPayload() -> HDDhistoryWidgetPayload {
    guard let rawPayload = widgetDefaults.string(forKey: type.payloadKey),
      let data = rawPayload.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return fallbackPayload() }

    return HDDhistoryWidgetPayload(
      state: (json["state"] as? String) ?? "empty",
      deeplink: (json["deeplink"] as? String) ?? type.defaultDeeplink,
      data: (json["data"] as? [String: Any]) ?? [:]
    )
  }

  private func fallbackPayload() -> HDDhistoryWidgetPayload {
    let state = type == .suggestCourse ? "exhausted" : "empty"
    var data: [String: Any] = ["title": type.defaultTitle, "staticAssetKey": type.fallbackImageKey]
    if type == .suggestCourse {
      data["subtitle"] = "More coming soon!"
    }
    if type == .streak {
      data["currentStreak"] = 0
      data["countText"] = "0 days"
      data["subtitle"] = type.defaultTitle
      data["weekStudy"] = Array(repeating: false, count: 7)
      data["weekLabels"] = ["M", "T", "W", "T", "F", "S", "S"]
    }
    return HDDhistoryWidgetPayload(
      state: state,
      deeplink: type.defaultDeeplink,
      data: data
    )
  }
}

let widgetDefaults = UserDefaults(suiteName: currentWidgetAppGroup) ?? .standard

var currentWidgetAppGroup: String {
  let bundleId = Bundle.main.bundleIdentifier ?? ""
  if bundleId.hasPrefix("com.hddhistory.app.dev") { return "group.com.hddhistory.app.dev.homewidget" }
  if bundleId.hasPrefix("com.hddhistory.app.stg") { return "group.com.hddhistory.app.stg.homewidget" }
  return "group.com.hddhistory.app.homewidget"
}

extension String {
  var nonEmpty: String? { isEmpty ? nil : self }
}
