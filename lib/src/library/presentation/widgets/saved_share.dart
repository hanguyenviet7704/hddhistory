part of '../../library.dart';

/// Public link to a course's roadmap.
///
/// The https form, not `hddhistory://`: a shared link is opened by someone who may
/// not have the app. `meup.training` carries the AASA / assetlinks files, so it
/// opens the app through a Universal Link when installed and the web page when
/// not. `course-roadmap` is a real [DeeplinkDestination], and `courseId` is the
/// param its handler reads.
String courseRoadmapShareUrl(String courseId) =>
    'https://meup.training/course-roadmap?courseId=$courseId';

/// The message that travels beside the picture on a course share.
///
/// Deliberately NOT localized: the product owner specified one fixed English
/// line for every locale, so a shared story reads the same wherever it lands.
String courseShareMessage(String courseId) =>
    "Look what I found on HDDhistory! Thought you'd enjoy these ideas too \u{1F447}\n"
    '${courseRoadmapShareUrl(courseId)}';

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
      fileName: 'hddhistory-card.png',
      // 3x so the card is still crisp when a messaging app re-encodes it.
      pixelRatio: 3,
      sharePositionOrigin: sharePositionOrigin,
    );
    return true;
  } catch (_) {
    return _shareTextOnly(message, sharePositionOrigin);
  }
}

/// Shares a course as the story card the reader picked in [CourseShareSheet].
///
/// Supersedes the text-only [shareSavedCourse] for the sheet's entry point:
/// the design gives a course its own 9:16 card, so the old "a course has no
/// card to picture" reasoning no longer holds where that card exists.
///
/// Same contract as [shareSavedQuoteCard] deliberately — capture the live
/// widget through [boundaryKey] at 3x, fall back to the text alone when the
/// capture throws, and return false only when even that fails.
Future<bool> shareCourseStoryCard(
  BuildContext context, {
  required GlobalKey boundaryKey,
  required String courseId,
}) async {
  // Read everything off `context` BEFORE the first await — the platform share
  // sheet can outlive this widget.
  final mediaService = AppDI.injector.get<IMediaService>();
  final sharePositionOrigin = mediaService.getSharePositionOrigin(context);
  final message = courseShareMessage(courseId);

  try {
    await mediaService.captureAndShareWithRepaintBoundary(
      boundaryKey,
      shareText: message,
      fileName: 'hddhistory-course.png',
      pixelRatio: 3,
      sharePositionOrigin: sharePositionOrigin,
    );
    return true;
  } catch (_) {
    return _shareTextOnly(message, sharePositionOrigin);
  }
}

/// Shares a course as text alone.
///
/// Still the fallback path for [shareCourseStoryCard] and for any entry point
/// with no card on screen to capture.
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
