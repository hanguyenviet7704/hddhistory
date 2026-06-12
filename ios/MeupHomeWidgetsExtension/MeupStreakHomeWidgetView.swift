import SwiftUI

struct StreakWidgetView: View {
  let entry: MeupWidgetEntry
  let isSmall: Bool

  var body: some View {
    if isSmall {
      SmallStreakWidgetView(payload: entry.payload)
    } else {
      MediumStreakWidgetView(payload: entry.payload)
    }
  }
}

private struct SmallStreakWidgetView: View {
  let payload: MeupWidgetPayload

  var body: some View {
    VStack(spacing: 5) {
      WidgetImageView(type: .streak, payload: payload, width: 72, height: 77)
      StreakCountText(payload: payload, fontSize: 26)
      Text(payload.string("subtitle", fallback: "Start your streak today"))
        .widgetCaption(fontSize: 12, lineLimit: 1)
    }
    .padding(14)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
  }
}

private struct MediumStreakWidgetView: View {
  let payload: MeupWidgetPayload

  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      Image("meup_widget_streak_medium_art")
        .resizable()
        .scaledToFit()
        .frame(width: 160, height: 94)
        .offset(x: 8, y: 6)
      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 12) {
          WidgetImageView(type: .streak, payload: payload, width: 44, height: 47)
          VStack(alignment: .leading, spacing: 1) {
            StreakCountText(payload: payload, fontSize: 24)
            Text(payload.string("subtitle", fallback: "Start your streak today"))
              .widgetCaption(fontSize: 12, lineLimit: 1)
          }
        }
        StreakWeekStudyRow(
          days: payload.boolArray("weekStudy", size: 7),
          labels: payload.stringArray("weekLabels", fallback: ["M", "T", "W", "T", "F", "S", "S"], size: 7),
          daySize: 24,
          gap: 16
        )
        Spacer(minLength: 0)
      }
      .padding(.top, 16)
      .padding(.leading, 16)
      .padding(.trailing, 12)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

private struct StreakWeekStudyRow: View {
  let days: [Bool]
  let labels: [String]
  let daySize: CGFloat
  let gap: CGFloat

  var body: some View {
    HStack(spacing: gap) {
      ForEach(labels.indices, id: \.self) { index in
        VStack(spacing: 2) {
          Circle()
            .fill(days[safe: index] == true ? WidgetColor.progress : WidgetColor.weekInactive)
            .overlay(Circle().stroke(Color.white, lineWidth: days[safe: index] == true ? 1 : 2))
            .overlay {
              if days[safe: index] == true {
                Text("✓")
                  .font(.system(size: 12, weight: .bold))
                  .foregroundStyle(.white)
              }
            }
            .frame(width: daySize, height: daySize)
          Text(labels[index])
            .font(.system(size: 11, weight: days[safe: index] == true ? .bold : .medium))
            .foregroundStyle(days[safe: index] == true ? WidgetColor.progress : WidgetColor.weekInactiveText)
        }
      }
    }
  }
}
