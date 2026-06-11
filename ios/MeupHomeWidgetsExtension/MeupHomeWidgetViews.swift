import SwiftUI
import UIKit
import WidgetKit

struct MeupHomeWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: MeupWidgetEntry

  var body: some View {
    Group {
      switch entry.type {
      case .inProgress:
        CourseWidgetView(entry: entry, compact: family == .systemSmall)
      case .streak:
        StreakWidgetView(entry: entry)
      case .suggestCourse:
        CourseWidgetView(entry: entry, compact: family == .systemSmall)
      }
    }
    .widgetURL(URL(string: entry.payload.deeplink))
    .widgetBackground()
  }
}

private struct CourseWidgetView: View {
  let entry: MeupWidgetEntry
  let compact: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .top, spacing: 10) {
        WidgetImageView(type: entry.type, payload: entry.payload, size: compact ? 48 : 60)
        VStack(alignment: .leading, spacing: 5) {
          if entry.type == .suggestCourse {
            Text(entry.payload.string("label", fallback: "Today's suggestion"))
              .font(.caption2.weight(.semibold))
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(Color(red: 0.92, green: 0.96, blue: 1.0))
              .clipShape(Capsule())
          }
          Text(entry.payload.string("title", fallback: entry.type.defaultTitle))
            .font(compact ? .caption.weight(.bold) : .subheadline.weight(.bold))
            .foregroundStyle(Color(red: 0.11, green: 0.13, blue: 0.16))
            .lineLimit(compact ? 3 : 2)
          if entry.type == .suggestCourse && !compact {
            Text(entry.payload.string("description", fallback: entry.payload.string("subtitle")))
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(2)
          }
        }
      }

      if entry.type == .inProgress && entry.payload.isReady {
        ProgressView(value: min(max(entry.payload.double("progress"), 0), 1))
          .tint(Color(red: 0.11, green: 0.67, blue: 0.46))
        Text("\(entry.payload.int("completedLessons"))/\(entry.payload.int("totalLessons")) lessons")
          .font(.caption2)
          .foregroundStyle(.secondary)
      } else if !entry.payload.isReady {
        Text(entry.payload.state == "exhausted" ? "All caught up" : "Open Meup to continue")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(Color(red: 0.11, green: 0.67, blue: 0.46))
          .padding(.horizontal, 8)
          .padding(.vertical, 5)
          .background(Color(red: 0.91, green: 0.97, blue: 0.94))
          .clipShape(Capsule())
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

private struct StreakWidgetView: View {
  let entry: MeupWidgetEntry

  var body: some View {
    VStack(spacing: 14) {
      HStack(spacing: 10) {
        WidgetImageView(type: .streak, payload: entry.payload, size: 48)
        VStack(alignment: .leading, spacing: 2) {
          let streak = entry.payload.int("currentStreak")
          Text("\(streak) day\(streak == 1 ? "" : "s")")
            .font(.title3.weight(.bold))
            .foregroundStyle(Color(red: 0.11, green: 0.13, blue: 0.16))
          Text(entry.payload.string("subtitle", fallback: "Start your streak today"))
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
      WeekStudyRow(days: entry.payload.boolArray("weekStudy", size: 7))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
  }
}

private struct WidgetImageView: View {
  let type: MeupWidgetType
  let payload: MeupWidgetPayload
  let size: CGFloat

  var body: some View {
    image
      .resizable()
      .scaledToFill()
      .frame(width: size, height: size)
      .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
  }

  private var image: Image {
    if let key = payload.string("imagePathKey").nonEmpty,
      let path = widgetDefaults.string(forKey: key),
      let uiImage = UIImage(contentsOfFile: path)
    {
      return Image(uiImage: uiImage)
    }
    if let path = widgetDefaults.string(forKey: payload.string("staticAssetKey", fallback: type.fallbackImageKey)),
      let uiImage = UIImage(contentsOfFile: path)
    {
      return Image(uiImage: uiImage)
    }
    return Image(type.fallbackImageName)
  }
}

private struct WeekStudyRow: View {
  let days: [Bool]

  var body: some View {
    HStack(spacing: 5) {
      ForEach(Array(days.enumerated()), id: \.offset) { index, active in
        ZStack {
          Circle()
            .fill(active ? Color(red: 0.11, green: 0.67, blue: 0.46) : Color(red: 0.91, green: 0.97, blue: 0.94))
          Text(active ? "✓" : "\(index + 1)")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(active ? Color.white : Color.secondary)
        }
        .frame(width: 20, height: 20)
      }
    }
  }
}

private extension View {
  @ViewBuilder
  func widgetBackground() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(.white, for: .widget)
    } else {
      padding(14)
        .background(Color.white)
    }
  }
}
