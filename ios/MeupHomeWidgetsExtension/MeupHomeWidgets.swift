import SwiftUI
import WidgetKit

@main
struct MeupHomeWidgets: WidgetBundle {
  var body: some Widget {
    MeupInProgressWidget()
    MeupStreakWidget()
    MeupSuggestCourseWidget()
    if #available(iOS 16.2, *) {
      MeupLessonLiveActivity()
    }
  }
}

struct MeupInProgressWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: MeupWidgetType.inProgress.kind, provider: MeupWidgetProvider(type: .inProgress)) { entry in
      MeupHomeWidgetView(entry: entry)
    }
    .configurationDisplayName("Continue course")
    .description("Your next lesson is ready when you are.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct MeupStreakWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: MeupWidgetType.streak.kind, provider: MeupWidgetProvider(type: .streak)) { entry in
      MeupHomeWidgetView(entry: entry)
    }
    .configurationDisplayName("Daily Streak")
    .description("Every day you learn counts. Keep it going!")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct MeupSuggestCourseWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: MeupWidgetType.suggestCourse.kind, provider: MeupWidgetProvider(type: .suggestCourse)) { entry in
      MeupHomeWidgetView(entry: entry)
    }
    .configurationDisplayName("Today's Course")
    .description("A new pick for you, every day.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
