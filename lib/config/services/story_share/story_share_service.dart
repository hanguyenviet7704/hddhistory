part of '../services.dart';

/// The story composers a course card can be handed to.
enum StoryPlatform {
  instagram('instagram'),
  facebook('facebook');

  const StoryPlatform(this.channelValue);

  /// What the native side switches on. Keep in sync with StoryShareChannel on
  /// both platforms.
  final String channelValue;
}

abstract class IStoryShareService {
  /// Hands [pngBytes] to [platform]'s story composer.
  ///
  /// Returns true only when the OS actually opened that app. False means the
  /// app isn't installed, the platform refused, or the channel is missing — the
  /// caller is expected to fall back to the system share sheet rather than
  /// leave the tap dead.
  Future<bool> shareToStory({
    required StoryPlatform platform,
    required Uint8List pngBytes,
  });
}

/// Bridges to `meup/story_share`.
///
/// Story hand-off cannot be done from Dart: Instagram wants the image on the
/// pasteboard under its own item keys before `instagram-stories://share` is
/// opened (iOS), and an `ADD_TO_STORY` intent with a content:// URI on Android.
/// Neither is reachable through `Clipboard` or `share_plus`.
@LazySingleton(as: IStoryShareService)
class StoryShareService implements IStoryShareService {
  static const MethodChannel _channel = MethodChannel('meup/story_share');

  @override
  Future<bool> shareToStory({
    required StoryPlatform platform,
    required Uint8List pngBytes,
  }) async {
    try {
      final handed = await _channel.invokeMethod<bool>('shareToStory', {
        'platform': platform.channelValue,
        'image': pngBytes,
      });
      return handed ?? false;
    } on MissingPluginException {
      // Build without the native side registered — treat as "not handled" so
      // the caller falls back instead of throwing at the reader.
      LogDev.warning('story_share channel missing; falling back to system share');
      return false;
    } catch (error) {
      LogDev.error('story_share failed: $error');
      return false;
    }
  }
}
