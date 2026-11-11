import Flutter
import UIKit

/// Hands a rendered PNG to Instagram's or Facebook's story composer.
///
/// This cannot be done from Dart. Both apps read the image off the system
/// pasteboard under their OWN item keys and are then opened by URL scheme;
/// `Clipboard.setData` can only write plain text, and `share_plus` can only
/// raise the generic share sheet.
///
/// Registered from AppDelegate alongside LiveActivityChannel.
final class StoryShareChannel {
  static let channelName = "hddhistory/story_share"

  /// Instagram requires the sharing app's Facebook App ID as
  /// `source_application`, or it silently refuses the hand-off. Read from
  /// Info.plist rather than duplicated here so it can never drift from the one
  /// the Facebook SDK already uses.
  private var facebookAppID: String {
    (Bundle.main.object(forInfoDictionaryKey: "FacebookAppID") as? String) ?? ""
  }

  init(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(false) }
      guard call.method == "shareToStory" else { return result(FlutterMethodNotImplemented) }

      guard
        let args = call.arguments as? [String: Any],
        let platform = args["platform"] as? String,
        let data = args["image"] as? FlutterStandardTypedData
      else {
        return result(false)
      }
      result(self.share(platform: platform, png: data.data))
    }
  }

  private func share(platform: String, png: Data) -> Bool {
    let appID = facebookAppID
    // Without it Instagram opens and shows nothing, which reads to the user as
    // a broken button — better to report "not handled" and let Dart fall back.
    guard !appID.isEmpty else { return false }

    // The pasteboard keys are NAMESPACED PER APP, and that is the whole trick:
    // Instagram reads `com.instagram.sharedSticker.*`, Facebook reads
    // `com.facebook.sharedSticker.*`. Handing Facebook Instagram's key is not a
    // degraded share, it is a silent no-op — Facebook opens, finds nothing under
    // its own key, and shows an empty composer. Worse, this function would still
    // have returned true (the app DID open), so Dart never fell back to the
    // system sheet and the reader was left with a dead button.
    let scheme: String
    let keyPrefix: String
    switch platform {
    case "instagram":
      scheme = "instagram-stories://share?source_application=\(appID)"
      keyPrefix = "com.instagram.sharedSticker"
    case "facebook":
      scheme = "facebook-stories://share?source_application=\(appID)"
      keyPrefix = "com.facebook.sharedSticker"
    default:
      return false
    }

    guard let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) else {
      return false
    }

    // The pasteboard item must be written immediately before the open, with an
    // expiry so a story image never lingers on the user's clipboard.
    //
    // Facebook additionally wants the app id INSIDE the pasteboard item, not
    // only on the query string — it is part of its published contract, and
    // Instagram ignores a key it does not know, so writing it unconditionally
    // costs nothing and keeps the two branches one shape.
    var item: [String: Any] = ["\(keyPrefix).backgroundImage": png]
    item["\(keyPrefix).appID"] = appID

    UIPasteboard.general.setItems(
      [item],
      options: [.expirationDate: Date().addingTimeInterval(60 * 5)]
    )

    UIApplication.shared.open(url, options: [:], completionHandler: nil)
    return true
  }
}
