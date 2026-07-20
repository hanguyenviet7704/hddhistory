import ImageIO
import SwiftUI
import UIKit

enum WidgetColor {
  static let card = Color(hex: 0xF3F2FC)
  static let fallbackCard = Color(hex: 0xE7E5FD)
  static let fallbackGradientStart = Color(hex: 0xF2F1FE)
  static let fallbackGradientEnd = Color(hex: 0xE4E2FD)
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
  let width: CGFloat
  let height: CGFloat

  init(type: MeupWidgetType, payload: MeupWidgetPayload, size: CGFloat) {
    self.type = type
    self.payload = payload
    self.width = size
    self.height = size
  }

  init(type: MeupWidgetType, payload: MeupWidgetPayload, width: CGFloat, height: CGFloat) {
    self.type = type
    self.payload = payload
    self.width = width
    self.height = height
  }

  var body: some View {
    if type == .streak {
      image.resizable().scaledToFit().frame(width: width, height: height)
    } else if payload.isReady {
      image.resizable()
        .scaledToFill()
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(Color.white, lineWidth: 3))
    } else {
      image.resizable()
        .scaledToFit()
        .frame(width: width, height: height)
    }
  }

  private var image: Image {
    if let key = payload.string("imagePathKey").nonEmpty,
      let path = widgetDefaults.string(forKey: key),
      let uiImage = meupDownsampledImage(atPath: path, maxPixel: 600) {
      return Image(uiImage: uiImage)
    }
    if let path = widgetDefaults.string(forKey: payload.string("staticAssetKey", fallback: type.fallbackImageKey)),
      let uiImage = meupDownsampledImage(atPath: path, maxPixel: 600) {
      return Image(uiImage: uiImage)
    }
    // Bundled fallback ships as loose PNGs (no asset catalog), so resolve via
    // UIImage(named:) which finds them; SwiftUI Image(name:) reads only catalogs
    // and would render blank.
    if let uiImage = UIImage(named: type.fallbackImageName) {
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
            .frame(width: max(6, proxy.size.width * progress))
        }
      }
    }
    .frame(width: width, height: 6)
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
      .minimumScaleFactor(0.65)
      .allowsTightening(true)
  }
}

struct StreakCountText: View {
  let payload: MeupWidgetPayload
  let fontSize: CGFloat

  var body: some View {
    let streak = payload.int("currentStreak")
    Text(payload.string("countText", fallback: "\(streak) day\(streak == 1 ? "" : "s")"))
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
      .multilineTextAlignment(.leading)
      .minimumScaleFactor(0.68)
      .allowsTightening(true)
      .fixedSize(horizontal: false, vertical: true)
  }

  func widgetCaption(fontSize: CGFloat, lineLimit: Int) -> some View {
    self.font(.system(size: fontSize, weight: .medium))
      .foregroundStyle(WidgetColor.muted)
      .lineLimit(lineLimit)
      .minimumScaleFactor(0.7)
      .allowsTightening(true)
  }
}

extension View {
  @ViewBuilder
  func meupWidgetBackground(isReady: Bool) -> some View {
    if isReady {
      widgetBackground(WidgetColor.card)
    } else {
      widgetBackground(
        LinearGradient(
          colors: [WidgetColor.fallbackGradientStart, WidgetColor.fallbackGradientEnd],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
    }
  }

  @ViewBuilder
  private func widgetBackground<S: ShapeStyle>(_ style: S) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) {
        Rectangle().fill(style)
      }
    } else {
      background(Rectangle().fill(style))
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

// Loads an image as a downsampled thumbnail via ImageIO so a full-resolution
// course image can't exceed the widget extension's tight memory budget (which
// jetsam-kills the process and forces the placeholder). Decodes only the
// thumbnail, never the full bitmap.
func meupDownsampledImage(atPath path: String, maxPixel: CGFloat) -> UIImage? {
  let url = URL(fileURLWithPath: path)
  guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
  let options: [CFString: Any] = [
    kCGImageSourceCreateThumbnailFromImageAlways: true,
    kCGImageSourceCreateThumbnailWithTransform: true,
    kCGImageSourceShouldCacheImmediately: true,
    kCGImageSourceThumbnailMaxPixelSize: maxPixel,
  ]
  guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
  return UIImage(cgImage: cgImage)
}
