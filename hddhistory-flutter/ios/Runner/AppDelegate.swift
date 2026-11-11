import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var tikTokPlugin: TikTokPlugin?
  private var liveActivityChannel: LiveActivityChannel?
  private var storyShareChannel: StoryShareChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    // Instantiate TikTokPlugin with the FlutterViewController
    if let controller = window?.rootViewController as? FlutterViewController {
      tikTokPlugin = TikTokPlugin(controller: controller)
      liveActivityChannel = LiveActivityChannel(messenger: controller.binaryMessenger)
      storyShareChannel = StoryShareChannel(messenger: controller.binaryMessenger)
    } else {
      NSLog("[AppDelegate] ⚠️ FlutterViewController not found")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
