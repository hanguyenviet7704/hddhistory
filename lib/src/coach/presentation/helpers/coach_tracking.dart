part of '../../coach.dart';

/// Analytics cho AI Coach.
///
/// Cùng shape phát-rồi-quên với [HabitTracking]: mọi lời gọi bọc trong
/// try/catch + `.catchError` + `unawaited`, nên một lần tracking hỏng không bao
/// giờ làm gãy cuộc hội thoại nó bám vào.
///
/// **Không bao giờ gửi chữ người đọc gõ.** Câu chuyện họ kể, câu cam kết họ
/// viết, ghi chú kèm đánh giá — tất cả ở lại trong phiên. Ra ngoài chỉ có lựa
/// chọn dạng scalar (chip nào, thumb nào) và độ dài, đủ để đo mà không mang
/// theo nội dung.
class CoachTracking {
  const CoachTracking._();

  static void track(String eventName, {Map<String, dynamic>? parameters}) {
    final eventParameters = <String, dynamic>{...?parameters}..removeWhere((_, value) => value == null);

    try {
      final trackingService = AppService.instance.appTrackingService;
      unawaited(trackingService.trackEvent(eventName, parameters: eventParameters).catchError((_) {}));
    } catch (_) {
      return;
    }
  }

  static void setUserProperties(Map<String, dynamic> properties) {
    final props = <String, dynamic>{...properties}..removeWhere((_, value) => value == null || (value is String && value.trim().isEmpty));
    if (props.isEmpty) return;

    try {
      final trackingService = AppService.instance.appTrackingService;
      unawaited(trackingService.setUserProperties(props).catchError((_) {}));
    } catch (_) {
      return;
    }
  }

  /// Khối định danh đi kèm MỌI event trong phiên.
  ///
  /// `session_id` là id của server, nên một hàng ở Firebase ghép thẳng được với
  /// `coach_sessions` bên hddhistory-api — không phải suy ra phiên từ dấu thời gian.
  static Map<String, dynamic> sessionParams(CoachState state) {
    return {
      'session_id': state.sessionId,
      'entry': state.entry.raw,
      'step': state.step,
    };
  }

  static String _snake(String key) => key.replaceAllMapped(RegExp('[A-Z]'), (match) => '_${match[0]!.toLowerCase()}');

  /// Câu trả lời của một lượt, đã lọc.
  ///
  /// Danh sách cho phép chứ không phải danh sách cấm: một `kind` mới thêm sau
  /// này mặc định KHÔNG lọt ra ngoài, thay vì lọt cho tới khi có người nhớ ra.
  static Map<String, dynamic> _answerParams(Map<String, dynamic> payload) {
    const allowed = <String>{
      'answer',
      'accept',
      'deep',
      'again',
      'task',
      'done',
      'quizAnswer',
      'value',
      'courseAction',
      'keepGoing',
      'thumb',
      'ratingSkipped',
      'met',
      'retry',
      'mood',
      'reminderEnabled',
      'reminderDays',
      'reminderHour',
    };

    final params = <String, dynamic>{};
    for (final entry in payload.entries) {
      if (!allowed.contains(entry.key)) continue;
      final value = entry.value;
      if (value is String || value is num || value is bool) params[_snake(entry.key)] = value;
    }

    // Chữ của họ chỉ ra ngoài dưới dạng một con số.
    final text = payload['text'];
    if (text is String) params['text_len'] = text.length;

    // Chip lý do của 👎 là một danh sách ĐÓNG gồm 5 id do app đặt sẵn
    // (missed_the_point · too_generic · too_long · voice_mismatch ·
    // imposed_thinking), không phải chữ người đọc gõ — nên gửi cả id, nối bằng
    // dấu phẩy theo đúng lệ của các event khác. Đây là tín hiệu "vì sao Coach
    // trả lời hỏng", mà đếm số lượng thôi thì không trả lời được.
    final chips = payload['chips'];
    if (chips is List) {
      params['chip_count'] = chips.length;
      params['chip_list'] = chips.whereType<String>().join(',');
    }

    final quiz = payload['quizResults'];
    if (quiz is List) {
      params['quiz_count'] = quiz.length;
      params['quiz_passed'] = quiz.where((item) => item is Map && item['passed'] == true).length;
    }

    return params;
  }

  //* Cửa vào — bong bóng trên shell
  static void bubbleView(CoachEntry entry, {required bool dot, required bool teaser}) {
    track(TrackingKey.coachBubbleView, parameters: {'entry': entry.raw, 'has_dot': dot, 'has_teaser': teaser});
  }

  static void bubbleClick(CoachEntry entry, {required bool dot}) {
    track(TrackingKey.coachBubbleClick, parameters: {'entry': entry.raw, 'has_dot': dot});
  }

  //* Cửa vào — màn mời sau keypoint (luồng 2/3)
  static Map<String, dynamic> _inviteParams({
    required String lessonId,
    required String keypointId,
    required String courseId,
    required bool isCourseDone,
  }) {
    return {
      'lesson_id': lessonId,
      'keypoint_id': keypointId,
      'course_id': courseId,
      'is_course_done': isCourseDone,
    };
  }

