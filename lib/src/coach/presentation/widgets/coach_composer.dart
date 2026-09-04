part of '../../coach.dart';

/// The bottom of the sheet: white, hairline on top, and whatever the current
/// step is answered with — drawn as `MeUp AI Coach.html` (v2) draws it.
///
/// Switches on [CoachUiKind] and nothing else. There is no step logic here and
/// no branching on what the reader said — the server decided both, and a second
/// opinion in this file is exactly how the two would drift apart.
class CoachComposer extends StatefulWidget {
  final CoachState state;
  final CoachCubit cubit;

  const CoachComposer({super.key, required this.state, required this.cubit});

  @override
  State<CoachComposer> createState() => _CoachComposerState();
}

class _CoachComposerState extends State<CoachComposer> {
  final _text = TextEditingController();
  final _planContext = TextEditingController();
  final _planAction = TextEditingController();
  final _ratingOther = TextEditingController();

  late final CoachRecorder _recorder = AppDI.injector.get<CoachRecorder>();
  bool _listening = false;

  /// Schedule — the three hours the design offers, and the days.

  /// "tự chọn" — ISO weekdays 1 (Mon) … 7 (Sun).

  /// Rating: the second toast opens only after 👎.
  bool _thumbDown = false;
  final Set<String> _ratingChips = {};

  /// The key the PLAN form's scene pre-fill was last applied for, so a rebuild
  /// mid-edit does not overwrite what the reader has started typing.
  String? _planFilledFor;

  /// The five moods, one glyph each — "emoji kèm chữ, một chạm". Glyphs are not
  /// words, so they live here rather than in five YAML files.

  @override
  void initState() {
    super.initState();
    // A sheet reopened mid-session lands straight on the form: the pre-fill
    // has to apply here too, not only on the step change into it.
    _applyPlanPrefill();
    // The save button lights up only when both fields hold something — the
    // form arrives EMPTY by design now, and a pale button that silently
    // ignored taps read as broken (owner, 2026-08-28).
    _planContext.addListener(_onPlanEdited);
    _planAction.addListener(_onPlanEdited);
  }

