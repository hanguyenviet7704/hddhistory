part of '../community.dart';

/// The write endpoints answer a refusal with one of these instead of a sentence.
///
/// Codes, not copy: at the moment it refuses, the server has no reliable way to
/// know the reader's language, and the app also keys its own behaviour off them.
/// Both halves are settled by translating here, in the only layer that knows
/// which language to translate into. Keep them in step with
/// `meup-api/src/modules/community/src/helper/community-limit.helper.ts` and
/// `community-sanction.service.ts`.
const String _codeRateLimited = 'COMMUNITY_RATE_LIMITED';
const String _codeDuplicate = 'COMMUNITY_DUPLICATE_CONTENT';
const String _codeMuted = 'COMMUNITY_MUTED';
const String _codeLoginRequired = 'COMMUNITY_LOGIN_REQUIRED';

/// Turns whatever a community call threw into an [AppException] carrying a line
/// a person can act on.
///
/// Anything unrecognised gets the generic line, and the raw text goes to the
/// console instead. A `DioException [bad response]: This exception was thrown
/// because...` on screen tells the reader nothing they can do and looks like the
/// app broke — but it is the first thing a developer wants, so it is logged, not
/// discarded.
AppException communityException(Object error) {
  if (error is! DioException) return _communityGenericFailure(error);

  // A 5xx can answer with an HTML page, so the body is not always a Map —
  // indexing a String throws, and this runs inside an error mapper where a
  // throw would escape the failure path entirely.
  final data = error.response?.data;
  final body = data is Map ? data : const <dynamic, dynamic>{};

  // Everything past `message` travels under `meta`: the API's global exception
  // filter forwards `message`, `errors` and `meta`, and drops any other key a
  // thrower sets. See meup-api/src/base/filters/all-exceptions.filter.ts.
  final rawMeta = body['meta'];
  final meta = rawMeta is Map ? rawMeta : const <dynamic, dynamic>{};

  switch (body['message']?.toString()) {
    case _codeRateLimited:
      final seconds = int.tryParse('${meta['retryAfterSeconds']}') ?? 0;

      return AppException.invalidInput(_communityTooFastCopy(seconds));

    case _codeDuplicate:
      return AppException.invalidInput(l10n.community.duplicateContent);

    case _codeMuted:
      // The moderator's own words when there are any: they name the specific
      // thing that was wrong, which the generic line cannot.
      final reason = meta['reason']?.toString();

      return AppException.forbidden(
        reason == null || reason.isEmpty ? l10n.community.mutedBodyFallback : reason,
      );

    case _codeLoginRequired:
      return AppException.unauthorized(l10n.community.guestBody);

    default:
      return _communityGenericFailure(error);
  }
}

/// The line shown for anything the server did not name: "Chưa tải được nội
/// dung. Kiểm tra kết nối rồi thử lại nhé."
AppException _communityGenericFailure(Object error) {
  LogDev.error('[community] $error');

  return AppException.unexpected(l10n.community.errorBody);
}

/// "Thử lại sau 40 giây" / "sau 3 phút", from the wait the server quoted.
///
/// Rounded UP past a minute: telling someone to come back in "2 phút" when the
/// real answer is 2:40 sends them straight back into the same refusal.
String _communityTooFastCopy(int seconds) {
  if (seconds >= 60) {
    return l10n.community.tooFastMinutes(count: (seconds / 60).ceil());
  }

  return l10n.community.tooFastSeconds(count: seconds < 1 ? 1 : seconds);
}
