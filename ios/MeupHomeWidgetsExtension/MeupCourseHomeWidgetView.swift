import SwiftUI

struct CourseWidgetView: View {
  let entry: MeupWidgetEntry
  let isSmall: Bool

  var body: some View {
    if isSmall {
      SmallCourseWidgetView(entry: entry)
    } else {
      MediumCourseWidgetView(entry: entry)
    }
  }
}

private struct MediumCourseWidgetView: View {
  let entry: MeupWidgetEntry

  var body: some View {
    HStack(alignment: .center, spacing: 20) {
      WidgetImageView(type: entry.type, payload: entry.payload, size: imageSize)
      VStack(alignment: .leading, spacing: 5) {
        if entry.type == .suggestCourse {
          SuggestLabel(text: entry.payload.string("label", fallback: "Today's suggestion"), fontSize: 12)
          Text(entry.payload.isReady ? mainText : title)
            .widgetTitle(fontSize: 16, lineLimit: 3)
          if !entry.payload.isReady {
            Text(entry.payload.string("subtitle", fallback: "More coming soon!"))
              .widgetCaption(fontSize: 12, lineLimit: 1)
          }
        } else {
          if entry.payload.isReady {
            CourseProgressRow(payload: entry.payload, barWidth: 76, fontSize: 12)
              .padding(.bottom, 3)
          }
          Text(title)
            .widgetTitle(fontSize: entry.payload.isReady ? 20 : 18, lineLimit: 2)
        }
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 14)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }

  private var title: String { entry.payload.string("title", fallback: entry.type.defaultTitle) }
  private var mainText: String { entry.payload.string("description", fallback: entry.payload.string("subtitle", fallback: title)) }
  private var imageSize: CGFloat { entry.type == .suggestCourse && !entry.payload.isReady ? 92 : 96 }
}

private struct SmallCourseWidgetView: View {
  let entry: MeupWidgetEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      WidgetImageView(type: entry.type, payload: entry.payload, size: imageSize)
      if entry.type == .suggestCourse {
        SuggestLabel(text: entry.payload.string("label", fallback: "Today's suggestion"), fontSize: 9)
        Text(entry.payload.isReady ? mainText : title)
          .widgetTitle(fontSize: 12, lineLimit: entry.payload.isReady ? 3 : 2)
        if !entry.payload.isReady {
          Text(entry.payload.string("subtitle", fallback: "More coming soon!"))
            .widgetCaption(fontSize: 10, lineLimit: 1)
        }
      } else {
        if entry.payload.isReady {
          CourseProgressRow(payload: entry.payload, barWidth: 48, fontSize: 11)
        }
        Text(title)
          .widgetTitle(fontSize: entry.payload.isReady ? 14 : 13, lineLimit: 3)
      }
      Spacer(minLength: 0)
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  private var title: String { entry.payload.string("title", fallback: entry.type.defaultTitle) }
  private var mainText: String { entry.payload.string("description", fallback: entry.payload.string("subtitle", fallback: title)) }
  private var imageSize: CGFloat { entry.type == .suggestCourse && !entry.payload.isReady ? 70 : 52 }
}

private struct CourseProgressRow: View {
  let payload: MeupWidgetPayload
  let barWidth: CGFloat
  let fontSize: CGFloat

  var body: some View {
    let completed = payload.int("completedLessons")
    let total = payload.int("totalLessons")
    if total > 0 {
      HStack(spacing: 8) {
        ProgressSegments(completed: completed, total: total, width: barWidth)
        Text("\(completed)/\(total) lesson")
          .font(.system(size: fontSize, weight: .medium))
          .foregroundStyle(WidgetColor.muted)
          .lineLimit(1)
          .minimumScaleFactor(0.75)
      }
    }
  }
}
