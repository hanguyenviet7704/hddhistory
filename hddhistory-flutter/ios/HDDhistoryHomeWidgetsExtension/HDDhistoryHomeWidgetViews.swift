import SwiftUI
import WidgetKit

struct HDDhistoryHomeWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: HDDhistoryWidgetEntry

  var body: some View {
    Group {
      switch entry.type {
      case .inProgress:
        CourseWidgetView(entry: entry, isSmall: family == .systemSmall)
      case .streak:
        StreakWidgetView(entry: entry, isSmall: family == .systemSmall)
      case .suggestCourse:
        CourseWidgetView(entry: entry, isSmall: family == .systemSmall)
      }
    }
    .widgetURL(URL(string: entry.payload.deeplink))
    .unredacted()
    .hddhistoryWidgetBackground(isReady: entry.payload.isReady)
  }
}
