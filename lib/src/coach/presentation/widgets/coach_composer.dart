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
  (int, int) _time = (20, 0);
  String _days = 'daily';

  /// "tự chọn" — ISO weekdays 1 (Mon) … 7 (Sun).
  final Set<int> _customDays = {};

  /// Rating: the second toast opens only after 👎.
  bool _thumbDown = false;
  final Set<String> _ratingChips = {};

  /// The key the PLAN form's scene pre-fill was last applied for, so a rebuild
  /// mid-edit does not overwrite what the reader has started typing.
  String? _planFilledFor;

  /// The five moods, one glyph each — "emoji kèm chữ, một chạm". Glyphs are not
  /// words, so they live here rather than in five YAML files.
  static const _moodEmoji = ['😞', '😕', '😐', '🙂', '😄'];

  @override
  void initState() {
    super.initState();
    // A sheet reopened mid-session lands straight on the form: the pre-fill
    // has to apply here too, not only on the step change into it.
    _applyPlanPrefill();
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

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final busy = state.typing;

    return Container(
      padding: EdgeInsets.fromLTRB(
        15.w,
        11.h,
        15.w,
        // The home-indicator inset only applies when the keyboard is DOWN —
        // with it up the indicator is hidden and adding both leaves a dead
        // band above the keys.
        MediaQuery.viewInsetsOf(context).bottom > 0 ? 12.h : 20.h + MediaQuery.viewPaddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: CoachStyle.surface,
        border: Border(top: BorderSide(color: CoachStyle.border)),
      ),
      child: _body(context, state, busy),
    );
  }

  Widget _body(BuildContext context, CoachState state, bool busy) {
    switch (state.ui.kind) {
      case CoachUiKind.chips:
        return _chips(context, state, busy);
      case CoachUiKind.textSkippable:
        return _story(context, state, busy);
      case CoachUiKind.twoCols:
        return _twoCols(context, state, busy);
      case CoachUiKind.plan:
        return _plan(context, busy);
      case CoachUiKind.schedule:
        return _schedule(context, busy);
      case CoachUiKind.courseCard:
        return _courseChips(context, state, busy);
      case CoachUiKind.rating:
        return _rating(context, busy);
      case CoachUiKind.nextSession:
        return _nextSession(context, state, busy);
      case CoachUiKind.end:
        return _end(context, state, busy);
      case CoachUiKind.safety:
        return const SizedBox.shrink();
      // Retired composers a parked session may still be on — a text box lets
      // them finish; the server routes the answer back onto the spine. The
      // rubric card joined them on 2026-08-27 when scoring was cut.
      case CoachUiKind.sceneScore:
      case CoachUiKind.nextAction:
      case CoachUiKind.closing:
      case CoachUiKind.shrink:
      case CoachUiKind.text:
        return _textArea(context, state, busy, onSubmit: widget.cubit.submitText);
    }
  }

  // --- chips -----------------------------------------------------------

  /// Options for a chip step.
  ///
  /// Full-width, stacked, left-aligned — every choice the same size, because
  /// "nút đi tiếp phải ngang hàng với nút dừng". Mood is the one exception: a
  /// 3-then-2 grid, centred, as the design draws its five faces.
  Widget _chips(BuildContext context, CoachState state, bool busy) {
    final l10n = context.l10n.coach;
    final step = state.step;

    final specs = switch (step) {
      'mood' || 'moodEnd' => [
        _ChipSpec('1', '${_moodEmoji[0]}  ${l10n.mood1}'),
        _ChipSpec('2', '${_moodEmoji[1]}  ${l10n.mood2}'),
        _ChipSpec('3', '${_moodEmoji[2]}  ${l10n.mood3}'),
        _ChipSpec('4', '${_moodEmoji[3]}  ${l10n.mood4}'),
        _ChipSpec('5', '${_moodEmoji[4]}  ${l10n.mood5}'),
      ],
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
      // pickNew — the only chips whose words are data.
      _ => state.ui.choices.map((c) => _ChipSpec(c.value, c.label ?? c.value)).toList(),
    };

    final grid = step == 'mood' || step == 'moodEnd';

    if (grid) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 2 * 7.w) / 3;

          return Wrap(
            spacing: 7.w,
            runSpacing: 7.h,
            children: specs
                .map(
                  (spec) => SizedBox(
                    width: width,
                    child: _ChoiceButton(
                      label: spec.label,
                      centered: true,
                      onTap: busy ? null : () => _onChip(step, spec),
                    ),
                  ),
                )
                .toList(),
          );
        },
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < specs.length; i++) ...[
          if (i > 0) SizedBox(height: 7.h),
          _ChoiceButton(
            label: specs[i].label,
            onTap: busy ? null : () => _onChip(step, specs[i]),
          ),
        ],
      ],
    );
  }

  void _onChip(String step, _ChipSpec spec) {
    final cubit = widget.cubit;
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
      case 'planAsk':
        cubit.answerPlanAsk(accept: spec.value == 'yes', label: echo);
      case 'loop':
        cubit.loop(keepGoing: spec.value == 'continue', label: spec.label);
      case 'shrinkAsk':
        cubit.answerShrinkAsk(accept: spec.value == 'yes', label: echo);
      case 'pickNew':
        cubit.pickNewHabit(spec.value, spec.label);
      case 'depth':
        cubit.sendRetired({'kind': 'depth', 'deep': spec.value == 'deep'}, label: spec.label);
      case 'contextAsk':
        cubit.sendRetired({'kind': 'context', 'keep': spec.value == 'keep'}, label: spec.label);
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (chips.isNotEmpty && !busy) ...[
          // One row that fades at its right edge — the design's `overflow-x`
          // hint that it scrolls, without a scrollbar. Suggestions are two
          // short phrases (see the situation/reflect schema), so they fit; the
          // fade covers the rare longer one. Restored to the artboard on the
          // product owner's call, over the wrapped-rows variant.
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.black, Colors.black, Colors.transparent],
              stops: [0, 0.88, 1],
            ).createShader(bounds),
            blendMode: BlendMode.dstIn,
            child: SizedBox(
              height: 30.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: chips.length,
                separatorBuilder: (_, _) => SizedBox(width: 7.w),
                itemBuilder: (_, i) => chips[i],
              ),
            ),
          ),
          SizedBox(height: 8.h),
        ],
        Row(
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
        _FilledButton(label: l10n.planSave, enabled: !busy, onTap: _savePlan),
      ],
    );
  }

  void _savePlan() => widget.cubit.savePlan(context: _planContext.text, action: _planAction.text);

  // --- schedule --------------------------------------------------------

  Widget _schedule(BuildContext context, bool busy) {
    final l10n = context.l10n.coach;
    const hours = [(8, 0), (12, 30), (20, 0)];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.scheduleLabel.toUpperCase(), style: CoachStyle.sectionLabel()),
        SizedBox(height: 9.h),
        Row(
          children: [
            for (var i = 0; i < hours.length; i++) ...[
              if (i > 0) SizedBox(width: 7.w),
              Expanded(
                child: _SelectableBox(
                  label: _clock(hours[i]),
                  selected: _time == hours[i],
                  onTap: busy ? null : () => setState(() => _time = hours[i]),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 7.h),
        Row(
          children: [
            for (final entry in [
              ('daily', l10n.daysDaily),
              ('weekdays', l10n.daysWeekdays),
              ('weekends', l10n.daysWeekends),
              ('custom', l10n.daysCustom),
            ]) ...[
              if (entry.$1 != 'daily') SizedBox(width: 6.w),
              Expanded(
                child: _SelectableBox(
                  label: entry.$2,
                  selected: _days == entry.$1,
                  verticalPadding: 9,
                  fontSize: 12,
                  onTap: busy ? null : () => setState(() => _days = entry.$1),
                ),
              ),
            ],
          ],
        ),
        // "tự chọn" — the reader's own weekdays. Only drawn once chosen, so
        // the three ready-made shapes stay one tap for everyone else.
        if (_days == 'custom') ...[
          SizedBox(height: 7.h),
          Row(
            children: List.generate(7, (i) {
              final day = i + 1;
              final label = [l10n.day1, l10n.day2, l10n.day3, l10n.day4, l10n.day5, l10n.day6, l10n.day7][i];

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: day == 7 ? 0 : 4.w),
                  child: _SelectableBox(
                    label: label,
                    selected: _customDays.contains(day),
                    radius: 10,
                    verticalPadding: 8,
                    fontSize: 12,
                    onTap: busy
                        ? null
                        : () => setState(() {
                            if (!_customDays.remove(day)) _customDays.add(day);
                          }),
                  ),
                ),
              );
            }),
          ),
        ],
        SizedBox(height: 9.h),
        Row(
          children: [
            Expanded(
              child: _FilledButton(
                label: l10n.reminderOn,
                enabled: !busy,
                onTap: () => widget.cubit.saveSchedule(
                  enabled: true,
                  hour: _time.$1,
                  minute: _time.$2,
                  days: _days,
                  customDays: _days == 'custom' ? (_customDays.toList()..sort()) : null,
                  label: l10n.scheduleEcho(time: _clock(_time), days: _daysLabel(context)),
                ),
              ),
            ),
            SizedBox(width: 9.w),
            _SelectableBox(
              label: l10n.reminderOff,
              selected: false,
              height: 44,
              radius: 14,
              horizontalPadding: 16,
              fontSize: 13,
              onTap: busy ? null : () => widget.cubit.saveSchedule(enabled: false, label: l10n.reminderOffEcho),
            ),
          ],
        ),
      ],
    );
  }

  String _clock((int, int) time) => '${time.$1.toString().padLeft(2, '0')}:${time.$2.toString().padLeft(2, '0')}';

  String _daysLabel(BuildContext context) {
    final l10n = context.l10n.coach;

    return switch (_days) {
      'weekdays' => l10n.daysWeekdays,
      'weekends' => l10n.daysWeekends,
      'custom' => l10n.daysCustom,
      _ => l10n.daysDaily,
    };
  }

  // --- course card -----------------------------------------------------

  /// The card is up in the thread; here are its three ways out, as three equal
  /// chips. "Đi tới khoá học" earns one short Coach line and then the sheet
  /// leaves; the other two go on to the mood question.
  Widget _courseChips(BuildContext context, CoachState state, bool busy) {
    final l10n = context.l10n.coach;
    final cubit = widget.cubit;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChoiceButton(
          label: l10n.courseOpen,
          onTap: busy || state.ui.course == null ? null : () => cubit.courseAction('open', label: l10n.courseOpenEcho),
        ),
        SizedBox(height: 7.h),
        _ChoiceButton(
          label: l10n.courseCardSave,
          onTap: busy ? null : () => cubit.courseAction('save', label: l10n.courseCardSaveEcho),
        ),
        SizedBox(height: 7.h),
        _ChoiceButton(
          label: l10n.courseCardClose,
          onTap: busy ? null : () => cubit.courseAction('close', label: l10n.courseCardCloseEcho),
        ),
      ],
    );
  }

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
      ('imposed_thinking', l10n.ratingChipImposed),
      ('too_many_questions', l10n.ratingChipQuestions),
      ('missed_the_point', l10n.ratingChipMissed),
      ('too_generic', l10n.ratingChipGeneric),
      ('voice_mismatch', l10n.ratingChipVoice),
      ('other', l10n.ratingChipOther),
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

  /// "Dừng hay bắt đầu phiên mới?" — two equal buttons, new session first as
  /// drawn. A low mood-end hides it: someone tired being invited to keep going
  /// is exactly what the anti-rumination rules exist to stop.
  Widget _nextSession(BuildContext context, CoachState state, bool busy) {
    final l10n = context.l10n.coach;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.ui.allowNewSession) ...[
          _ChoiceButton(
            label: l10n.nextAgain,
            onTap: busy ? null : () => widget.cubit.nextSession(again: true, label: l10n.nextAgainEcho),
          ),
          SizedBox(height: 7.h),
        ],
        _ChoiceButton(
          label: l10n.nextStop,
          onTap: busy ? null : () => widget.cubit.nextSession(again: false, label: l10n.nextStopEcho),
        ),
      ],
    );
  }

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

class _ChipSpec {
  final String value;
  final String label;

  /// What the thread shows as the reader's line — the design echoes a short
  /// sentence ("Mình làm được rồi.") rather than the button's label.
  final String? echo;

  const _ChipSpec(this.value, this.label, {this.echo});
}

/// One choice, as the design draws every chip step: a soft lilac box, 1.5px
/// border, left-aligned, full width — identical for every option.
class _ChoiceButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool centered;

  const _ChoiceButton({required this.label, required this.onTap, this.centered = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 11.h),
        alignment: centered ? Alignment.center : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: CoachStyle.choiceBackground,
          border: Border.all(color: CoachStyle.selectedBorderSoft, width: 1.5),
          borderRadius: BorderRadius.circular(13.r),
        ),
        child: Text(
          label,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          maxLines: 100,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            height: 1.4,
            color: onTap == null ? CoachStyle.textMuted : CoachStyle.selectedText,
          ),
        ),
      ),
    );
  }
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
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CoachStyle.chipBackground,
          border: Border.all(color: CoachStyle.border, width: 1.5),
          borderRadius: BorderRadius.circular(99.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: CoachStyle.textChip,
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
    this.horizontalPadding = 6,
    this.fontSize = 13,
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