  void _onPlanEdited() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant CoachComposer oldWidget) {
    super.didUpdateWidget(oldWidget);

    _applyPlanPrefill();

    if (widget.state.step != oldWidget.state.step) {
      _thumbDown = false;
      _ratingChips.clear();
      _ratingOther.clear();
    }
  }

  /// PLAN — drop the server's suggestion into the form once, so the reader
  /// edits rather than retypes: the move for next time (from the scene, or the
  /// old wording at SHRINK) and its "khi nào". Both stay editable.
  void _applyPlanPrefill() {
    final suggested = widget.state.ui.suggested;
    final planKey = '${widget.state.sessionId}:${widget.state.step}:${widget.state.messages.length}';
    if (widget.state.ui.kind == CoachUiKind.plan && suggested != null && !suggested.isEmpty && _planFilledFor != planKey) {
      _planFilledFor = planKey;
      if (suggested.context.isNotEmpty) _planContext.text = suggested.context;
      if (suggested.action.isNotEmpty) _planAction.text = suggested.action;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _planContext.dispose();
    _planAction.dispose();
    _ratingOther.dispose();
    unawaited(_recorder.cancel());
    super.dispose();
  }

  /// Kinds whose composer is a text box: they draw their own two-layer chrome
  /// (suggestion pills on the sheet's ground, the input row in a white bar),
  /// exactly as the design's screens stack them.
  static const _textKinds = {
    CoachUiKind.text,
    CoachUiKind.textSkippable,
    CoachUiKind.depth,
    CoachUiKind.hub,
    // Nhịp 3 answers in a text box too, and `_twoCols` builds it with
    // `_textArea` — which draws the white bar and the safe-area gap itself.
    // Left out of this set, it got a SECOND bar and a second bottom inset
    // wrapped around it by build(): the broken footer under the two-column
    // draft (bug sheet 2026-08-28 16:18).
    CoachUiKind.twoCols,
    CoachUiKind.sceneScore,
    CoachUiKind.nextAction,
    CoachUiKind.closing,
    CoachUiKind.shrink,
  };

  double _bottomInset(BuildContext context) =>
      MediaQuery.viewInsetsOf(context).bottom > 0 ? 12.h : 20.h + MediaQuery.viewPaddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final busy = state.typing;

    // ⟨Phương án⟩, the mood row, the closing choice and the course card's own
    // buttons all live IN the thread now — those screens have no input area at
    // all in the design, only the safe-area gap.
    if (state.ui.kind == CoachUiKind.chips ||
        state.ui.kind == CoachUiKind.nextSession ||
        state.ui.kind == CoachUiKind.courseCard) {
      return SizedBox(height: MediaQuery.viewPaddingOf(context).bottom);
    }

    // Text kinds carry their own chrome (see `_textArea`).
    if (_textKinds.contains(state.ui.kind)) return _body(context, state, busy);

    return Container(
      padding: EdgeInsets.fromLTRB(15.w, 11.h, 15.w, _bottomInset(context)),
      decoration: const BoxDecoration(
        color: CoachStyle.surface,
        border: Border(top: BorderSide(color: CoachStyle.border)),
      ),
      child: _body(context, state, busy),
    );
  }

  Widget _body(BuildContext context, CoachState state, bool busy) {
    switch (state.ui.kind) {
      // ⟨Phương án⟩ render in the thread (`_OptionPills`); build() never routes
      // this kind here, but the switch must stay total.
      case CoachUiKind.chips:
        return const SizedBox.shrink();
      case CoachUiKind.textSkippable:
        return _story(context, state, busy);
      case CoachUiKind.depth:
        return _depth(context, state, busy);
      case CoachUiKind.hub:
        return _hub(context, state, busy);
      case CoachUiKind.twoCols:
        return _twoCols(context, state, busy);
      case CoachUiKind.plan:
        return _plan(context, busy);
      case CoachUiKind.schedule:
        return _schedule(context, busy);
      // In the thread now — see build().
      case CoachUiKind.courseCard:
        return const SizedBox.shrink();
      case CoachUiKind.rating:
        return _rating(context, busy);
      case CoachUiKind.nextSession:
        return const SizedBox.shrink();
      case CoachUiKind.end:
        return _end(context, state, busy);
      case CoachUiKind.safety:
        return const SizedBox.shrink();
      // Retired composers a parked session may still be on — a text box lets
      // them finish; the server routes the answer back onto the spine. The
      // rubric card joined them on 2026-08-27 when scoring was cut.
      case CoachUiKind.text:
        return _telling(context, state, busy);
      case CoachUiKind.sceneScore:
      case CoachUiKind.nextAction:
      case CoachUiKind.closing:
      case CoachUiKind.shrink:
        return _textArea(context, state, busy, onSubmit: widget.cubit.submitText);
    }
  }

  // --- story -----------------------------------------------------------

  /// "Hôm nay có chuyện gì mới không?" — the text box, and "Không có gì đặc
  /// biệt" as the FIRST suggestion. Skipping is a real answer here, not a
  /// failure to answer, and the design puts it in the same row as the other
  /// ways in rather than as a separate way out.
  Widget _story(BuildContext context, CoachState state, bool busy) {
    final l10n = context.l10n.coach;

    return _textArea(
      context,
      state,
      busy,
      onSubmit: widget.cubit.submitText,
      leadingChips: [
        _SampleChip(
          label: l10n.storySkip,
          onTap: busy ? null : () => widget.cubit.skipStory(l10n.storySkipEcho),
        ),
        // ②B — "hoặc chọn habit muốn bàn". A ⟨Gợi ý⟩, deliberately not an
        // option: "giữ kể trước, xếp sau làm đường chính, ai muốn chọn chủ đề
        // trước thì vẫn có lối". Gone once the habit is settled, because then
        // the chip above already says which one and carries its own "đổi".
        if (state.ui.habit == null)
          _SampleChip(
            label: l10n.storyPickHabit,
            onTap: busy
                ? null
                : () => widget.cubit.changeHabit(l10n.storyPickHabitEcho),
          ),
      ],
    );
  }

  /// Nhịp 2 — the Coach's one question back, answered in free text.
  ///
  /// "Chỉ ghi lại thôi" rides along: the pills are shortcuts that stay reachable
  /// through the script ("hai pill ở lại suốt phiên"), and tapping one always
  /// beats what the Coach guessed. Only offered while the script is running —
  /// the scene's own answer box has no pills, by design.
  Widget _telling(BuildContext context, CoachState state, bool busy) {
    final l10n = context.l10n.coach;

    return _textArea(
      context,
      state,
      busy,
      onSubmit: widget.cubit.submitText,
      leadingChips: [
        if (state.step == 'tell2')
          _SampleChip(
            label: l10n.depthShallow,
            onTap: busy ? null : () => widget.cubit.fileItInstead(l10n.depthShallow),
          ),
      ],
    );
  }

  // --- bộ điều phối --------------------------------------------------------

  /// One Coach line, up to two task suggestions, and the way to stop.
  ///
  /// The pills are ⟨Gợi ý⟩ — shortcuts, never a gate: "ô chat luôn gõ được ·
  /// user gõ tự do → classifier định tuyến". Which two appear is the server's
  /// call (the registry's priority); their words are ours, so they arrive in the
  /// reader's own language.
  Widget _hub(BuildContext context, CoachState state, bool busy) {
    final l10n = context.l10n.coach;
    final labels = <String, String>{
      'T1': l10n.hubTaskT1,
      'T2': l10n.hubTaskT2,
      'T3': l10n.hubTaskT3,
      // The session's result, first in line once a real occasion exists — it
      // must never hide behind "Mình dừng ở đây".
      'T4': l10n.hubTaskT4,
    };

    // Luồng 4: the two pills and the box — "gõ thẳng vào ô chat thì đi luôn
    // nhánh kể chuyện". No "Mình dừng ở đây" pill any more: the sheet's own
    // ⟨Đóng⟩ is the way out (and luồng 6 will be the one to ask them to stay).
    return _textArea(
      context,
      state,
      busy,
      hint: l10n.hubHint,
      onSubmit: widget.cubit.submitText,
      leadingChips: [
        for (final choice in state.ui.choices)
          if (labels.containsKey(choice.value))
            _SampleChip(
              label: labels[choice.value]!,
              onTap: busy
                  ? null
                  : () => widget.cubit.pickTask(
                        choice.value,
                        label: labels[choice.value]!,
                      ),
            ),
      ],
    );
  }

  // --- the depth question ------------------------------------------------

  /// "Bạn muốn chia sẻ thêm không?" — the text box with both pills above it.
  ///
  /// They are SUGGESTIONS, not a gate: typing on is the main road, and the
  /// server reads what was typed for its intent. Same size, same colour, in a
  /// fixed order — "không làm nút kể sâu hơn nổi bật hơn".
  Widget _depth(BuildContext context, CoachState state, bool busy) {
    final l10n = context.l10n.coach;

    return _textArea(
      context,
      state,
      busy,
      onSubmit: widget.cubit.submitText,
      leadingChips: [
        _SampleChip(
          label: l10n.depthDeep,
          onTap: busy ? null : () => widget.cubit.answerDepth(deep: true, label: l10n.depthDeep),
        ),
        _SampleChip(
          label: l10n.depthShallow,
          onTap: busy ? null : () => widget.cubit.answerDepth(deep: false, label: l10n.depthShallow),
        ),
      ],
    );
  }

  // --- nhịp 3 ------------------------------------------------------------

  /// Nhịp 3's composer. The draft itself is a card up in the thread (see the
  /// sheet); down here is only the sentence — "Vấn đề thật của tôi là…" — and
  /// the chips: ⑤ "Không đúng với mình" first, then the model's suggestions.
  /// ⑤ is a chip among the suggestions, exactly where the design puts it:
  /// findable, never dressed as the primary action, and gone after one use.
  Widget _twoCols(BuildContext context, CoachState state, bool busy) {
    final l10n = context.l10n.coach;

    return _textArea(
      context,
      state,
      busy,
      hint: l10n.problemHint,
      onSubmit: (text) => _submitProblem(context, text),
      leadingChips: [
        if (state.ui.rejectAvailable)
          _SampleChip(
            label: l10n.rejectDraft,
            onTap: busy ? null : () => widget.cubit.rejectDraft(l10n.rejectDraftEcho),
          ),
      ],
    );
  }

  /// The sentence is saved whole. The box only asks for its tail, so the
  /// stored line — and the bubble that echoes it — carry the opening words
  /// unless the reader typed them themselves.
  Future<void> _submitProblem(BuildContext context, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return Future.value();
    final prefix = context.l10n.coach.problemPrefix;
    final startsWithPrefix = trimmed.toLowerCase().startsWith(prefix.toLowerCase());
    final sentence = startsWithPrefix ? trimmed : '$prefix $trimmed';

    return widget.cubit.submitProblemStatement(sentence);
  }

  // --- text ------------------------------------------------------------

  /// Suggestions above, the input row below.
  ///
  /// The suggestions exist to lower the cost of the first word: someone looking
  /// at a blank field after being asked something hard closes the sheet. They
  /// fill the box rather than sending, so what goes in is still edited by the
  /// person whose sentence it becomes. [leadingChips] act instead of filling.
  Widget _textArea(
    BuildContext context,
    CoachState state,
    bool busy, {
    required Future<void> Function(String) onSubmit,
    String? hint,
    List<Widget> leadingChips = const [],
  }) {
    final chips = [
      ...leadingChips,
      ...state.ui.samples.map((sample) => _SampleChip(label: sample, onTap: () => _text.text = sample)),
    ];

    // Two layers, as the design stacks every text screen: the suggestion pills
    // ride on the sheet's own ground, and only the input row sits in the white
    // bar underneath.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (chips.isNotEmpty && !busy)
          Padding(
            padding: EdgeInsets.fromLTRB(15.w, 0, 15.w, 10.h),
            // One row that fades at its right edge — the design's `overflow-x`
            // hint that it scrolls, without a scrollbar.
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.black, Colors.black, Colors.transparent],
                stops: [0, 0.88, 1],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: SizedBox(
                height: 34.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: chips.length,
                  separatorBuilder: (_, _) => SizedBox(width: 7.w),
                  itemBuilder: (_, i) => chips[i],
                ),
              ),
            ),
          ),
        Container(
          padding: EdgeInsets.fromLTRB(15.w, 11.h, 15.w, _bottomInset(context)),
          decoration: const BoxDecoration(
            color: CoachStyle.surface,
            border: Border(top: BorderSide(color: CoachStyle.border)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _input(context, busy, onSubmit, hint: hint)),
              SizedBox(width: 9.w),
              _SendButton(
                enabled: !busy,
                onTap: () {
                  onSubmit(_text.text);
                  _text.clear();
                },
              ),
              SizedBox(width: 9.w),
              _MicButton(
                listening: _listening,
                enabled: !busy,
                onTap: _toggleMic,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _input(
    BuildContext context,
    bool busy,
    Future<void> Function(String) onSubmit, {
    String? hint,
  }) {
    return Container(
      constraints: BoxConstraints(minHeight: 44.h),
      decoration: BoxDecoration(
        color: CoachStyle.inputBackground,
        borderRadius: BorderRadius.circular(99.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      alignment: Alignment.center,
      child: TextField(
        controller: _text,
        enabled: !busy,
        minLines: 1,
        maxLines: 4,
        textInputAction: TextInputAction.send,
        onSubmitted: (value) {
          onSubmit(value);
          _text.clear();
        },
        style: TextStyle(
          fontSize: 13.5.sp,
          fontWeight: FontWeight.w600,
          color: CoachStyle.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
          hintText: _listening ? context.l10n.coach.micListening : (hint ?? context.l10n.coach.inputHint),
          hintStyle: TextStyle(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w600,
            color: CoachStyle.textPlaceholder,
          ),
        ),
      ),
    );
  }

  /// Tap to start, tap to stop. A refused microphone changes nothing on screen
  /// — the reader types instead, and being told off for a permission they did
  /// not grant is not what this moment needs.
  Future<void> _toggleMic() async {
    if (_listening) {
      setState(() => _listening = false);
      final text = await _recorder.stopAndTranscribe(
        LocaleSettings.currentLocale.languageCode,
      );
      if (!mounted || text.isEmpty) return;

      // Into the box, not straight out: the transcription is a draft of their
      // sentence, and they get to fix it before it is filed under their name.
      _text.text = text;

      return;
    }

    final started = await _recorder.start();
    if (!mounted || !started) return;

    setState(() => _listening = true);
  }

  // --- plan ------------------------------------------------------------

  /// Two boxes, both filled by the reader.
  ///
  /// Never a picker and never a suggestion: the push that arrives days later
  /// quotes these back word for word, and the whole mechanism rests on them
  /// recognising their own sentence.
  Widget _plan(BuildContext context, bool busy) {
    final l10n = context.l10n.coach;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.planLabel.toUpperCase(), style: CoachStyle.sectionLabel()),
        SizedBox(height: 8.h),
        _FormField(controller: _planContext, hint: l10n.planContextHint, enabled: !busy),
        SizedBox(height: 8.h),
        _FormField(
          controller: _planAction,
          hint: l10n.planActionHint,
          enabled: !busy,
          onSubmitted: (_) => _savePlan(),
        ),
        SizedBox(height: 8.h),
        _FilledButton(
          label: l10n.planSave,
          enabled: !busy &&
              _planContext.text.trim().isNotEmpty &&
              _planAction.text.trim().isNotEmpty,
          onTap: _savePlan,
        ),
      ],
    );
  }

  void _savePlan() => widget.cubit.savePlan(context: _planContext.text, action: _planAction.text);

  // --- schedule --------------------------------------------------------

  Widget _schedule(BuildContext context, bool busy) {
    return _ScheduleForm(cubit: widget.cubit, busy: busy);
  }

  // --- course card -----------------------------------------------------
  // --- rating ----------------------------------------------------------

  /// The rating is a TOAST that rises from the input area and rates the WHOLE
  /// session — never a line in the chat. 👍 closes it at once; 👎 opens the
  /// second toast with the closed list; ✕ skips. Nothing is echoed into the
  /// thread: "toast đóng ngay, không thêm câu nào vào chat".
  Widget _rating(BuildContext context, bool busy) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Toast(
          child: _thumbDown ? _ratingIssues(context, busy) : _ratingThumbs(context, busy),
        ),
        SizedBox(height: 9.h),
        // The input row, disabled: the toast is what is being answered.
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _input(context, true, (_) async {})),
            SizedBox(width: 9.w),
            _SendButton(enabled: false, onTap: () {}),
            SizedBox(width: 9.w),
            _MicButton(listening: false, enabled: false, onTap: () {}),
          ],
        ),
      ],
    );
  }

  Widget _ratingThumbs(BuildContext context, bool busy) {
    final l10n = context.l10n.coach;

    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.ratingToastTitle,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, height: 1.35, color: CoachStyle.textPrimary),
          ),
        ),
        SizedBox(width: 10.w),
        _ThumbButton(glyph: '👍', onTap: busy ? null : () => widget.cubit.rate(thumb: 'up')),
        SizedBox(width: 7.w),
        _ThumbButton(glyph: '👎', onTap: busy ? null : () => setState(() => _thumbDown = true)),
        SizedBox(width: 10.w),
        _CloseDot(onTap: busy ? null : () => widget.cubit.rate()),
      ],
    );
  }

  /// Why it felt wrong — a closed list, multi-select, only after 👎. "Khác"
  /// opens one box; the words land beside the chips, not in the thread.
  Widget _ratingIssues(BuildContext context, bool busy) {
    final l10n = context.l10n.coach;
    final chips = [
      // The doc's five, in its order: "hiểu sai chuyện · quá chung · quá dài ·
      // giọng không phù hợp · áp đặt suy nghĩ". The last one is the safety valve
      // — a session tagged with it must be read by a person.
      ('missed_the_point', l10n.ratingChipMissed),
      ('too_generic', l10n.ratingChipGeneric),
      ('too_long', l10n.ratingChipLong),
      ('voice_mismatch', l10n.ratingChipVoice),
      ('imposed_thinking', l10n.ratingChipImposed),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.ratingIssuesTitle,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: CoachStyle.textPrimary),
              ),
            ),
            SizedBox(width: 10.w),
            _CloseDot(onTap: busy ? null : () => widget.cubit.rate()),
          ],
        ),
        SizedBox(height: 9.h),
        Wrap(
          spacing: 6.w,
          runSpacing: 6.h,
          children: chips
              .map(
                (chip) => _Pill(
                  label: chip.$2,
                  selected: _ratingChips.contains(chip.$1),
                  onTap: busy
                      ? null
                      : () => setState(() {
                          if (!_ratingChips.remove(chip.$1)) _ratingChips.add(chip.$1);
                        }),
                ),
              )
              .toList(),
        ),
        if (_ratingChips.contains('other')) ...[
          SizedBox(height: 8.h),
          _FormField(
            controller: _ratingOther,
            hint: l10n.ratingOtherHint,
            enabled: !busy,
            height: 34,
            radius: 11,
            fontSize: 12.5,
          ),
        ],
        SizedBox(height: 9.h),
        _FilledButton(
          label: l10n.ratingSend,
          enabled: !busy && _ratingChips.isNotEmpty,
          height: 34,
          radius: 11,
          fontSize: 12.5,
          onTap: () => widget.cubit.rate(
            thumb: 'down',
            chips: _ratingChips.toList(),
            note: _ratingChips.contains('other') ? _ratingOther.text.trim() : null,
          ),
        ),
      ],
    );
  }

  // --- next session ----------------------------------------------------
  // --- end -------------------------------------------------------------

  /// One button out. Where it goes depends on how the session ended: ① back
  /// to the Roadmap, ② back to wherever the sheet was opened from, and
  /// "Đi tới khoá học" onward to that course's Roadmap.
  Widget _end(BuildContext context, CoachState state, bool busy) {
    final l10n = context.l10n.coach;
    final course = state.ui.course;
    final leaving = state.step == 'leave' && course != null;

    final label = leaving
        ? l10n.endLeave
        : state.entry == CoachEntry.lesson
        ? l10n.endCloseLesson
        : l10n.endCloseHome;

    return _SelectableBox(
      label: label,
      selected: false,
      radius: 14,
      verticalPadding: 12,
      fontSize: 12,
      onTap: busy
          ? null
          : () => Navigator.of(context).pop(
              leaving ? _CoachSheetResult.openCourse(course.courseId) : const _CoachSheetResult.close(),
            ),
    );
  }
}

