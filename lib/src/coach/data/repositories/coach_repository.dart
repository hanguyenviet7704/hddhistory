part of '../../coach.dart';

@LazySingleton(as: ICoachRepository)
class CoachRepository implements ICoachRepository {
  final CoachApi _api;

  CoachRepository(this._api);

  @override
  TaskEither<AppException, CoachBubbleEntity> getBubble({
    required CoachEntry entry,
    String? lessonId,
    required int tzOffsetMinutes,
  }) {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.getBubble(entry.raw, lessonId, tzOffsetMinutes);

        return (response.data ?? const CoachBubbleModel()).toEntity();
      },
      (error, stackTrace) => AppException.unexpected(error.toString()),
    );
  }

  @override
  TaskEither<AppException, CoachTurnEntity> openSession({
    required CoachEntry entry,
    String? lessonId,
    String? habitId,
    required String locale,
    required int tzOffsetMinutes,
  }) {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.openSession({
          'entry': entry.raw,
          'lessonId': ?lessonId,
          'habitId': ?habitId,
          'locale': locale,
          'tzOffsetMinutes': tzOffsetMinutes,
        });

        return (response.data ?? const CoachTurnModel()).toEntity();
      },
      (error, stackTrace) => AppException.unexpected(error.toString()),
    );
  }

  @override
  TaskEither<AppException, CoachTurnEntity> sendTurn({
    required String sessionId,
    required Map<String, dynamic> payload,
  }) {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.sendTurn(sessionId, payload);

        return (response.data ?? const CoachTurnModel()).toEntity();
      },
      // 410 means the session expired under us — the TTL that enforces "the
      // Coach's words are never stored". The cubit answers by opening a fresh
      // session rather than showing anything, so it has to be distinguishable
      // from an ordinary failure.
      (error, stackTrace) =>
          error is DioException && error.response?.statusCode == 410 ? const AppException.notFound(CoachRepository.sessionExpiredCode) : AppException.unexpected(error.toString()),
    );
  }

  @override
  TaskEither<AppException, Unit> closeSession(String sessionId) {
    return TaskEither.tryCatch(
      () async {
        await _api.closeSession(sessionId);

        return unit;
      },
      (error, stackTrace) => AppException.unexpected(error.toString()),
    );
  }

  @override
  TaskEither<AppException, String> transcribe({
    required String base64Audio,
    required String mimeType,
    required String locale,
  }) {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.transcribe({
          'audio': base64Audio,
          'mimeType': mimeType,
          'locale': locale,
        });

        return (response.data ?? const CoachTranscriptModel()).text;
      },
      (error, stackTrace) => AppException.unexpected(error.toString()),
    );
  }

  @override
  TaskEither<AppException, Unit> explainAgain(String keypointId) {
    return TaskEither.tryCatch(
      () async {
        await _api.explainAgain({'keypointId': keypointId});

        return unit;
      },
      (error, stackTrace) => AppException.unexpected(error.toString()),
    );
  }

  /// Sentinel for "the session is gone, open a new one".
  static const String sessionExpiredCode = 'coach_session_expired';
}
