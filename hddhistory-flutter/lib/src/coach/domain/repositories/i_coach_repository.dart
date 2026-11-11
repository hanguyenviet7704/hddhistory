part of '../../coach.dart';

abstract interface class ICoachRepository {
  TaskEither<AppException, CoachBubbleEntity> getBubble({
    required CoachEntry entry,
    String? lessonId,
    required int tzOffsetMinutes,
  });

  TaskEither<AppException, CoachTurnEntity> openSession({
    required CoachEntry entry,
    String? lessonId,
    String? habitId,
    String? keypointId,
    String? courseId,
    bool recap = false,
    required String locale,
    required int tzOffsetMinutes,
  });

  TaskEither<AppException, CoachTurnEntity> sendTurn({
    required String sessionId,
    required Map<String, dynamic> payload,
  });

  TaskEither<AppException, Unit> closeSession(String sessionId);

  /// Luồng 6 — records whether the reader stayed when asked, or closed anyway.
  /// [chips]/[note] — why they left, from the sheet after ⟨Vẫn đóng⟩. Absent
  /// when they skipped it, and always absent when they stayed.
  TaskEither<AppException, Unit> exitSession(String sessionId, {required bool stayed, List<String>? chips, String? note});

  /// The voice, changed from the header at any step — remembered for next time.
  TaskEither<AppException, Unit> setPersona({
    required String sessionId,
    required String persona,
  });

  /// Counts a "explain this more simply" against the KEYPOINT, weekly.
  TaskEither<AppException, Unit> explainAgain(String keypointId);

  /// Speech to the reader's own words. Returns '' when nothing could be heard.
  TaskEither<AppException, String> transcribe({
    required String base64Audio,
    required String mimeType,
    required String locale,
  });
}