/// ⟨Phương án⟩, drawn where the design draws them: IN the thread, right-aligned
/// under the Coach's line, one white pill per choice — "nằm TRONG khung chat,
/// căn phải, mỗi phương án một dòng". Mood is the one exception: a single row
/// of five faces, no words, one tap.
class _OptionPills extends StatelessWidget {
  final CoachState state;
  final CoachCubit cubit;
  final bool busy;

  const _OptionPills({required this.state, required this.cubit, required this.busy});

  static const _moodEmoji = ['😞', '😕', '😐', '🙂', '😄'];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.coach;
    final step = state.step;

    if (step == 'mood' || step == 'moodEnd') {
      final labels = [l10n.mood1, l10n.mood2, l10n.mood3, l10n.mood4, l10n.mood5];

      return Padding(
        padding: EdgeInsets.only(top: 2.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            for (var i = 0; i < _moodEmoji.length; i++) ...[
              if (i > 0) SizedBox(width: 8.w),
              Semantics(
                button: true,
                label: labels[i],
                child: GestureDetector(
                  onTap: busy
                      ? null
                      : () => _dispatchChip(
                          cubit,
                          step,
                          _ChipSpec('${i + 1}', '${_moodEmoji[i]}  ${labels[i]}'),
                        ),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: CoachStyle.surface,
                      border: Border.all(color: CoachStyle.selectedBorderSoft, width: 1.5),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(_moodEmoji[i], style: TextStyle(fontSize: 22.sp)),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // pickNew / pickHabit — the choices ARE the reader's own library, and a
    // library is long. Three at a time, re-rollable, instead of every habit at
    // once (owner's call, 2026-08-28).
    if (step == 'pickNew' || step == 'pickHabit') {
      return _HabitPickPills(state: state, cubit: cubit, busy: busy);
    }

    final specs = _chipSpecsFor(l10n, state);

    return Padding(
      padding: EdgeInsets.only(top: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < specs.length; i++) ...[
            if (i > 0) SizedBox(height: 7.h),
            _OptionPill(
              label: specs[i].label,
              onTap: busy ? null : () => _dispatchChip(cubit, step, specs[i]),
            ),
          ],
        ],
      ),
    );
  }
}

/// pickNew / pickHabit — THREE habits at a time, drawn at random from the
/// reader's own library, with a quiet way to ask for three more.
///
/// The server sends the library WHOLE (thirteen and up in practice), and
/// thirteen identical pills is not a question — it is a list the reader scrolls
/// past. Three is a choice. The re-roll is what makes three safe: nothing is
/// hidden for good, it is only out of frame.
class _HabitPickPills extends StatefulWidget {
  final CoachState state;
  final CoachCubit cubit;
  final bool busy;

  const _HabitPickPills({required this.state, required this.cubit, required this.busy});

  @override
  State<_HabitPickPills> createState() => _HabitPickPillsState();
}

class _HabitPickPillsState extends State<_HabitPickPills> {
  /// How many the reader sees at once.
  static const _size = 3;

  final _random = Random();
  List<CoachChoiceEntity> _shown = const [];

  @override
  void initState() {
    super.initState();
    _shown = _roll(widget.state.ui.choices, const []);
  }

  @override
  void didUpdateWidget(covariant _HabitPickPills oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A different library (or a different step's list) starts over — but ONLY
    // then. Compared by VALUE, never by list identity: every rebuild hands us a
    // fresh list object, and reshuffling on each one would move the answer out
    // from under a thumb already on its way down.
    final before = oldWidget.state.ui.choices.map((c) => c.value).join('\u0000');
    final now = widget.state.ui.choices.map((c) => c.value).join('\u0000');
    if (before != now) _shown = _roll(widget.state.ui.choices, const []);
  }

  /// Three at random — and never the same three twice while the library still
  /// has unseen ones to give, because a re-roll that returns what was already
  /// on screen reads as a broken button.
  List<CoachChoiceEntity> _roll(List<CoachChoiceEntity> pool, List<CoachChoiceEntity> previous) {
    if (pool.length <= _size) return List.of(pool);

    final seen = previous.map((c) => c.value).toSet();
    final unseen = pool.where((c) => !seen.contains(c.value)).toList()..shuffle(_random);
    final picked = unseen.take(_size).toList();

    // A library barely bigger than three runs out of unseen ones. Fill from the
    // rest rather than show fewer — but only after every unseen one is in, so
    // each tap still moves at least one pill.
    if (picked.length < _size) {
      final taken = picked.map((c) => c.value).toSet();
      final rest = pool.where((c) => !taken.contains(c.value)).toList()..shuffle(_random);
      picked.addAll(rest.take(_size - picked.length));
    }

    return picked;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.coach;

    return Padding(
      padding: EdgeInsets.only(top: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _shown.length; i++) ...[
            if (i > 0) SizedBox(height: 7.h),
            _OptionPill(
              label: _shown[i].label ?? _shown[i].value,
              onTap: widget.busy
                  ? null
                  : () => _dispatchChip(
                      widget.cubit,
                      widget.state.step,
                      _ChipSpec(_shown[i].value, _shown[i].label ?? _shown[i].value),
                    ),
            ),
          ],
          // Nothing left to swap in — a button that cannot change anything is
          // worse than no button.
          if (widget.state.ui.choices.length > _size) ...[
            SizedBox(height: 9.h),
            _RerollLink(
              label: l10n.pickReroll,
              onTap: widget.busy
                  ? null
                  : () => setState(() => _shown = _roll(widget.state.ui.choices, _shown)),
            ),
          ],
        ],
      ),
    );
  }
}

/// The way to ask for three more. A quiet line with a shuffle mark, never a
/// fourth pill: the answers must look identical to each other, so nothing that
/// is NOT an answer may look like one.
class _RerollLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _RerollLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = onTap == null ? CoachStyle.textDisabled : CoachStyle.textMuted;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shuffle_rounded, size: 14.sp, color: color),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One choice: a white pill with the lilac hairline, as the design draws every
/// option — identical chrome for every choice, because "ba nút phải trông
/// giống hệt nhau".
class _OptionPill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _OptionPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: BoxConstraints(maxWidth: 0.84.sw),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: CoachStyle.surface,
          border: Border.all(color: CoachStyle.selectedBorderSoft, width: 1.5),
          borderRadius: BorderRadius.circular(99.r),
        ),
        child: Text(
          label,
          maxLines: 100,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            height: 1.35,
            color: onTap == null ? CoachStyle.textMuted : CoachStyle.selectedText,
          ),
        ),
      ),
    );
  }
}

