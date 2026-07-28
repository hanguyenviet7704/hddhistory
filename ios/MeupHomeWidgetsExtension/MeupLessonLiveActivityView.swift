import ActivityKit
import SwiftUI
import WidgetKit

// Ported from the Claude Design file "7 · Live Activity.dc.html" (project MeUp,
// layout "C — Course thumbnail", the chosen option). Colors/copy match that
// spec 1:1; typography uses the system font (SF Pro) rather than the design's
// Poppins/Mulish — MeupHomeWidgetComponents.swift's existing widgets already
// established that convention for this extension (no custom fonts bundled
// into the widget target), so this follows suit instead of introducing new
// font assets just for this surface.

@available(iOS 16.2, *)
private enum LiveActivityColor {
  static let badgeBg = Color(hex: 0x5B4FE8).opacity(0.12)
  static let badgeDot = Color(hex: 0xB7A9FF)
  static let badgeText = Color(hex: 0x5B4FE8)
  static let label = Color(hex: 0x6C63E8)
  static let title = Color(hex: 0x181822)
  static let percentText = Color(hex: 0x3A3F4A)
  static let trackLight = Color.black.opacity(0.1)
  static let nudgeBg = Color(hex: 0x8B7BFF).opacity(0.16)
  static let thumbnailFallback = Color(hex: 0x2A2545)
  static let logoStart = Color(hex: 0x8B8BF0)
  static let logoEnd = Color(hex: 0x4B45D6)
  static let ringTint = Color(hex: 0x8E7BFF)
  static let ringTrackDark = Color.white.opacity(0.2)
  static let diTitle = Color.white
  static let diLabel = Color(hex: 0x8E7BFF)
  static let diFooter = Color.white.opacity(0.45)
  static let diButtonBg = Color(hex: 0x554FF0)
  static let gradientStops: [Color] = [Color(hex: 0x5B4FE8), Color(hex: 0xC56BD6), Color(hex: 0xF4A45C)]
}

// The new Meup brand mark: a "?" glyph (Poppins-Bold "question", viewBox
// 479 x 749) extracted verbatim from the bundled Poppins-Bold.ttf — the same
// mark shipped on the app icon (design "9 · Logo"). Kept as a tiny M/L/C/Z-only
// SVG path (Poppins TrueType quadratics converted to cubics) since
// SwiftUI/CoreGraphics has no built-in "Path(svgPathString:)" initializer. The
// -4° tilt + gradient tile are applied by meupLessonLogo(), not baked here.
// The Android side uses the IDENTICAL path in drawable/ic_stat_meup.xml.
private let meupLogoMarkPathData = """
M 479.0 214.0 C 479.0 339.33 389.67 412.67 255.0 414.0 L 250.0 489.0 L 100.0 489.0 L 95.0 303.0 L 155.0 303.0 C 257.67 303.0 313.0 281.67 313.0 215.0 C 313.0 168.33 286.33 140.0 241.0 140.0 C 193.0 140.0 165.0 169.33 165.0 216.0 L 4.0 216.0 C 0.0 94.0 89.0 0.0 243.0 0.0 C 385.67 0.0 479.0 78.0 479.0 214.0 Z M 75.0 657.0 C 75.0 603.67 117.0 563.0 177.0 563.0 C 235.67 563.0 278.0 603.67 278.0 657.0 C 278.0 709.0 235.67 749.0 177.0 749.0 C 117.0 749.0 75.0 709.0 75.0 657.0 Z
"""

private func meupParseSVGPath(_ d: String, scale: CGFloat, offset: CGPoint) -> Path {
  var path = Path()
  let tokens = d.split(whereSeparator: { $0 == " " || $0 == "\n" }).map(String.init)
  var i = 0
  func nextPoint() -> CGPoint {
    guard i + 1 < tokens.count else { return .zero }
    let x = CGFloat(Double(tokens[i]) ?? 0)
    let y = CGFloat(Double(tokens[i + 1]) ?? 0)
    i += 2
    return CGPoint(x: offset.x + x * scale, y: offset.y + y * scale)
  }
  while i < tokens.count {
    let cmd = tokens[i]
    i += 1
    switch cmd {
    case "M": path.move(to: nextPoint())
    case "L": path.addLine(to: nextPoint())
    case "C":
      let c1 = nextPoint()
      let c2 = nextPoint()
      let end = nextPoint()
      path.addCurve(to: end, control1: c1, control2: c2)
    case "Z", "z":
      path.closeSubpath()
    default:
      i = tokens.count // unrecognized token — bail rather than loop forever
    }
  }
  return path
}

private struct MeupLogoMarkShape: Shape {
  static let sourceSize = CGSize(width: 479, height: 749)

  func path(in rect: CGRect) -> Path {
    let scale = min(rect.width / Self.sourceSize.width, rect.height / Self.sourceSize.height)
    let offset = CGPoint(
      x: rect.minX + (rect.width - Self.sourceSize.width * scale) / 2,
      y: rect.minY + (rect.height - Self.sourceSize.height * scale) / 2
    )
    return meupParseSVGPath(meupLogoMarkPathData, scale: scale, offset: offset)
  }
}

