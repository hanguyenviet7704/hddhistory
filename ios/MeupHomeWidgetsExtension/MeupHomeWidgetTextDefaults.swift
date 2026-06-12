import Foundation

let widgetLocaleCodeKey = "meup_home_widget_locale_code"

let legacySuggestLabels: Set<String> = [
  "Today's suggestion",
  "Gợi ý hôm nay",
  "今日推荐",
  "今日のおすすめ",
  "오늘의 추천",
]

var storedWidgetLocaleCode: String? {
  widgetDefaults.string(forKey: widgetLocaleCodeKey)?
    .trimmingCharacters(in: .whitespacesAndNewlines)
    .nonEmpty
}

var currentWidgetLocaleCode: String {
  storedWidgetLocaleCode ?? "en"
}

struct MeupWidgetTextDefaults {
  let inProgressEmptyTitle: String
  let streakActiveSubtitle: String
  let streakEmptySubtitle: String
  let suggestLabel: String
  let suggestExhaustedTitle: String
  let suggestExhaustedSubtitle: String
  let weekLabels: [String]
  let streakCountSingularTemplate: String
  let streakCountPluralTemplate: String

  static func forLocale(_ localeCode: String) -> MeupWidgetTextDefaults {
    switch normalizedWidgetLanguageCode(localeCode) {
    case "vi":
      return MeupWidgetTextDefaults(
        inProgressEmptyTitle: "Chọn khóa học để bắt đầu",
        streakActiveSubtitle: "Tiếp tục nhé!",
        streakEmptySubtitle: "Bắt đầu chuỗi hôm nay",
        suggestLabel: "Gợi ý hôm nay",
        suggestExhaustedTitle: "Bạn đã hoàn thành mọi khóa học!",
        suggestExhaustedSubtitle: "Sắp có thêm!",
        weekLabels: ["T2", "T3", "T4", "T5", "T6", "T7", "CN"],
        streakCountSingularTemplate: "{count} ngày",
        streakCountPluralTemplate: "{count} ngày"
      )
    case "zh":
      return MeupWidgetTextDefaults(
        inProgressEmptyTitle: "选择课程，继续学习",
        streakActiveSubtitle: "继续加油！",
        streakEmptySubtitle: "今天开始连续学习",
        suggestLabel: "今日推荐",
        suggestExhaustedTitle: "你已完成所有课程！",
        suggestExhaustedSubtitle: "更多内容即将推出！",
        weekLabels: ["周一", "周二", "周三", "周四", "周五", "周六", "周日"],
        streakCountSingularTemplate: "{count} 天",
        streakCountPluralTemplate: "{count} 天"
      )
    case "ja":
      return MeupWidgetTextDefaults(
        inProgressEmptyTitle: "コースを選んで学習を続けよう",
        streakActiveSubtitle: "その調子！",
        streakEmptySubtitle: "今日から連続記録を始めよう",
        suggestLabel: "今日のおすすめ",
        suggestExhaustedTitle: "すべてのコースを完了しました！",
        suggestExhaustedSubtitle: "近日追加予定！",
        weekLabels: ["月", "火", "水", "木", "金", "土", "日"],
        streakCountSingularTemplate: "{count} 日",
        streakCountPluralTemplate: "{count} 日"
      )
    case "ko":
      return MeupWidgetTextDefaults(
        inProgressEmptyTitle: "코스를 골라 학습을 이어가세요",
        streakActiveSubtitle: "잘하고 있어요!",
        streakEmptySubtitle: "오늘 연속 학습을 시작하세요",
        suggestLabel: "오늘의 추천",
        suggestExhaustedTitle: "모든 코스를 완료했어요!",
        suggestExhaustedSubtitle: "곧 더 추가돼요!",
        weekLabels: ["월", "화", "수", "목", "금", "토", "일"],
        streakCountSingularTemplate: "{count}일",
        streakCountPluralTemplate: "{count}일"
      )
    default:
      return MeupWidgetTextDefaults(
        inProgressEmptyTitle: "Pick a course and stay in the loop",
        streakActiveSubtitle: "Keep going!",
        streakEmptySubtitle: "Start your streak today",
        suggestLabel: "Today's suggestion",
        suggestExhaustedTitle: "You crushed every course!",
        suggestExhaustedSubtitle: "More coming soon!",
        weekLabels: ["M", "T", "W", "T", "F", "S", "S"],
        streakCountSingularTemplate: "{count} day",
        streakCountPluralTemplate: "{count} days"
      )
    }
  }

  func streakCountText(_ count: Int) -> String {
    let template = count == 1 ? streakCountSingularTemplate : streakCountPluralTemplate
    return template.replacingOccurrences(of: "{count}", with: "\(count)")
  }
}

func normalizedWidgetLanguageCode(_ localeCode: String) -> String {
  localeCode
    .trimmingCharacters(in: .whitespacesAndNewlines)
    .split { $0 == "-" || $0 == "_" }
    .first
    .map(String.init)?
    .lowercased() ?? "en"
}

extension MeupWidgetPayload {
  func localizedString(_ translationsKey: String, localeCode: String, fallback: String) -> String {
    guard let translations = data[translationsKey] as? [String: Any] else { return fallback }
    for key in [normalizedWidgetLanguageCode(localeCode), "en", "text"] {
      if let value = (translations[key] as? String)?
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .nonEmpty {
        return value
      }
    }
    return fallback
  }
}