/// The words each chip step offers. Kept beside the dispatch below so a new
/// step cannot gain words without gaining a destination.
List<_ChipSpec> _chipSpecsFor(dynamic l10n, CoachState state) {
  return switch (state.step) {
    // Three buttons that MUST look identical — no highlighted "right" answer,
    // or the reader taps to please the app and the câu kể data turns to noise.
    'intent' => [
      _ChipSpec('done', l10n.intentDone, echo: l10n.intentDoneEcho),
      _ChipSpec('missed', l10n.intentMissed, echo: l10n.intentMissedEcho),
      _ChipSpec('none', l10n.intentNone, echo: l10n.intentNoneEcho),
    ],
    'invite' => [
      _ChipSpec('yes', l10n.inviteYes, echo: l10n.inviteYesEcho),
      _ChipSpec('no', l10n.inviteNo, echo: l10n.inviteNoEcho),
    ],
    // Nhịp 6 — the invented scene gave them an action; only their own life can
    // give the occasion a commitment needs.
    'sceneMet' => [
      _ChipSpec('yes', l10n.sceneMetYes, echo: l10n.sceneMetYesEcho),
      _ChipSpec('no', l10n.sceneMetNo, echo: l10n.sceneMetNoEcho),
    ],
    // RETIRED with nhịp 4 (doc v4).
    'sceneAgain' => [
      _ChipSpec('yes', l10n.sceneAgainYes, echo: l10n.sceneAgainYesEcho),
      _ChipSpec('no', l10n.sceneAgainNo, echo: l10n.sceneAgainNoEcho),
    ],
    // Luồng 4 — after an off-track answer: the same scene once more, or not.
    'sceneFix' => [
      _ChipSpec('retry', l10n.sceneFixRetry, echo: l10n.sceneFixRetryEcho),
      _ChipSpec('later', l10n.sceneFixLater, echo: l10n.sceneFixLaterEcho),
    ],
    'planAsk' => [
      _ChipSpec('yes', l10n.planAskYes, echo: l10n.planAskYesEcho),
      _ChipSpec('no', l10n.planAskNo, echo: l10n.planAskNoEcho),
    ],
    'loop' => [
      _ChipSpec('continue', l10n.loopContinue),
      _ChipSpec('stop', l10n.loopStop),
    ],
    // ②A after "có dịp mà chưa làm" — smaller, or keep it. Equal buttons.
    'shrinkAsk' => [
      _ChipSpec('yes', l10n.shrinkAskYes, echo: l10n.shrinkAskYesEcho),
      _ChipSpec('no', l10n.shrinkAskNo, echo: l10n.shrinkAskNoEcho),
    ],
    // Retired steps a parked session may still be on.
    'depth' => [
      _ChipSpec('shallow', l10n.depthShallow),
      _ChipSpec('deep', l10n.depthDeep),
    ],
    'contextAsk' => [
      _ChipSpec('keep', l10n.contextKeep),
      _ChipSpec('change', l10n.contextChange),
    ],
    // "Dừng phiên hay bắt đầu phiên mới?" — two equal pills; a low mood-end
    // hides "phiên mới" and only the stop remains.
    'nextSession' => [
      if (state.ui.allowNewSession) _ChipSpec('again', l10n.nextAgain, echo: l10n.nextAgainEcho),
      _ChipSpec('stop', l10n.nextStop, echo: l10n.nextStopEcho),
    ],
    // pickNew / pickHabit — the only chips whose words are data.
    _ => state.ui.choices.map((c) => _ChipSpec(c.value, c.label ?? c.value)).toList(),
  };
}

