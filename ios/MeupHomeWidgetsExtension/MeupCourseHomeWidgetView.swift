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
    HStack(alignment: .center, spacing: 24) {
      WidgetImageView(type: entry.type, payload: entry.payload, width: imageWidth, height: imageHeight)
      VStack(alignment: .leading, spacing: 5) {
        if entry.type == .suggestCourse {
          if entry.payload.isReady {
            SuggestLabel(text: textDefaults.suggestLabel, fontSize: 12)
          }
          Text(entry.payload.isReady ? mainText : title)
            .widgetTitle(fontSize: 16, lineLimit: 3)
          if !entry.payload.isReady {
            Text(textDefaults.suggestExhaustedSubtitle)
              .widgetCaption(fontSize: 12, lineLimit: 1)
          }
        } else {
          if entry.payload.isReady {
            CourseProgressRow(payload: entry.payload, barWidth: 76, fontSize: 12)
              .padding(.bottom, 3)
          }
          Text(title)
            .widgetTitle(fontSize: 20, lineLimit: entry.payload.isReady ? 2 : 3)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .layoutPriority(1)
    }
    .padding(.leading, 24)
    .padding(.trailing, 12)
    .padding(.vertical, 12)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }

  private var localeCode: String { storedWidgetLocaleCode ?? entry.payload.string("localeCode", fallback: "en") }
  private var textDefaults: MeupWidgetTextDefaults { MeupWidgetTextDefaults.forLocale(localeCode) }
  private var title: String {
    let fallback = entry.payload.title(for: entry.type, defaults: textDefaults)
    guard entry.payload.isReady else { return fallback }
    return entry.payload.localizedString("titleTranslations", localeCode: localeCode, fallback: fallback)
  }
  private var mainText: String {
    let fallback = entry.payload.string("description", fallback: entry.payload.string("subtitle", fallback: title))
    return entry.payload.localizedString("descriptionTranslations", localeCode: localeCode, fallback: fallback)
  }
  private var imageWidth: CGFloat { 110 }
  private var imageHeight: CGFloat {
    entry.type == .suggestCourse && !entry.payload.isReady ? 75 : 110
  }
}

private struct SmallCourseWidgetView: View {
  let entry: MeupWidgetEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      WidgetImageView(type: entry.type, payload: entry.payload, width: imageWidth, height: imageHeight)
      if entry.type == .suggestCourse {
        if entry.payload.isReady {
          SuggestLabel(text: textDefaults.suggestLabel, fontSize: 10)
        }
        Text(entry.payload.isReady ? mainText : title)
          .widgetTitle(fontSize: 14, lineLimit: entry.payload.isReady ? 3 : 2)
        if !entry.payload.isReady {
          Text(textDefaults.suggestExhaustedSubtitle)
            .widgetCaption(fontSize: 10, lineLimit: 1)
        }
      } else {
        if entry.payload.isReady {
          CourseProgressRow(payload: entry.payload, barWidth: 52, fontSize: 12)
        }
        Text(title)
          .widgetTitle(fontSize: 14, lineLimit: entry.payload.isReady ? 3 : 2)
      }
      Spacer(minLength: 0)
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  private var localeCode: String { storedWidgetLocaleCode ?? entry.payload.string("localeCode", fallback: "en") }
  private var textDefaults: MeupWidgetTextDefaults { MeupWidgetTextDefaults.forLocale(localeCode) }
  private var title: String {
    let fallback = entry.payload.title(for: entry.type, defaults: textDefaults)
    guard entry.payload.isReady else { return fallback }
    return entry.payload.localizedString("titleTranslations", localeCode: localeCode, fallback: fallback)
  }
  private var mainText: String {
    let fallback = entry.payload.string("description", fallback: entry.payload.string("subtitle", fallback: title))
    return entry.payload.localizedString("descriptionTranslations", localeCode: localeCode, fallback: fallback)
  }
  private var imageWidth: CGFloat {
    if entry.type == .suggestCourse && !entry.payload.isReady { return 76 }
    if entry.type == .inProgress && !entry.payload.isReady { return 70 }
    return 52
  }
  private var imageHeight: CGFloat {
    if entry.type == .suggestCourse && !entry.payload.isReady { return 52 }
    if entry.type == .inProgress && !entry.payload.isReady { return 70 }
    return 52
  }
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
        Text(payload.string("progressText", fallback: "\(completed)/\(total) lesson"))
          .font(.system(size: fontSize, weight: .medium))
          .foregroundStyle(WidgetColor.muted)
          .lineLimit(1)
          .minimumScaleFactor(0.75)
      }
    }
  }
}
