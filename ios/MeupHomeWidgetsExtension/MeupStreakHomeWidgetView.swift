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
      WidgetImageView(type: .streak, payload: payload, size: 64)
      StreakCountText(streak: payload.int("currentStreak"), fontSize: 25)
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
        .frame(width: 150, height: 88)
        .offset(x: 5, y: 5)
      VStack(alignment: .leading, spacing: 14) {
        HStack(spacing: 12) {
          WidgetImageView(type: .streak, payload: payload, size: 46)
          VStack(alignment: .leading, spacing: 1) {
            StreakCountText(streak: payload.int("currentStreak"), fontSize: 24)
            Text(payload.string("subtitle", fallback: "Start your streak today"))
              .widgetCaption(fontSize: 12, lineLimit: 1)
          }
        }
        StreakWeekStudyRow(days: payload.boolArray("weekStudy", size: 7), daySize: 22, gap: 8)
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
  let daySize: CGFloat
  let gap: CGFloat
  private let labels = ["M", "T", "W", "T", "F", "S", "S"]

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