void _dispatchChip(CoachCubit cubit, String step, _ChipSpec spec) {
  final echo = spec.echo ?? spec.label;

  switch (step) {
    case 'mood':
      cubit.pickMood(int.parse(spec.value), spec.label);
    case 'moodEnd':
      cubit.pickMoodEnd(int.parse(spec.value), spec.label);
    case 'intent':
      cubit.answerIntent(spec.value, echo);
    case 'invite':
      cubit.answerInvite(accept: spec.value == 'yes', label: echo);
    case 'sceneAgain':
      cubit.answerSceneAgain(again: spec.value == 'yes', label: echo);
    case 'sceneMet':
      cubit.answerSceneMet(met: spec.value == 'yes', label: echo);
    case 'planAsk':
      cubit.answerPlanAsk(accept: spec.value == 'yes', label: echo);
    case 'loop':
      cubit.loop(keepGoing: spec.value == 'continue', label: spec.label);
    case 'shrinkAsk':
      cubit.answerShrinkAsk(accept: spec.value == 'yes', label: echo);
    case 'pickNew':
    // The chip's picker sends the same event; the server knows which step it
    // came from and puts the reader back there.
    case 'pickHabit':
    // Luồng 4 — the habit to practise, from the kho.
    case 'scenePick':
      cubit.pickNewHabit(spec.value, spec.label);
    // Luồng 4 — the retry offer rides the `sceneAgain` event: same meaning.
    case 'sceneFix':
      cubit.answerSceneAgain(again: spec.value == 'retry', label: echo);
    case 'depth':
      cubit.sendRetired({'kind': 'depth', 'deep': spec.value == 'deep'}, label: spec.label);
    case 'contextAsk':
      cubit.sendRetired({'kind': 'context', 'keep': spec.value == 'keep'}, label: spec.label);
    case 'nextSession':
      cubit.nextSession(again: spec.value == 'again', label: echo);
  }
}

