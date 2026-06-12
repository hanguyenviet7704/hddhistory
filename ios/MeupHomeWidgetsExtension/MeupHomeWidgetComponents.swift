import SwiftUI
import UIKit

enum WidgetColor {
  static let card = Color(hex: 0xF3F2FC)
  static let fallbackCard = Color(hex: 0xE7E5FD)
  static let brand = Color(hex: 0x362F82)
  static let muted = Color(hex: 0x8A86A8)
  static let progress = Color(hex: 0x4B44CA)
  static let progressTrack = Color(hex: 0xD8D5EA)
  static let progressStroke = Color(hex: 0xC7C5FA)
  static let weekInactive = Color(hex: 0xD8D5EA)
  static let weekInactiveText = Color(hex: 0x110751)
}

struct WidgetImageView: View {
  let type: MeupWidgetType
  let payload: MeupWidgetPayload
  let size: CGFloat

  var body: some View {
    if type == .streak {
      image.resizable().scaledToFit().frame(width: size, height: size)
    } else {
      image.resizable()
        .scaledToFill()
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
  }

  private var image: Image {
    if let key = payload.string("imagePathKey").nonEmpty,
      let path = widgetDefaults.string(forKey: key),
      let uiImage = UIImage(contentsOfFile: path) {
      return Image(uiImage: uiImage)
    }
    if let path = widgetDefaults.string(forKey: payload.string("staticAssetKey", fallback: type.fallbackImageKey)),
      let uiImage = UIImage(contentsOfFile: path) {
      return Image(uiImage: uiImage)
    }
    return Image(type.fallbackImageName)
  }
}

struct ProgressSegments: View {
  let completed: Int
  let total: Int
  let width: CGFloat

  var body: some View {
    GeometryReader { proxy in
      let safeTotal = max(total, 1)
      let safeCompleted = min(max(completed, 0), safeTotal)
      let progress = CGFloat(safeCompleted) / CGFloat(safeTotal)
      ZStack(alignment: .leading) {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
          .fill(WidgetColor.progressTrack)
          .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(WidgetColor.progressStroke, lineWidth: 1))
        if safeCompleted > 0 {
          RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(WidgetColor.progress)
            .frame(width: max(8, proxy.size.width * progress))
        }
      }
    }
    .frame(width: width, height: 8)
  }
}

struct SuggestLabel: View {
  let text: String
  let fontSize: CGFloat

  var body: some View {
    Text(text)
      .font(.system(size: fontSize, weight: .medium))
      .foregroundStyle(WidgetColor.muted)
      .lineLimit(1)
  }
}

struct StreakCountText: View {
  let streak: Int
  let fontSize: CGFloat

  var body: some View {
    Text("\(streak) day\(streak == 1 ? "" : "s")")
      .font(.system(size: fontSize, weight: .bold))
      .foregroundStyle(WidgetColor.brand)
      .lineLimit(1)
      .minimumScaleFactor(0.78)
  }
}

extension Text {
  func widgetTitle(fontSize: CGFloat, lineLimit: Int) -> some View {
    self.font(.system(size: fontSize, weight: .bold))
      .foregroundStyle(WidgetColor.brand)
      .lineLimit(lineLimit)
      .minimumScaleFactor(0.78)
  }

  func widgetCaption(fontSize: CGFloat, lineLimit: Int) -> some View {
    self.font(.system(size: fontSize, weight: .medium))
      .foregroundStyle(WidgetColor.muted)
      .lineLimit(lineLimit)
      .minimumScaleFactor(0.8)
  }
}

extension View {
  @ViewBuilder
  func widgetBackground(_ color: Color) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(color, for: .widget)
    } else {
      background(color)
    }
  }
}

extension Color {
  init(hex: Int) {
    self.init(
      red: Double((hex >> 16) & 0xFF) / 255.0,
      green: Double((hex >> 8) & 0xFF) / 255.0,
      blue: Double(hex & 0xFF) / 255.0
    )
  }
}

extension Array {
  subscript(safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
