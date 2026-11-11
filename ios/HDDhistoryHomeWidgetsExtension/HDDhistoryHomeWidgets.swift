import SwiftUI
import WidgetKit

@main
struct HDDhistoryHomeWidgets: WidgetBundle {
  var body: some Widget {
    HDDhistoryInProgressWidget()
    HDDhistoryStreakWidget()
    HDDhistorySuggestCourseWidget()
    if #available(iOS 16.2, *) {
      HDDhistoryLessonLiveActivity()
    }
  }
}

struct HDDhistoryInProgressWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: HDDhistoryWidgetType.inProgress.kind, provider: HDDhistoryWidgetProvider(type: .inProgress)) { entry in
      HDDhistoryHomeWidgetView(entry: entry)
    }
    .configurationDisplayName("Continue course")
    .description("Your next lesson is ready when you are.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct HDDhistoryStreakWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: HDDhistoryWidgetType.streak.kind, provider: HDDhistoryWidgetProvider(type: .streak)) { entry in
      HDDhistoryHomeWidgetView(entry: entry)
    }
    .configurationDisplayName("Daily Streak")
    .description("Every day you learn counts. Keep it going!")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct HDDhistorySuggestCourseWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: HDDhistoryWidgetType.suggestCourse.kind, provider: HDDhistoryWidgetProvider(type: .suggestCourse)) { entry in
      HDDhistoryHomeWidgetView(entry: entry)
    }
    .configurationDisplayName("Today's Course")
    .description("A new pick for you, every day.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