@available(iOS 16.2, *)
private func meupLessonLogo(size: CGFloat) -> some View {
  RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
    .fill(LinearGradient(colors: [LiveActivityColor.logoStart, LiveActivityColor.logoEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
    .frame(width: size, height: size)
    .overlay(
      // "?" is taller than wide — size it by height (~58% of the tile) and let
      // width follow the glyph aspect, then apply the design's -4° tilt.
      MeupLogoMarkShape()
        .fill(Color.white)
        .frame(
          width: size * 0.58 * (MeupLogoMarkShape.sourceSize.width / MeupLogoMarkShape.sourceSize.height),
          height: size * 0.58
        )
        .rotationEffect(.degrees(-4))
    )
}

@available(iOS 16.2, *)
private func meupLessonThumbnail(path: String, size: CGFloat) -> some View {
  Group {
    if let uiImage = meupDownsampledImage(atPath: path, maxPixel: size * 3) {
      Image(uiImage: uiImage).resizable().scaledToFill()
    } else {
      Rectangle().fill(LiveActivityColor.thumbnailFallback)
    }
  }
  .frame(width: size, height: size)
  .clipShape(RoundedRectangle(cornerRadius: size * 0.26, style: .continuous))
}

@available(iOS 16.2, *)
private struct MeupLessonProgressRing: View {
  let progress: Double
  let lineWidth: CGFloat
  var trackColor: Color = LiveActivityColor.trackLight
  var tintColor: Color = LiveActivityColor.ringTint

  var body: some View {
    ZStack {
      Circle().stroke(trackColor, lineWidth: lineWidth)
      Circle()
        .trim(from: 0, to: max(0.001, min(1, progress)))
        .stroke(tintColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        .rotationEffect(.degrees(-90))
    }
  }
}

// All display copy (resumeLabel, primaryNudge, footerNudge, inLessonLabel,
// continueLearningLabel) is localized on the Dart side and carried in the
// Activity attributes/state — the widget renders those strings verbatim, so no
// copy or done/not-done branching lives here anymore.
@available(iOS 16.2, *)
private func meupPercentText(_ progress: Double) -> String {
  "\(Int((max(0, min(1, progress)) * 100).rounded()))%"
}

// MARK: - Lock Screen (layout C — course thumbnail)

@available(iOS 16.2, *)
struct MeupLessonLockScreenView: View {
  let attributes: MeupLessonActivityAttributes
  let state: MeupLessonActivityAttributes.ContentState

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 9) {
        meupLessonLogo(size: 26)
        Text("MeUp").font(.system(size: 13, weight: .semibold)).foregroundStyle(LiveActivityColor.title)
        Spacer()
        HStack(spacing: 5) {
          Circle().fill(LiveActivityColor.badgeDot).frame(width: 5, height: 5)
          Text(attributes.inLessonLabel).font(.system(size: 9, weight: .heavy)).foregroundStyle(LiveActivityColor.badgeText)
        }
        .padding(.horizontal, 10).padding(.vertical, 3)
        .background(Capsule().fill(LiveActivityColor.badgeBg))
      }

      HStack(spacing: 14) {
        meupLessonThumbnail(path: attributes.courseImagePath, size: 54)
        VStack(alignment: .leading, spacing: 5) {
          Text(attributes.continueLearningLabel).font(.system(size: 10, weight: .heavy)).foregroundStyle(LiveActivityColor.label)
          Text(attributes.courseName)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(LiveActivityColor.title)
            .lineLimit(2)
          HStack(spacing: 9) {
            GeometryReader { proxy in
              ZStack(alignment: .leading) {
                Capsule().fill(LiveActivityColor.trackLight)
                Capsule()
                  .fill(LinearGradient(colors: LiveActivityColor.gradientStops, startPoint: .leading, endPoint: .trailing))
                  .frame(width: proxy.size.width * max(0, min(1, state.progress)))
              }
            }
            .frame(height: 7)
            Text(meupPercentText(state.progress)).font(.system(size: 11, weight: .bold)).foregroundStyle(LiveActivityColor.percentText)
          }
          .padding(.top, 5)
        }
      }

      HStack {
        Spacer()
        HStack(spacing: 6) {
          Image(systemName: "play.fill").font(.system(size: 11)).foregroundStyle(LiveActivityColor.badgeText)
          Text(state.primaryNudge).font(.system(size: 12, weight: .bold)).foregroundStyle(LiveActivityColor.badgeText)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Capsule().fill(LiveActivityColor.nudgeBg))
        Spacer()
      }
    }
    .padding(.horizontal, 30)
    .padding(.vertical, 28)
  }
}

// MARK: - Dynamic Island

@available(iOS 16.2, *)
private struct MeupLessonDIMinimal: View {
  let state: MeupLessonActivityAttributes.ContentState
  var body: some View {
    // White track — the Dynamic Island background is black, so the default
    // black-tinted lock-screen track would be invisible here.
    MeupLessonProgressRing(progress: state.progress, lineWidth: 3, trackColor: LiveActivityColor.ringTrackDark).frame(width: 20, height: 20)
  }
}

@available(iOS 16.2, *)
private struct MeupLessonDICompactLeading: View {
  var body: some View {
    meupLessonLogo(size: 20)
  }
}

@available(iOS 16.2, *)
private struct MeupLessonDICompactTrailing: View {
  let state: MeupLessonActivityAttributes.ContentState
  var body: some View {
    HStack(spacing: 6) {
      MeupLessonProgressRing(progress: state.progress, lineWidth: 3, trackColor: LiveActivityColor.ringTrackDark).frame(width: 20, height: 20)
      Text(meupPercentText(state.progress)).font(.system(size: 13, weight: .bold)).foregroundStyle(LiveActivityColor.diTitle)
    }
  }
}

// Dynamic Island Expanded is split across the system's three regions
// (leading / trailing / bottom) that flow around the camera cutout — NOT one
// free-form card. Each piece appears exactly once (header text left, ring
// right, button+footer below), so there's no duplication and nothing gets
// clipped by cramming the whole card into a single region.
// Matches the design's top row: logo + (IN LESSON label above course title).
// The camera cutout keeps .leading narrow, so the title uses
// minimumScaleFactor to shrink-to-fit on one line rather than truncating to
// "Dopam…"; keeping it here (not in .bottom) leaves .bottom for just the
// button + footer so the footer never gets clipped.
@available(iOS 16.2, *)
private struct MeupLessonDIExpandedLeading: View {
  let attributes: MeupLessonActivityAttributes
  var body: some View {
    HStack(spacing: 9) {
      meupLessonLogo(size: 30)
      VStack(alignment: .leading, spacing: 1) {
        Text(attributes.inLessonLabel).font(.system(size: 9, weight: .heavy)).foregroundStyle(LiveActivityColor.diLabel).lineLimit(1)
        Text(attributes.courseName)
          .font(.system(size: 15, weight: .bold))
          .foregroundStyle(LiveActivityColor.diTitle)
          .lineLimit(1)
          .minimumScaleFactor(0.6)
      }
    }
  }
}

@available(iOS 16.2, *)
private struct MeupLessonDIExpandedTrailing: View {
  let state: MeupLessonActivityAttributes.ContentState
  var body: some View {
    ZStack {
      MeupLessonProgressRing(progress: state.progress, lineWidth: 4, trackColor: LiveActivityColor.ringTrackDark)
      Text(meupPercentText(state.progress)).font(.system(size: 11, weight: .bold)).foregroundStyle(LiveActivityColor.diTitle)
    }
    .frame(width: 40, height: 40)
  }
}

@available(iOS 16.2, *)
private struct MeupLessonDIExpandedBottom: View {
  let state: MeupLessonActivityAttributes.ContentState

  var body: some View {
    VStack(spacing: 8) {
      // A real interactive button needs an AppIntent (iOS 17+); the whole
      // presentation already opens the app via .widgetURL (same tap-to-open
      // convention as the existing static widgets), so this is styled as a
      // button but isn't itself the tap target.
      Text(state.resumeLabel).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white).frame(maxWidth: .infinity)
        .frame(height: 38)
        .background(Capsule().fill(LiveActivityColor.diButtonBg))
      Text(state.footerNudge)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(LiveActivityColor.diFooter)
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }
    .padding(.top, 4)
  }
}