/// The reminder schedule, exactly as the design's Schedule part draws it:
/// three rows — the time pill beside the seven weekday chips, the three-mode
/// switch, and Bật/Tắt nhắc — with a small swipe popup for the hour and the
/// minute ("chạm vào số → popup vuốt riêng, nền mờ, chạm ra ngoài là đóng").
class _ScheduleForm extends StatefulWidget {
  final CoachCubit cubit;
  final bool busy;

  const _ScheduleForm({required this.cubit, required this.busy});

  @override
  State<_ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<_ScheduleForm> {
  int _hour = 20;
  int _minute = 0;
  String _mode = 'daily';

  /// Weekly — ISO weekdays. Starts on today's, so "hằng tuần" is one tap.
  late final Set<int> _weekdays = {DateTime.now().weekday};

  /// Once — offset in days from today, 0..6.
  int _onceOffset = 0;

  /// Which half of the clock the popup is editing, or null.
  String? _picking;

  String get _clock => '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';

  List<String> _dayLabels(BuildContext context) {
    final l10n = context.l10n.coach;

    return [l10n.day1, l10n.day2, l10n.day3, l10n.day4, l10n.day5, l10n.day6, l10n.day7];
  }

  void _save() {
    final l10n = context.l10n.coach;
    final now = DateTime.now();

    switch (_mode) {
      case 'once':
        final date = now.add(Duration(days: _onceOffset));
        final iso =
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        widget.cubit.saveSchedule(
          enabled: true,
          hour: _hour,
          minute: _minute,
          days: 'once',
          date: iso,
          label: l10n.scheduleEcho(time: _clock, days: l10n.modeOnce),
        );
      case 'weekly':
        widget.cubit.saveSchedule(
          enabled: true,
          hour: _hour,
          minute: _minute,
          days: 'custom',
          customDays: _weekdays.toList()..sort(),
          label: l10n.scheduleEcho(time: _clock, days: l10n.modeWeekly),
        );
      default:
        widget.cubit.saveSchedule(
          enabled: true,
          hour: _hour,
          minute: _minute,
          days: 'daily',
          label: l10n.scheduleEcho(time: _clock, days: l10n.modeDaily),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.coach;
    final busy = widget.busy;

    // The wheel used to float above the form via a Positioned OUTSIDE the
    // Stack's bounds — Flutter paints there (Clip.none) but never hit-tests
    // there, so the picker LOOKED tappable and swallowed nothing: "lỗi cứng
    // không chọn được giờ" (owner, on-device, 2026-08-28). It now opens
    // INLINE, growing the form upward, where every value is really tappable.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_picking != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: _picking == 'hour' ? 4.w : 44.w),
              child: _WheelPopup(
                values: _picking == 'hour'
                    ? List.generate(24, (i) => i)
                    : List.generate(12, (i) => i * 5),
                selected: _picking == 'hour' ? _hour : _minute,
                onPick: (value) => setState(() {
                  if (_picking == 'hour') {
                    _hour = value;
                  } else {
                    _minute = value;
                  }
                  _picking = null;
                }),
              ),
            ),
          ),
          SizedBox(height: 8.h),
        ],
        Row(
          children: [
            _TimePill(
              hour: _hour,
              minute: _minute,
              picking: _picking,
              // Tapping the open half again closes the wheel.
              onPick: busy
                  ? null
                  : (part) =>
                      setState(() => _picking = _picking == part ? null : part),
            ),
            SizedBox(width: 9.w),
            Expanded(child: _dayRow(context, busy)),
          ],
        ),
        SizedBox(height: 10.h),
        _modeSwitch(l10n, busy),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _FilledButton(
                label: l10n.reminderOn,
                enabled: !busy && (_mode != 'weekly' || _weekdays.isNotEmpty),
                onTap: _save,
              ),
            ),
            SizedBox(width: 9.w),
            GestureDetector(
              onTap: busy
                  ? null
                  : () => widget.cubit.saveSchedule(enabled: false, label: l10n.reminderOffEcho),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 44.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CoachStyle.chipBackground,
                  border: Border.all(color: CoachStyle.border, width: 1.5),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Text(
                  l10n.reminderOff,
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: CoachStyle.textChip),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// "Chỉ một lần thì hàng dưới đổi thành chọn ngày cụ thể; hằng tuần thì chọn
  /// bao nhiêu thứ cũng được" — daily shows the week lit whole, read-only.
  Widget _dayRow(BuildContext context, bool busy) {
    final labels = _dayLabels(context);
    final l10n = context.l10n.coach;
    final now = DateTime.now();

    if (_mode == 'once') {
      return Row(
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) SizedBox(width: 4.w),
            Expanded(
              child: _DayChip(
                label: i == 0 ? l10n.dateToday : '${now.add(Duration(days: i)).day}',
                selected: _onceOffset == i,
                onTap: busy ? null : () => setState(() => _onceOffset = i),
              ),
            ),
          ],
        ],
      );
    }

    final daily = _mode == 'daily';

    return Row(
      children: [
        for (var day = 1; day <= 7; day++) ...[
          if (day > 1) SizedBox(width: 4.w),
          Expanded(
            child: _DayChip(
              label: labels[day - 1],
              selected: daily || _weekdays.contains(day),
              // Tapping a weekday IS choosing weekly — one gesture, no detour
              // through the switch first.
              onTap: busy
                  ? null
                  : () => setState(() {
                      if (daily) {
                        _mode = 'weekly';
                        _weekdays
                          ..clear()
                          ..add(day);
                      } else if (!_weekdays.remove(day)) {
                        _weekdays.add(day);
                      }
                    }),
            ),
          ),
        ],
      ],
    );
  }

  Widget _modeSwitch(dynamic l10n, bool busy) {
    final modes = [
      ('once', l10n.modeOnce as String),
      ('daily', l10n.modeDaily as String),
      ('weekly', l10n.modeWeekly as String),
    ];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: CoachStyle.inputBackground,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          for (var i = 0; i < modes.length; i++) ...[
            if (i > 0) SizedBox(width: 5.w),
            Expanded(
              child: GestureDetector(
                onTap: busy ? null : () => setState(() => _mode = modes[i].$1),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 6.w),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _mode == modes[i].$1 ? CoachStyle.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(11.r),
                    boxShadow: _mode == modes[i].$1
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0D121C).withValues(alpha: 0.12),
                              blurRadius: 3.r,
                              offset: Offset(0, 1.h),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    modes[i].$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: _mode == modes[i].$1 ? CoachStyle.textPrimary : CoachStyle.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "20 : 00" — each half its own tap target, the tapped one on a white pip.
class _TimePill extends StatelessWidget {
  final int hour;
  final int minute;
  final String? picking;
  final void Function(String part)? onPick;

  const _TimePill({required this.hour, required this.minute, required this.picking, required this.onPick});

  Widget _half(String part, int value) {
    final active = picking == part;

    return GestureDetector(
      onTap: onPick == null ? null : () => onPick!(part),
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: BoxConstraints(minWidth: 28.w),
        height: 28.w,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active || part == 'hour' ? CoachStyle.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(99.r),
        ),
        child: Text(
          value.toString().padLeft(2, '0'),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: part == 'hour' ? CoachStyle.textPrimary : CoachStyle.selectedText,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38.h,
      padding: EdgeInsets.symmetric(horizontal: 7.w),
      decoration: BoxDecoration(
        color: CoachStyle.selectedBackground,
        border: Border.all(color: CoachStyle.skin, width: 1.5),
        borderRadius: BorderRadius.circular(99.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _half('hour', hour),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: Text(':', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: CoachStyle.skin)),
          ),
          _half('minute', minute),
        ],
      ),
    );
  }
}

