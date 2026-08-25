part of '../../coach.dart';

/// One conversation.
///
/// Holds no state machine of its own — every step, every composer, every
/// transition comes from the server, and this only renders what it is handed
/// and posts back what the reader did. That is deliberate: the rules this
/// feature runs on are rules about what gets written, and a second copy of them
/// here would drift from the first one the week after it shipped.
@injectable
class CoachCubit extends Cubit<CoachState> {
  final OpenCoachSessionUseCase _openSession;
  final SendCoachTurnUseCase _sendTurn;
  final CloseCoachSessionUseCase _closeSession;
  final ExplainAgainUseCase _explainAgain;

  CoachCubit(this._openSession, this._sendTurn, this._closeSession, this._explainAgain) : super(const CoachState());

  CoachEntry _entry = CoachEntry.home;
  String? _lessonId;
  String? _habitId;
  String _locale = 'en';

  /// Resolves a fixed line's slang key. Injected by the sheet, which is the
  /// only place with a BuildContext — keeping `context.l10n` out of the cubit
  /// is what lets the same cubit be driven from a test with no widget tree.
  String Function(String key)? promptResolver;

  Future<void> open({
    required CoachEntry entry,
    required String locale,
    String? lessonId,
    String? habitId,
  }) async {
    _entry = entry;
    _lessonId = lessonId;
    _habitId = habitId;
    _locale = locale;

    emit(state.copyWith(status: CoachStatus.opening, messages: const []));

    final result = await _openSession(
      entry: entry,
      lessonId: lessonId,
      habitId: habitId,
      locale: locale,
      tzOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
    ).run();

    result.match(
      (_) => emit(state.copyWith(status: CoachStatus.failed)),
      (turn) {
        if (turn.silent) {
          emit(
            state.copyWith(
              status: CoachStatus.closed,
              silent: true,
              silentReasonKey: turn.reasonKey,
            ),
          );

          return;
        }

        // A resumed session arrives with its thread; a new one starts empty.
        emit(
          _applyTurn(
            state.copyWith(status: CoachStatus.ready, messages: turn.replay),
            turn,
            userLine: null,
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------ events

  /// Every answer the reader gives is echoed back as their own bubble, chips
  /// included. Without the label the thread reads as the Coach talking to
  /// itself — three questions in a row with nothing between them.
  Future<void> pickMood(int value, String label) => _send({'kind': 'mood', 'mood': value}, userLine: label);

  Future<void> pickMoodEnd(int value, String label) => _send({'kind': 'moodEnd', 'mood': value}, userLine: label);

  Future<void> pickNewHabit(String habitId, String label) => _send({'kind': 'pickNew', 'habitId': habitId}, userLine: label);

  Future<void> pickHabit(String habitId, String label) => _send({'kind': 'pickHabit', 'habitId': habitId}, userLine: label);

  Future<void> pickPersona(String persona, String label) => _send({'kind': 'persona', 'persona': persona}, userLine: label);

  Future<void> pickScript(String script, String label) => _send({'kind': 'time', 'script': script}, userLine: label);

  Future<void> answerIntent(String answer, String label) => _send({'kind': 'intent', 'answer': answer}, userLine: label);

  Future<void> answerCheckin(bool used, String label) => _send({'kind': 'checkin', 'used': used}, userLine: label);

  Future<void> submitText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return Future.value();

    return _send({'kind': 'text', 'text': trimmed}, userLine: trimmed);
  }

  /// ⑦ — submit the sentence, carrying the columns as the reader arranged them
  /// so the server records what they actually pulled across.
  Future<void> submitProblemStatement(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return Future.value();

    return _send(
      {
        'kind': 'text',
        'text': trimmed,
        'leftLines': state.columnLeft,
        'rightLines': state.columnRight,
      },
      userLine: trimmed,
    );
  }

  Future<void> savePlan({required String context, required String action}) {
    if (context.trim().isEmpty || action.trim().isEmpty) return Future.value();

    return _send(
      {
        'kind': 'plan',
        'planContext': context.trim(),
        'planAction': action.trim(),
      },
      userLine: '${context.trim()} — ${action.trim()}',
    );
  }

  Future<void> saveSchedule({
    required bool enabled,
    required String label,
    int? hour,
    int? minute,
    String? days,
  }) => _send({
    'kind': 'schedule',
    'reminderEnabled': enabled,
    'reminderHour': ?hour,
    'reminderMinute': ?minute,
    'reminderDays': ?days,
  }, userLine: label);

  Future<void> loop({required bool keepGoing, required String label}) => _send({'kind': 'loop', 'keepGoing': keepGoing}, userLine: label);

  Future<void> rate({String? thumb, List<String>? chips, String? label}) => _send({
    'kind': 'rating',
    'thumb': ?thumb,
    'chips': ?chips,
    'ratingSkipped': thumb == null,
  }, userLine: label);

  /// ⑧ — "Không đúng với mình". The draft was not theirs at all, so it is
  /// thrown away and they write both columns themselves. The Coach does not
  /// get a second attempt.
  Future<void> rejectDraft(String label) => _send({'kind': 'rejectDraft'}, userLine: label);

  /// Nhịp 5 is the Coach speaking, not asking. One tap moves past it.
  Future<void> acknowledge() => _send({'kind': 'ack'});

  /// "Giải thích đơn giản hơn" — counted against the CONTENT, not the reader.
  /// Fire-and-forget: a failed count must not interrupt the conversation.
  Future<void> explainAgain(String keypointId) async {
    await _explainAgain(keypointId).run();
  }

  /// ⑥ — a small line, never a big button. Placement is the widget's job; this
  /// only sends it.
  Future<void> takeEscape() => _send({'kind': 'escape'});

  /// ⑦ — move a line between columns. Purely local until the sentence is sent.
  /// ⑦ — move one drafted line to the other column.
  ///
  /// Addressed by index rather than by text: the model can draft two lines that
  /// read the same, and matching on the string moved both of them.
  void moveLine(int index, {required bool fromRight}) {
    final source = [...(fromRight ? state.columnRight : state.columnLeft)];
    if (index < 0 || index >= source.length) return;

    final line = source.removeAt(index);
    final target = [...(fromRight ? state.columnLeft : state.columnRight), line];

    emit(
      state.copyWith(
        columnLeft: fromRight ? target : source,
        columnRight: fromRight ? source : target,
      ),
    );
  }

  /// The reader rewrote a line the model got wrong.
  ///
  /// The whole exercise rests on the lines being their words; a garbled one they
  /// cannot correct is the model still holding the pen.
  void editLine(int index, {required bool inRight, required String text}) {
    final lines = [...(inRight ? state.columnRight : state.columnLeft)];
    if (index < 0 || index >= lines.length) return;

    lines[index] = text;
    emit(
      state.copyWith(
        columnLeft: inRight ? state.columnLeft : lines,
        columnRight: inRight ? lines : state.columnRight,
      ),
    );
  }

  /// A line that was never theirs at all. Dropping it is not the same as ⑧:
  /// that rejects the whole draft, this is one bad row.
  void deleteLine(int index, {required bool inRight}) {
    final lines = [...(inRight ? state.columnRight : state.columnLeft)];
    if (index < 0 || index >= lines.length) return;

    lines.removeAt(index);
    emit(
      state.copyWith(
        columnLeft: inRight ? state.columnLeft : lines,
        columnRight: inRight ? lines : state.columnRight,
      ),
    );
  }

  /// Tell the server the sheet is done.
  ///
  /// Deliberately NOT named `close`: that is `Cubit`'s own lifecycle method,
  /// and shadowing it would quietly stop the bloc from ever being disposed
  /// while looking exactly like this code.
  Future<void> endSession() async {
    final id = state.sessionId;
    emit(state.copyWith(status: CoachStatus.closed));
    if (id.isEmpty) return;

    await _closeSession(id).run();
  }

  // ------------------------------------------------------------------ plumbing

  Future<void> _send(Map<String, dynamic> payload, {String? userLine}) async {
    if (state.typing || state.sessionId.isEmpty) return;

    emit(
      state.copyWith(
        status: CoachStatus.sending,
        typing: true,
        messages: userLine == null ? state.messages : [...state.messages, CoachMessage(isCoach: false, text: userLine)],
      ),
    );

    final result = await _sendTurn(sessionId: state.sessionId, payload: payload).run();

    await result.match(
      (error) async {
        // The session expired under us — the 48h TTL that makes "close the
        // sheet and it's gone" a property of the database. Reopen rather than
        // report: the reader did nothing wrong and has nothing to fix.
        if (error.message == CoachRepository.sessionExpiredCode) {
          emit(state.copyWith(typing: false));
          await open(
            entry: _entry,
            locale: _locale,
            lessonId: _lessonId,
            habitId: _habitId,
          );

          return;
        }

        emit(state.copyWith(status: CoachStatus.failed, typing: false));
      },
      (turn) async => emit(
        _applyTurn(state.copyWith(status: CoachStatus.ready, typing: false), turn, userLine: null),
      ),
    );
  }

  /// Fold one server turn into the state.
  ///
  /// The reply and the next step's prompt are two different lines and both may
  /// arrive together — the reply answers what was just said, the prompt asks
  /// the next thing. Appending them in that order is what makes the thread read
  /// like a conversation rather than a form.
  CoachState _applyTurn(CoachState base, CoachTurnEntity turn, {String? userLine}) {
    final messages = [...base.messages];

    if (userLine != null) {
      messages.add(CoachMessage(isCoach: false, text: userLine));
    }
    if (turn.reply != null) {
      messages.add(CoachMessage(isCoach: true, text: turn.reply!));
    }

    // A situation IS the Coach's line at that step — there is no separate
    // prompt to show alongside it.
    final situation = turn.ui.situation;
    if (situation != null) {
      messages.add(CoachMessage(isCoach: true, text: situation));
    } else if (turn.promptKey != null) {
      final resolved = promptResolver?.call(turn.promptKey!);
      if (resolved != null && resolved.isNotEmpty) {
        messages.add(CoachMessage(isCoach: true, text: resolved));
      }
    }

    return base.copyWith(
      sessionId: turn.sessionId,
      step: turn.step,
      messages: messages,
      ui: turn.ui,
      courseInvite: turn.courseInvite,
      columnLeft: turn.ui.columnLeft.isNotEmpty ? turn.ui.columnLeft : base.columnLeft,
      columnRight: turn.ui.columnRight.isNotEmpty ? turn.ui.columnRight : base.columnRight,
      ended: turn.ended,
    );
  }
}