  static void inviteScrView({
    required String lessonId,
    required String keypointId,
    required String courseId,
    required bool isCourseDone,
  }) {
    track(
      TrackingKey.coachInviteScrView,
      parameters: _inviteParams(lessonId: lessonId, keypointId: keypointId, courseId: courseId, isCourseDone: isCourseDone),
    );
  }

  static void inviteAccept({
    required String lessonId,
    required String keypointId,
    required String courseId,
    required bool isCourseDone,
  }) {
    track(
      TrackingKey.coachInviteAccept,
      parameters: _inviteParams(lessonId: lessonId, keypointId: keypointId, courseId: courseId, isCourseDone: isCourseDone),
    );
  }

  static void inviteLater({
    required String lessonId,
    required String keypointId,
    required String courseId,
    required bool isCourseDone,
  }) {
    track(
      TrackingKey.coachInviteLater,
      parameters: _inviteParams(lessonId: lessonId, keypointId: keypointId, courseId: courseId, isCourseDone: isCourseDone),
    );
  }

  //* Vòng đời phiên
  static void scrView({
    required CoachEntry entry,
    required String sessionId,
    required String step,
    required bool resumed,
    required bool reopened,
  }) {
    track(
      TrackingKey.coachScrView,
      parameters: {
        'entry': entry.raw,
        'session_id': sessionId,
        'step': step,
        // Phiên nối tiếp phiên đang dở, phân biệt với phiên mới tinh.
        'is_resumed': resumed,
        // Mở lại tự động sau khi phiên hết hạn 48h — lọc ra khỏi funnel để
        // không đếm thành một lần người đọc chủ động mở.
        'is_reopen': reopened,
      },
    );
  }

  static void openSilent(CoachEntry entry, {String? reasonKey}) {
    track(TrackingKey.coachOpenSilent, parameters: {'entry': entry.raw, 'reason_key': reasonKey ?? ''});
  }

  static void openFailed(CoachEntry entry) {
    track(TrackingKey.coachOpenFailed, parameters: {'entry': entry.raw});
  }

  static void scrExit(CoachState state, {required int turnCount, required int durationSec}) {
    track(
      TrackingKey.coachScrExit,
      parameters: {
        ...sessionParams(state),
        'turn_count': turnCount,
        'duration_sec': durationSec,
        // Server đã khép phiên (đi hết đường) hay người đọc tự đóng giữa chừng.
        'is_ended': state.ended,
      },
    );
  }

  //* Từng lượt — bắn từ đúng một chỗ nghẽn
  static void turnSend(CoachState state, {required String kind, required Map<String, dynamic> payload}) {
    track(TrackingKey.coachTurnSend, parameters: {...sessionParams(state), 'kind': kind, ..._answerParams(payload)});
  }

  static void turnFailed(CoachState state, {required String kind, String? errorType}) {
    track(TrackingKey.coachTurnFailed, parameters: {...sessionParams(state), 'kind': kind, 'error_type': errorType ?? ''});
  }

  static void sessionExpired(CoachState state, {required String kind}) {
    track(TrackingKey.coachSessionExpired, parameters: {...sessionParams(state), 'kind': kind});
  }

  //* Các bề mặt trong phiên
  static void courseCardView(CoachState state) {
    track(TrackingKey.coachCourseCardView, parameters: {...sessionParams(state), 'course_id': state.ui.course?.courseId ?? ''});
  }

  static void ratingView(CoachState state) => track(TrackingKey.coachRatingView, parameters: sessionParams(state));

  static void safetyView(CoachState state) => track(TrackingKey.coachSafetyView, parameters: sessionParams(state));

  static void sceneScoreView(CoachState state) {
    track(TrackingKey.coachSceneScoreView, parameters: {...sessionParams(state), 'retry_available': state.ui.score?.retryAvailable ?? false});
  }

  static void quizRun(CoachState state, {required int questionCount}) {
    track(TrackingKey.coachQuizRun, parameters: {...sessionParams(state), 'question_count': questionCount});
  }

  static void micStart(CoachState state, {required bool granted}) {
    track(TrackingKey.coachMicStart, parameters: {...sessionParams(state), 'granted': granted});
  }

  static void micDone(CoachState state, {required bool hasText}) {
    track(TrackingKey.coachMicDone, parameters: {...sessionParams(state), 'has_text': hasText});
  }

  //* Luồng 6 — lời níu khi đóng giữa chừng
  static void exitPleaView(CoachState state) => track(TrackingKey.coachExitPleaView, parameters: sessionParams(state));

  static void exitStay(CoachState state) => track(TrackingKey.coachExitStay, parameters: sessionParams(state));

  static void exitLeave(CoachState state) => track(TrackingKey.coachExitLeave, parameters: sessionParams(state));

  //* User properties — cắt được cohort "người dùng Coach" ở MỌI report khác,
  //* không riêng các event coach_*.
  static void profile({String? persona, DateTime? lastSessionAt}) {
    setUserProperties({
      'coach_persona': persona,
      'coach_last_session_at': lastSessionAt == null ? null : DateFormat('yyyy-MM-dd').format(lastSessionAt),
    });
  }
}
