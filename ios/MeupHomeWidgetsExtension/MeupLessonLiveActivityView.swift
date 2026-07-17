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
  static let logoStart = Color(hex: 0x6C63E8)
  static let logoEnd = Color(hex: 0x4B44CA)
  static let ringTint = Color(hex: 0x8E7BFF)
  static let ringTrackDark = Color.white.opacity(0.2)
  static let diTitle = Color.white
  static let diLabel = Color(hex: 0x8E7BFF)
  static let diFooter = Color.white.opacity(0.45)
  static let diButtonBg = Color(hex: 0x554FF0)
  static let gradientStops: [Color] = [Color(hex: 0x5B4FE8), Color(hex: 0xC56BD6), Color(hex: 0xF4A45C)]
}

// Exact "M" mark from the design file's Component.logo() (viewBox 0 0 45 28.111,
// path data copied verbatim) — a tiny M/L/C-only SVG path parser, since
// SwiftUI/CoreGraphics has no built-in "Path(svgPathString:)" initializer.
private let meupLogoMarkPathData = """
M 41.067 1.773 C 40.803 0.555 39.618 -0.215 38.42 0.053 L 30.016 1.935 C 29.056 2.15 28.349 2.981 28.279 3.978 L 27.649 12.859 C 27.561 14.102 28.482 15.183 29.705 15.273 C 30.929 15.363 31.992 14.427 32.08 13.183 L 32.436 8.162 C 33.089 8.64 33.8 9.184 34.522 9.778 C 35.865 10.883 37.206 12.127 38.284 13.406 C 39.384 14.712 40.082 15.906 40.34 16.906 C 40.843 18.85 40.431 20.501 39.562 21.649 C 38.69 22.801 37.245 23.595 35.381 23.595 C 35.016 23.595 34.425 23.439 33.564 22.895 C 32.719 22.361 31.769 21.551 30.729 20.494 C 28.645 18.375 26.455 15.532 24.284 12.641 C 22.168 9.821 20.033 6.902 18.189 4.886 C 17.278 3.889 16.296 2.951 15.298 2.364 C 14.339 1.799 12.712 1.209 11.159 2.261 C 10.234 2.889 9.228 3.973 8.296 5.111 C 7.32 6.302 6.275 7.742 5.27 9.245 C 3.282 12.218 1.329 15.628 0.372 18.05 C -0.552 20.389 0.368 22.993 1.791 24.768 C 3.294 26.643 5.718 28.111 8.69 28.111 C 11.745 28.111 14.359 26.282 16 24.825 C 16.864 24.058 17.565 23.298 18.05 22.73 C 18.294 22.445 18.487 22.204 18.621 22.031 C 18.689 21.944 18.742 21.874 18.78 21.823 C 18.8 21.797 18.815 21.776 18.826 21.76 L 18.849 21.729 C 19.573 20.722 19.357 19.31 18.367 18.574 C 17.377 17.838 15.988 18.057 15.263 19.063 L 15.263 19.064 C 15.26 19.068 15.246 19.087 15.241 19.093 C 15.22 19.122 15.184 19.169 15.136 19.231 C 15.039 19.356 14.89 19.542 14.697 19.768 C 14.307 20.224 13.75 20.827 13.077 21.424 C 11.645 22.696 10.077 23.595 8.69 23.595 C 7.218 23.595 6.004 22.875 5.234 21.915 C 4.384 20.855 4.398 19.978 4.494 19.733 C 5.277 17.752 7.026 14.652 8.944 11.783 C 9.892 10.365 10.85 9.05 11.71 8.001 C 12.332 7.241 12.839 6.699 13.209 6.359 C 13.614 6.63 14.187 7.142 14.935 7.96 C 16.59 9.769 18.548 12.442 20.753 15.38 C 22.904 18.246 25.263 21.324 27.588 23.687 C 28.753 24.872 29.973 25.943 31.218 26.73 C 32.446 27.506 33.864 28.111 35.381 28.111 C 38.551 28.111 41.326 26.723 43.083 24.403 C 44.842 22.079 45.467 18.97 44.637 15.759 C 44.133 13.808 42.95 12.003 41.658 10.469 C 40.344 8.909 38.781 7.473 37.317 6.268 C 36.869 5.899 36.426 5.549 35.997 5.22 L 39.376 4.463 C 40.574 4.195 41.331 2.99 41.067 1.773 Z
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
  static let sourceSize = CGSize(width: 45, height: 28.111)

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
      MeupLogoMarkShape()
        .fill(Color.white)
        .frame(width: size * 0.62, height: size * 0.62 * (MeupLogoMarkShape.sourceSize.height / MeupLogoMarkShape.sourceSize.width))
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