// Matches the existing static widgets' tap-to-open convention (see
// MeupHomeWidgetViews.swift's `.widgetURL(URL(string: entry.payload.deeplink))`).
@available(iOS 16.2, *)
private func meupLessonDeeplink(courseId: String) -> URL? {
  URL(string: "meup://course-roadmap?courseId=\(courseId)&source=live_activity")
}

@available(iOS 16.2, *)
struct MeupLessonLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: MeupLessonActivityAttributes.self) { context in
      MeupLessonLockScreenView(attributes: context.attributes, state: context.state)
        .activityBackgroundTint(Color.white)
        .activitySystemActionForegroundColor(LiveActivityColor.title)
        .widgetURL(meupLessonDeeplink(courseId: context.attributes.courseId))
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          MeupLessonDIExpandedLeading(attributes: context.attributes)
        }
        DynamicIslandExpandedRegion(.trailing) {
          MeupLessonDIExpandedTrailing(state: context.state)
        }
        DynamicIslandExpandedRegion(.bottom) {
          MeupLessonDIExpandedBottom(state: context.state)
            .widgetURL(meupLessonDeeplink(courseId: context.attributes.courseId))
        }
      } compactLeading: {
        MeupLessonDICompactLeading()
      } compactTrailing: {
        MeupLessonDICompactTrailing(state: context.state)
      } minimal: {
        MeupLessonDIMinimal(state: context.state)
      }
    }
  }
}
