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
  final SetCoachPersonaUseCase _setPersona;

  CoachCubit(this._openSession, this._sendTurn, this._closeSession, this._explainAgain, this._setPersona) : super(const CoachState());

  CoachEntry _entry = CoachEntry.home;
  String? _lessonId;
  String? _habitId;
  String _locale = 'en';

  /// Resolves a fixed line's slang key, filling in the reader's own words
  /// (`args`) where the line quotes them. Injected by the sheet, which is the
  /// only place with a BuildContext — keeping `context.l10n` out of the cubit
  /// is what lets the same cubit be driven from a test with no widget tree.
  String Function(String key, Map<String, String> args)? promptResolver;

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

    emit(state.copyWith(status: CoachStatus.opening, entry: entry, messages: const []));

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

  /// ②A — three equal buttons. The label is echoed so the thread shows what
  /// was answered; the server decides which branch it opens.
  Future<void> answerIntent(String answer, String label) => _send({'kind': 'intent', 'answer': answer}, userLine: label);

  /// ②A after "có dịp mà chưa làm" — make the commitment smaller, or keep it.
  Future<void> answerShrinkAsk({required bool accept, required String label}) => _send({'kind': 'shrink', 'accept': accept}, userLine: label);

  /// ② "hoặc bỏ qua" — the story step's second way out.
  Future<void> skipStory(String label) => _send({'kind': 'skip'}, userLine: label);

  /// "Bạn muốn chia sẻ thêm không?" — `Kể sâu hơn` runs the 5-beat script,
  /// `Chỉ ghi lại thôi` files the sentence they already wrote and skips
  /// straight to the commitment question.
  Future<void> answerDepth({required bool deep, required String label}) =>
      _send({'kind': 'depth', 'deep': deep}, userLine: label);

  /// The same pill, tapped later inside the script: file it and move on.
  Future<void> fileItInstead(String label) => _send({'kind': 'ack'}, userLine: label);

  /// Nhịp 4 of the scene — "Nói lại" answers the same scene a second time,
  /// "Đủ rồi" closes it. The beat that makes the task practice rather than one
  /// question and one answer.
  Future<void> answerSceneAgain({required bool again, required String label}) =>
      _send({'kind': 'sceneAgain', 'again': again}, userLine: label);

  /// Thanh habit — "đổi": the Coach lists the reader's own kho and puts them
  /// back on the step they were on. Never refused.
  Future<void> changeHabit(String label) =>
      _send({'kind': 'changeHabit'}, userLine: label);

  /// Bộ điều phối — start a task by name. The registry decides whether it is
  /// still allowed; a refused one comes back as an error rather than a guess.
  Future<void> pickTask(String task, {required String label}) =>
      _send({'kind': 'task', 'task': task}, userLine: label);

  /// Bộ điều phối — "Mình dừng ở đây": card → the one commitment offer → tail.
  Future<void> stopSession(String label) => _send({'kind': 'stop'}, userLine: label);

  /// Nhịp 6 — "Chuyện giống vậy bạn gặp bao giờ chưa?". "Gặp rồi" collects the
  /// occasion the commitment needs; "Chưa gặp" moves on without a word about it.
  Future<void> answerSceneMet({required bool met, required String label}) =>
      _send({'kind': 'sceneMet', 'met': met}, userLine: label);

  /// ★ — practise one situation, or not. Never required.
  Future<void> answerInvite({required bool accept, required String label}) => _send({'kind': 'invite', 'accept': accept}, userLine: label);

  /// Tầng 4 — the rubric card. "Thử lại tình huống này" replays the SAME scene
  /// once; anything else moves on to the commitment.
  Future<void> answerSceneScore({required bool retry, required String label}) =>
      _send({'kind': 'sceneScore', 'retry': retry}, userLine: label);

  /// "Muốn đặt Nhắc hẹn không?" — the commitment is optional at every door.
  Future<void> answerPlanAsk({required bool accept, required String label}) => _send({'kind': 'planAsk', 'accept': accept}, userLine: label);

  /// The course card's three ways out. "Đi tới khoá học" earns one short
  /// line and a LEAVE step; the END button then hands the course id back to
  /// whoever opened the sheet.
  Future<void> courseAction(String action, {String? label}) => _send({'kind': 'course', 'courseAction': action}, userLine: label);

  /// "Dừng phiên hay bắt đầu phiên mới?" — two equal buttons.
  Future<void> nextSession({required bool again, required String label}) => _send({'kind': 'nextSession', 'again': again}, userLine: label);

  /// The voice, from the header, at any step. Not a turn: nothing in the flow
  /// moves, so the state is updated first and the server told after.
  Future<void> setPersona(String persona) async {
    if (persona == state.persona) return;
    emit(state.copyWith(persona: persona));
    if (state.sessionId.isEmpty) return;

    await _setPersona(sessionId: state.sessionId, persona: persona).run();
  }

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
    List<int>? customDays,
    String? date,
  }) => _send({
    'kind': 'schedule',
    'reminderEnabled': enabled,
    'reminderHour': ?hour,
    'reminderMinute': ?minute,
    'reminderDays': ?days,
    'reminderCustomDays': ?customDays,
    'reminderDate': ?date,
  }, userLine: label);

  Future<void> loop({required bool keepGoing, required String label}) => _send({'kind': 'loop', 'keepGoing': keepGoing}, userLine: label);

  /// The toast's answer. Nothing is echoed into the thread — the toast rates
  /// the whole session and closes; a line in the chat would make it a turn.
  Future<void> rate({String? thumb, List<String>? chips, String? note}) => _send({
    'kind': 'rating',
    'thumb': ?thumb,
    'chips': ?chips,
    'ratingNote': ?(note == null || note.isEmpty ? null : note),
    'ratingSkipped': thumb == null,
  });

  /// A parked session on a retired step (depth, context) still needs its one
  /// answer sent; the server routes it back onto the spine.
  Future<void> sendRetired(Map<String, dynamic> payload, {String? label}) => _send(payload, userLine: label);

  /// ⑤ — "Không đúng với mình". The draft was not theirs at all: it is
  /// thrown away and the Coach asks to hear the story again. Once only.
  Future<void> rejectDraft(String label) => _send({'kind': 'rejectDraft'}, userLine: label);

  /// "Giải thích đơn giản hơn" — counted against the CONTENT, not the reader.
  /// Fire-and-forget: a failed count must not interrupt the conversation.
  Future<void> explainAgain(String keypointId) async {
    await _explainAgain(keypointId).run();
  }

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

  /// One reply split on blank lines, never empty for a reply that says anything.
  static List<String> _paragraphs(String reply) {
    final parts = reply
        .split(RegExp(r'\n\s*\n'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    return parts.isEmpty ? [reply.trim()] : parts;
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
      // `speaker` set means this line was said IN CHARACTER by the scene's other
      // person, so the bubble is labelled with their name.
      //
      // A reply written as paragraphs — nhịp 4's idea and then nhịp 5's one
      // piece of praise — arrives as ONE string with a blank line in it, and
      // each paragraph becomes its own bubble: "chat ra nhiều đoạn để dễ hiểu,
      // không phải chat 1 cục lớn".
      for (final part in _paragraphs(turn.reply!)) {
        messages.add(CoachMessage(isCoach: true, text: part, speaker: turn.speaker));
      }
    }

    // A fixed line before the step's own — "Đó là câu của bạn, mình không
    // sửa.", "Bạn vừa thêm “…”. Một cảnh ngắn:". Some quote the reader's or
    // the habit's words, so the args travel to it too.
    final note = turn.noteKey == null ? null : promptResolver?.call(turn.noteKey!, turn.promptArgs);
    final situation = turn.ui.situation;

    // The note is its own bubble — "Bạn vừa thêm “X”." · "Tình huống này bạn
    // từng gặp ba tuần trước…" — and the scene follows in a second one. At ①
    // the scene bubble opens with "Một cảnh ngắn:" so the two read as one
    // thought split in two, not two unrelated lines.
    if (note != null && note.isNotEmpty) {
      messages.add(CoachMessage(isCoach: true, text: note));
    }
    // The scene arrives split — habit · setup · question — and goes into the
    // thread as separate short bubbles with bold headings. One 60-word block
    // read as a wall of text. Older payloads (no `scene`) keep the single bubble.
    final scene = turn.ui.scene;
    if (scene != null) {
      final habit = scene.habit;
      if (habit != null && habit.isNotEmpty) {
        messages.add(
          CoachMessage(
            isCoach: true,
            title: promptResolver?.call('coach.scene.habitLabel', const {}),
            text: habit,
          ),
        );
      }
      // The led scene's second beat carries only the question — the setup is
      // already in the thread, so an empty one gets no bubble.
      if (scene.setup.isNotEmpty) {
        messages.add(
          CoachMessage(
            isCoach: true,
            title: promptResolver?.call('coach.scene.setupLabel', const {}),
            text: scene.setup,
          ),
        );
      }
      if (scene.question != null) {
        messages.add(CoachMessage(isCoach: true, text: scene.question!, emphasis: true));
      }
    } else if (situation != null) {
      final lead = turn.noteKey == 'coach.prompt.lessonIntro' ? promptResolver?.call('coach.prompt.sceneLead', const {}) : null;
      messages.add(CoachMessage(isCoach: true, text: lead == null || lead.isEmpty ? situation : '$lead $situation'));
    }

    // The step's fixed line — unless the scene just closed with its own
    // question. A scene shown WITHOUT one (the feeling beat holds it back) is
    // followed by the step's question, emphasised like a scene question is.
    final sceneAskedItsOwn = scene != null ? scene.question != null : situation != null;
    if (!sceneAskedItsOwn && turn.promptKey != null) {
      final resolved = promptResolver?.call(turn.promptKey!, turn.promptArgs);
      if (resolved != null && resolved.isNotEmpty) {
        messages.add(CoachMessage(isCoach: true, text: resolved, emphasis: scene != null));
      }
    }

    return base.copyWith(
      sessionId: turn.sessionId,
      step: turn.step,
      persona: turn.persona,
      messages: messages,
      ui: turn.ui,
      courseInvite: turn.courseInvite,
      columnLeft: turn.ui.columnLeft.isNotEmpty ? turn.ui.columnLeft : base.columnLeft,
      columnRight: turn.ui.columnRight.isNotEmpty ? turn.ui.columnRight : base.columnRight,
      ended: turn.ended,
    );
  }
}