/// One weekday (or date) chip — 38px tall, a pill like everything else here.
class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _DayChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 38.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? CoachStyle.selectedBackground : CoachStyle.surface,
          border: Border.all(
            color: selected ? CoachStyle.skin : CoachStyle.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(99.r),
        ),
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w700,
            color: selected ? CoachStyle.selectedText : CoachStyle.textChip,
          ),
        ),
      ),
    );
  }
}

/// The design's little wheel: a white panel above the pill, five values
/// showing, the middle one lit. Tap a value to take it.
class _WheelPopup extends StatelessWidget {
  final List<int> values;
  final int selected;
  final void Function(int) onPick;

  const _WheelPopup({required this.values, required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final index = values.indexOf(selected).clamp(0, values.length - 1);

    return Container(
      width: 62.w,
      height: 190.h,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: CoachStyle.surface,
        border: Border.all(color: CoachStyle.border),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: CoachStyle.toastShadow,
      ),
      child: ListWheelScrollView.useDelegate(
        controller: FixedExtentScrollController(initialItem: index),
        itemExtent: 34.h,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (_) {},
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: values.length,
          builder: (context, i) => GestureDetector(
            onTap: () => onPick(values[i]),
            behavior: HitTestBehavior.opaque,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: values[i] == selected ? CoachStyle.selectedBackground : Colors.transparent,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                values[i].toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: values[i] == selected ? 14.sp : 12.5.sp,
                  fontWeight: values[i] == selected ? FontWeight.w800 : FontWeight.w700,
                  color: values[i] == selected ? CoachStyle.selectedText : CoachStyle.textChip,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipSpec {
  final String value;
  final String label;

  /// What the thread shows as the reader's line — the design echoes a short
  /// sentence ("Mình làm được rồi.") rather than the button's label.
  final String? echo;

  const _ChipSpec(this.value, this.label, {this.echo});
}

/// A small pill that toggles — the rating toast's issues.
class _Pill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  const _Pill({required this.label, this.onTap, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected ? CoachStyle.selectedBackground : CoachStyle.chipBackground,
          border: Border.all(color: selected ? CoachStyle.skin : CoachStyle.border, width: 1.5),
          borderRadius: BorderRadius.circular(99.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w700,
            color: selected ? CoachStyle.selectedText : CoachStyle.textChip,
          ),
        ),
      ),
    );
  }
}

/// A suggestion above the box. Flatter and quieter than a choice — most fill
/// the box rather than answering, so it must not read as a button that commits.
class _SampleChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _SampleChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 13.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CoachStyle.surface,
          border: Border.all(color: CoachStyle.selectedBorderSoft, width: 1.5),
          borderRadius: BorderRadius.circular(99.r),
          boxShadow: CoachStyle.cardShadow,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w700,
            color: CoachStyle.selectedText,
          ),
        ),
      ),
    );
  }
}

