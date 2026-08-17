part of '../constants.dart';

/// Where a share sends someone who does not have the app yet.
///
/// Both stores are listed rather than a single smart link: a share lands in a
/// chat thread read on either platform, and nothing in the message knows which
/// device will open it.
abstract final class StoreUrl {
  static const String android = 'https://play.google.com/store/apps/details?id=com.eup.meup';
  static const String ios = 'https://apps.apple.com/us/app/meup-up-your-skills/id6755175330';

  /// The two links as they read at the bottom of a shared message.
  static const String shareFooter = 'Android: $android\nIOS: $ios';
}
