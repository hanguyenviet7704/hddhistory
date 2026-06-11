import SwiftUI
import WidgetKit

@main
struct MeupHomeWidgets: WidgetBundle {
  var body: some Widget {
    MeupInProgressWidget()
    MeupStreakWidget()
    MeupSuggestCourseWidget()
  }
}

struct MeupInProgressWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: MeupWidgetType.inProgress.kind, provider: MeupWidgetProvider(type: .inProgress)) { entry in
      MeupHomeWidgetView(entry: entry)
    }
    .configurationDisplayName("Continue course")
    .description("Shows your active Meup course.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct MeupStreakWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: MeupWidgetType.streak.kind, provider: MeupWidgetProvider(type: .streak)) { entry in
      MeupHomeWidgetView(entry: entry)
    }
    .configurationDisplayName("Weekly streak")
    .description("Shows your weekly Meup learning streak.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct MeupSuggestCourseWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: MeupWidgetType.suggestCourse.kind, provider: MeupWidgetProvider(type: .suggestCourse)) { entry in
      MeupHomeWidgetView(entry: entry)
    }
    .configurationDisplayName("Course suggestion")
    .description("Shows today's suggested Meup course.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
