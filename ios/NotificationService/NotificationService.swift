import UserNotifications

/// Attaches the image a push carries so iOS can show it.
///
/// APNs itself never fetches media: without an extension like this one, an
/// `fcm_options.image` URL is delivered and silently dropped, which is exactly
/// what MeUp did before — an image-carrying push looked identical to a text-only
/// one on iOS while Android rendered it fine.
///
/// Runs only when the payload sets `mutable-content: 1`; the server sets that
/// flag on the same condition it sends an image, so a text-only push never pays
/// for this process at all.
class NotificationService: UNNotificationServiceExtension {
  /// Every exit path must call this exactly once, including the timeout one.
  private var contentHandler: ((UNNotificationContent) -> Void)?
  /// What ships if the download fails or runs out of time: the notification
  /// unchanged. A missing image must never cost the reader the whole message.
  private var bestAttempt: UNMutableNotificationContent?
  private var downloadTask: URLSessionDataTask?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    self.contentHandler = contentHandler
    let mutableContent = request.content.mutableCopy() as? UNMutableNotificationContent
    bestAttempt = mutableContent

    guard
      let content = mutableContent,
      let imageURL = Self.imageURL(from: request.content.userInfo)
    else {
      self.contentHandler = nil
      contentHandler(request.content)
      return
    }

    // 15s, not the ~30s the system allows: `serviceExtensionTimeWillExpire` is a
    // hard kill, and being killed mid-write is how a half-downloaded file ends
    // up attached. Finishing early with no image beats that.
    let configuration = URLSessionConfiguration.ephemeral
    configuration.timeoutIntervalForRequest = 15
    configuration.timeoutIntervalForResource = 15

    downloadTask = URLSession(configuration: configuration)
      .dataTask(with: imageURL) { [weak self] data, response, _ in
        guard let self = self else { return }
        defer { self.deliver() }

        guard
          let data = data,
          ((response as? HTTPURLResponse)?.statusCode ?? 200) < 400,
          let attachment = Self.attachment(for: data, from: imageURL)
        else { return }

        content.attachments = [attachment]
      }
    downloadTask?.resume()
  }

  /// Called when the system is about to kill this process. Ship what we have.
  override func serviceExtensionTimeWillExpire() {
    downloadTask?.cancel()
    deliver()
  }

  /// Guards against double delivery: the timeout and the download completing can
  /// race, and calling the handler twice is a crash, not a no-op.
  private func deliver() {
    guard let handler = contentHandler, let content = bestAttempt else { return }
    contentHandler = nil
    handler(content)
  }

  /// Where the URL comes from, in order of how much we trust it.
  ///
  /// `imageUrl` is MeUp's own data key — the same one the Flutter side reads to
  /// render a foreground notification, so server and app agree on one name.
  /// `fcm_options.image` is FCM's field, kept as a fallback so a push composed
  /// outside our own sender (a Firebase console test, say) still shows its image.
  private static func imageURL(from userInfo: [AnyHashable: Any]) -> URL? {
    let candidates: [Any?] = [
      userInfo["imageUrl"],
      (userInfo["fcm_options"] as? [AnyHashable: Any])?["image"],
    ]

    for candidate in candidates {
      guard
        let raw = (candidate as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
        !raw.isEmpty,
        let url = URL(string: raw),
        url.scheme == "https" || url.scheme == "http"
      else { continue }
      return url
    }
    return nil
  }

  /// `UNNotificationAttachment` reads the type off the file EXTENSION, so the
  /// temp file has to carry one — an extensionless copy is rejected and the
  /// image is lost with no error the sender can see.
  private static func attachment(for data: Data, from url: URL) -> UNNotificationAttachment? {
    let known = ["jpg", "jpeg", "png", "gif", "webp"]
    let fromURL = url.pathExtension.lowercased()
    let ext = known.contains(fromURL) ? fromURL : "jpg"

    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let file = directory.appendingPathComponent("image.\(ext)")

    do {
      try FileManager.default.createDirectory(
        at: directory,
        withIntermediateDirectories: true
      )
      try data.write(to: file)
      return try UNNotificationAttachment(identifier: "image", url: file)
    } catch {
      return nil
    }
  }
}