/// A boxed control: the schedule chips, the end button. One widget because the
/// design draws them identically apart from corner radius and padding.
class _SelectableBox extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final double radius;
  final double verticalPadding;
  final double horizontalPadding;
  final double fontSize;
  final double? height;

  const _SelectableBox({
    required this.label,
    required this.selected,
    required this.onTap,
    this.radius = 12,
    this.verticalPadding = 10,
    // ignore: unused_element_parameter — kept for the next form that needs it.
    this.horizontalPadding = 6,
    this.fontSize = 13,
    // ignore: unused_element_parameter
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: height?.h,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding.w, vertical: verticalPadding.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? CoachStyle.selectedBackground : CoachStyle.chipBackground,
          border: Border.all(
            color: selected ? CoachStyle.skin : CoachStyle.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(radius.r),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 100,
          style: TextStyle(
            fontSize: fontSize.sp,
            fontWeight: FontWeight.w700,
            height: 1.35,
            color: selected ? CoachStyle.selectedText : CoachStyle.textChip,
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool enabled;
  final double height;
  final double radius;
  final double fontSize;
  final ValueChanged<String>? onSubmitted;

  const _FormField({
    required this.controller,
    required this.hint,
    required this.enabled,
    this.height = 42,
    this.radius = 14,
    this.fontSize = 13.5,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CoachStyle.inputBackground,
        border: Border.all(color: CoachStyle.border, width: 1.5),
        borderRadius: BorderRadius.circular(radius.r),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        onSubmitted: onSubmitted,
        style: TextStyle(
          fontSize: fontSize.sp,
          fontWeight: FontWeight.w600,
          color: CoachStyle.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: fontSize.sp,
            fontWeight: FontWeight.w600,
            color: CoachStyle.textPlaceholder,
          ),
        ),
      ),
    );
  }
}

class _FilledButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final double height;
  final double radius;
  final double fontSize;

  const _FilledButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.height = 44,
    this.radius = 14,
    this.fontSize = 13.5,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: height.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? CoachStyle.skin : CoachStyle.border,
          borderRadius: BorderRadius.circular(radius.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize.sp,
            fontWeight: FontWeight.w700,
            color: CoachStyle.surface,
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _SendButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: enabled ? CoachStyle.skin : CoachStyle.border,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_upward_rounded,
          color: CoachStyle.surface,
          size: 21.w,
        ),
      ),
    );
  }
}

/// The microphone. Outlined, not filled — it is the second way in, not the
/// primary one, and the design gives it the same chrome as a chip.
class _MicButton extends StatelessWidget {
  final bool listening;
  final bool enabled;
  final VoidCallback onTap;

  const _MicButton({
    required this.listening,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.coach.micSemantics,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: listening ? CoachStyle.selectedBackground : CoachStyle.chipBackground,
            border: Border.all(
              color: listening ? CoachStyle.skin : CoachStyle.border,
              width: 1.5,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            listening ? Icons.stop_rounded : Icons.mic_none_rounded,
            size: 20.w,
            color: listening
                ? CoachStyle.selectedText
                : enabled
                ? CoachStyle.textChip
                : CoachStyle.textPlaceholder,
          ),
        ),
      ),
    );
  }
}

/// The card that rises from the input area — the rating's home. Drawn inside
/// the composer rather than floated over the thread: a widget that overflows
/// its parent cannot be tapped outside it, and this one has to be.
class _Toast extends StatelessWidget {
  final Widget child;

  const _Toast({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 11.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: CoachStyle.surface,
        border: Border.all(color: CoachStyle.border),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: CoachStyle.toastShadow,
      ),
      child: child,
    );
  }
}

class _ThumbButton extends StatelessWidget {
  final String glyph;
  final VoidCallback? onTap;

  const _ThumbButton({required this.glyph, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34.w,
        height: 30.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CoachStyle.choiceBackground,
          border: Border.all(color: CoachStyle.selectedBorderSoft, width: 1.5),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(glyph, style: TextStyle(fontSize: 14.sp, height: 1)),
      ),
    );
  }
}

/// The toast's ✕ — skipping is allowed, and quiet.
class _CloseDot extends StatelessWidget {
  final VoidCallback? onTap;

  const _CloseDot({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 24.w,
        height: 24.w,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: CoachStyle.inputBackground,
          shape: BoxShape.circle,
        ),
        child: Text(
          '✕',
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, height: 1, color: CoachStyle.textMuted),
        ),
      ),
    );
  }
}
