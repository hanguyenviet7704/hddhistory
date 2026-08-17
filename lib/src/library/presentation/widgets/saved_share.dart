part of '../../library.dart';

/// Shares the quote card the reader is looking at, as a picture.
///
/// The card IS the thing worth sharing — a title and a link in a chat thread
/// is a different, duller message — so this screenshots the live widget through
/// [boundaryKey] rather than composing an image server-side.
///
/// Falls back to the text alone if the capture fails (an off-screen or
/// not-yet-laid-out boundary throws), because a share that half-works still
/// carries the link. Returns false only when even that fails, which is the
/// caller's cue to say so.
///
/// Public: the deck, the detail overlay and the recap card at the end of a
/// keypoint all share the same card the same way.
Future<bool> shareSavedQuoteCard(
  BuildContext context, {
  required GlobalKey boundaryKey,
  required String title,
}) async {
  // Everything off `context` is read BEFORE the first await — the share sheet
  // can outlive this widget, and a BuildContext used after it has not.
  final mediaService = AppDI.injector.get<IMediaService>();
  final sharePositionOrigin = mediaService.getSharePositionOrigin(context);
  final message = '${context.l10n.library.shareCardMessage(title: title)}\n${StoreUrl.shareFooter}';

  try {
    await mediaService.captureAndShareWithRepaintBoundary(
      boundaryKey,
      shareText: message,
      fileName: 'meup-card.png',
      // 3x so the card is still crisp when a messaging app re-encodes it.
      pixelRatio: 3,
      sharePositionOrigin: sharePositionOrigin,
    );
    return true;
  } catch (_) {
    return _shareTextOnly(message, sharePositionOrigin);
  }
}

/// Shares a course. Text only — a course has no card to picture, and its
/// thumbnail without the title around it says nothing.
Future<bool> shareSavedCourse(BuildContext context, {required String title}) {
  final mediaService = AppDI.injector.get<IMediaService>();
  final sharePositionOrigin = mediaService.getSharePositionOrigin(context);
  final message = '${context.l10n.library.shareCourseMessage(title: title)}\n${StoreUrl.shareFooter}';

  return _shareTextOnly(message, sharePositionOrigin);
}

Future<bool> _shareTextOnly(String message, Rect? sharePositionOrigin) async {
  try {
    await SharePlus.instance.share(
      ShareParams(text: message, sharePositionOrigin: sharePositionOrigin),
    );
    return true;
  } catch (_) {
    return false;
  }
}
