part of '../../coach.dart';

/// The bottom half of the sheet: white, hairline on top, and whatever the
/// current step is answered with.
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

  late final CoachRecorder _recorder = AppDI.injector.get<CoachRecorder>();
  bool _listening = false;

  int _hour = 20;
  String _days = 'daily';

  @override
  void dispose() {
    _text.dispose();
    _planContext.dispose();
    _planAction.dispose();
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _body(context, state, busy),
          // ⑥ — a small line, never a button, and left-aligned so it never
          // reads as the primary way out. Its weight IS the design: an escape
          // that competes with the main action stops being an escape and
          // becomes a suggestion to give up.
          if (state.ui.escapeAvailable && !busy)
            Padding(
              padding: EdgeInsets.only(top: 9.h),
              child: GestureDetector(
                onTap: widget.cubit.takeEscape,
                behavior: HitTestBehavior.opaque,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.l10n.coach.escapeLabel,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: CoachStyle.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, CoachState state, bool busy) {
    switch (state.ui.kind) {
      case CoachUiKind.chips:
        return _chips(context, state, busy);
      case CoachUiKind.twoCols:
        return _twoCols(context, state, busy);
      case CoachUiKind.nextAction:
        return _nextAction(context, state, busy);
      case CoachUiKind.closing:
        return _closing(context, busy);
      case CoachUiKind.plan:
        return _plan(context, busy);
      case CoachUiKind.schedule:
        return _schedule(context, busy);
      case CoachUiKind.rating:
        return _rating(context, busy);
      case CoachUiKind.end:
        return _end(context);
      case CoachUiKind.safety:
        return const SizedBox.shrink();
      case CoachUiKind.text:
        return _textArea(context, state, busy, onSubmit: widget.cubit.submitText);
    }
  }

  // --- chips -----------------------------------------------------------

  /// Options for a chip step, as pills that scroll sideways.
  ///
  /// Data-driven options (habit titles) arrive with a label; fixed ones arrive
  /// as a bare value and are rendered from `coach.yaml`, so the same sentence
  /// never exists in both the server and the app.
  Widget _chips(BuildContext context, CoachState state, bool busy) {
    final l10n = context.l10n.coach;
    final step = state.step;

    final specs = switch (step) {
      // Five words, not three. The middle three are what most days actually
      // are, and collapsing them loses the only movement the delta can see.
      'mood' || 'moodEnd' => [
        _ChipSpec('1', l10n.mood1),
        _ChipSpec('2', l10n.mood2),
        _ChipSpec('3', l10n.mood3),
        _ChipSpec('4', l10n.mood4),
        _ChipSpec('5', l10n.mood5),
      ],
      'persona' => [
        _ChipSpec('friend', l10n.personaFriend),
        _ChipSpec('direct', l10n.personaDirect),
        _ChipSpec('guide', l10n.personaGuide),
      ],
      'time' => [
        _ChipSpec('short', l10n.scriptShort),
        _ChipSpec('medium', l10n.scriptMedium),
        _ChipSpec('long', l10n.scriptLong),
        _ChipSpec('practice', l10n.scriptPractice),
      ],
      'intent' => [
        _ChipSpec('done', l10n.intentDone),
        _ChipSpec('missed', l10n.intentMissed),
        _ChipSpec('none', l10n.intentNone),
      ],
      'checkin' => [
        _ChipSpec('yes', l10n.checkinYes),
        _ChipSpec('no', l10n.checkinNo),
      ],
      'loop' => [
        _ChipSpec('continue', l10n.loopContinue),
        _ChipSpec('stop', l10n.loopStop),
      ],
      // pickNew / pickHabit — the only chips whose words are data.
      _ => state.ui.choices.map((c) => _ChipSpec(c.value, c.label ?? c.value)).toList(),
    };

    return Wrap(
      spacing: 7.w,
      runSpacing: 7.h,
      children: specs
          .map(
            (spec) => _Pill(
              label: spec.label,
              onTap: busy ? null : () => _onChip(step, spec),
            ),
          )
          .toList(),
    );
  }

  void _onChip(String step, _ChipSpec spec) {
    final cubit = widget.cubit;

    switch (step) {
      case 'mood':
        cubit.pickMood(int.parse(spec.value), spec.label);
      case 'moodEnd':
        cubit.pickMoodEnd(int.parse(spec.value), spec.label);
      case 'persona':
        cubit.pickPersona(spec.value, spec.label);
      case 'time':
        cubit.pickScript(spec.value, spec.label);
      case 'intent':
        cubit.answerIntent(spec.value, spec.label);
      case 'checkin':
        cubit.answerCheckin(spec.value == 'yes', spec.label);
      case 'loop':
        cubit.loop(keepGoing: spec.value == 'continue', label: spec.label);
      case 'pickNew':
        cubit.pickNewHabit(spec.value, spec.label);
      case 'pickHabit':
        cubit.pickHabit(spec.value, spec.label);
    }
  }

  // --- text ------------------------------------------------------------

  /// Suggestions above, the input row below.
  ///
  /// The suggestions exist to lower the cost of the first word: someone looking
  /// at a blank field after being asked something hard closes the sheet. They
  /// fill the box rather than sending, so what goes in is still edited by the
  /// person whose sentence it becomes.
  Widget _textArea(
    BuildContext context,
    CoachState state,
    bool busy, {
    required Future<void> Function(String) onSubmit,
  }) {
    final samples = state.ui.samples;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (samples.isNotEmpty && !busy) ...[
          SizedBox(
            height: 28.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: samples.length,
              separatorBuilder: (_, _) => SizedBox(width: 7.w),
              itemBuilder: (_, i) => _SampleChip(
                label: samples[i],
                onTap: () => _text.text = samples[i],
              ),
            ),
          ),
          SizedBox(height: 8.h),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _input(context, busy, onSubmit)),
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
    Future<void> Function(String) onSubmit,
  ) {
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
          hintText: _listening ? context.l10n.coach.micListening : context.l10n.coach.inputHint,
          hintStyle: TextStyle(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w600,
            color: CoachStyle.textMuted,
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

  Widget _twoCols(BuildContext context, CoachState state, bool busy) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CoachTwoColumns(
          left: state.columnLeft,
          right: state.columnRight,
          onMove: (index, {required fromRight}) =>
              widget.cubit.moveLine(index, fromRight: fromRight),
          onEdit: (index, {required inRight, required text}) =>
              widget.cubit.editLine(index, inRight: inRight, text: text),
          onDelete: (index, {required inRight}) =>
              widget.cubit.deleteLine(index, inRight: inRight),
        ),
        SizedBox(height: 11.h),
        _textArea(context, state, busy, onSubmit: widget.cubit.submitProblemStatement),
        // ⑧ — for when the draft is not wrong in a line, it is wrong as a
        // whole. Dragging fixes detail; this says "that was not my story".
        // Quiet on purpose: it must be findable without inviting a tap.
        if (!busy)
          Padding(
            padding: EdgeInsets.only(top: 9.h),
            child: GestureDetector(
              onTap: () => widget.cubit.rejectDraft(context.l10n.coach.rejectDraft),
              behavior: HitTestBehavior.opaque,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.l10n.coach.rejectDraft,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: CoachStyle.textMuted,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // --- nhịp 4 -----------------------------------------------------------

  /// "Bạn sẽ làm gì?", with at most two keypoints to read.
  ///
  /// The keypoints come from the catalogue, never from the model, and each
  /// carries a quiet "explain this more simply" — which counts against the
  /// CONTENT, not the reader. A keypoint people keep asking about is a
  /// keypoint that needs rewriting.
  Widget _nextAction(BuildContext context, CoachState state, bool busy) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.ui.keypoints.isNotEmpty) ...[
          Text(
            context.l10n.coach.keypointsLabel.toUpperCase(),
            style: CoachStyle.sectionLabel(size: 10.5),
          ),
          SizedBox(height: 6.h),
          ...state.ui.keypoints.map(
            (kp) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: _KeypointRow(
                title: kp.title,
                onExplain: busy ? null : () => widget.cubit.explainAgain(kp.id),
              ),
            ),
          ),
          SizedBox(height: 8.h),
        ],
        _textArea(context, state, busy, onSubmit: widget.cubit.submitText),
      ],
    );
  }

  // --- nhịp 5 -----------------------------------------------------------

  /// The closing beat is the Coach speaking, not asking — one button out.
  /// "DỪNG CỨNG": there is no way to keep the Long script going from here.
  Widget _closing(BuildContext context, bool busy) {
    return _FilledButton(
      label: context.l10n.coach.closingContinue,
      enabled: !busy,
      onTap: widget.cubit.acknowledge,
    );
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
        _FormField(controller: _planAction, hint: l10n.planActionHint, enabled: !busy),
        SizedBox(height: 8.h),
        _FilledButton(
          label: l10n.planSave,
          enabled: !busy,
          onTap: () => widget.cubit.savePlan(
            context: _planContext.text,
            action: _planAction.text,
          ),
        ),
      ],
    );
  }

  // --- schedule --------------------------------------------------------

  Widget _schedule(BuildContext context, bool busy) {
    final l10n = context.l10n.coach;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.scheduleLabel.toUpperCase(), style: CoachStyle.sectionLabel()),
        SizedBox(height: 9.h),
        Row(
          children: [8, 12, 20]
              .map(
                (h) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: h == 20 ? 0 : 7.w),
                    child: _SelectableBox(
                      label: '${h.toString().padLeft(2, '0')}:00',
                      selected: _hour == h,
                      onTap: busy ? null : () => setState(() => _hour = h),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        SizedBox(height: 7.h),
        Row(
          children:
              [
                    ('daily', l10n.daysDaily),
                    ('weekdays', l10n.daysWeekdays),
                    ('weekends', l10n.daysWeekends),
                  ]
                  .map(
                    (entry) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: entry.$1 == 'weekends' ? 0 : 7.w),
                        child: _SelectableBox(
                          label: entry.$2,
                          selected: _days == entry.$1,
                          onTap: busy ? null : () => setState(() => _days = entry.$1),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
        SizedBox(height: 9.h),
        Row(
          children: [
            Expanded(
              child: _FilledButton(
                label: l10n.reminderOn,
                enabled: !busy,
                onTap: () => widget.cubit.saveSchedule(
                  enabled: true,
                  hour: _hour,
                  minute: 0,
                  days: _days,
                  label: '${_hour.toString().padLeft(2, '0')}:00 · ${_daysLabel(context)}',
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _SelectableBox(
                label: l10n.reminderOff,
                selected: false,
                height: 44,
                onTap: busy ? null : () => widget.cubit.saveSchedule(enabled: false, label: l10n.reminderOff),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _daysLabel(BuildContext context) {
    final l10n = context.l10n.coach;

    return switch (_days) {
      'weekdays' => l10n.daysWeekdays,
      'weekends' => l10n.daysWeekends,
      _ => l10n.daysDaily,
    };
  }

  // --- rating ----------------------------------------------------------

  Widget _rating(BuildContext context, bool busy) {
    final l10n = context.l10n.coach;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.ratingLabel.toUpperCase(), style: CoachStyle.sectionLabel()),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _SelectableBox(
                label: l10n.ratingUp,
                selected: false,
                radius: 13,
                onTap: busy ? null : () => widget.cubit.rate(thumb: 'up', label: l10n.ratingUp),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _SelectableBox(
                label: l10n.ratingDown,
                selected: false,
                radius: 13,
                onTap: busy ? null : () => widget.cubit.rate(thumb: 'down', label: l10n.ratingDown),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        GestureDetector(
          onTap: busy ? null : () => widget.cubit.rate(),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.ratingSkip,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: CoachStyle.textMuted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- end -------------------------------------------------------------

  /// Three choices in three equal columns.
  ///
  /// Same box, same width, same weight, same order, every time. Promoting "go
  /// to the course" into a filled button would turn the close of a personal
  /// conversation into a funnel — the design forbids it, and this grid is where
  /// that rule is either kept or quietly lost.
  Widget _end(BuildContext context) {
    final l10n = context.l10n.coach;
    final invite = widget.state.courseInvite;

    final labels = [
      if (invite != null) (l10n.endGoToCourse, _CoachSheetResult.openCourse(invite.courseId)),
      (l10n.endKeepTalking, const _CoachSheetResult.keepTalking()),
      (l10n.endClose, const _CoachSheetResult.close()),
    ];

    return Row(
      children: labels
          .map(
            (entry) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: entry == labels.last ? 0 : 8.w),
                child: _SelectableBox(
                  label: entry.$1,
                  selected: false,
                  radius: 14,
                  verticalPadding: 12,
                  onTap: () => Navigator.of(context).pop(entry.$2),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

/// One keypoint, with the quiet way to ask for it in plainer words.
class _KeypointRow extends StatelessWidget {
  final String title;
  final VoidCallback? onExplain;

  const _KeypointRow({required this.title, required this.onExplain});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: CoachStyle.chipBackground,
        border: Border.all(color: CoachStyle.border, width: 1.5),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: CoachStyle.textBody,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: onExplain,
            behavior: HitTestBehavior.opaque,
            child: Text(
              context.l10n.coach.explainSimpler,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: CoachStyle.skin,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipSpec {
  final String value;
  final String label;

  const _ChipSpec(this.value, this.label);
}

/// A chip: fully round, 1.5px border, never filled.
class _Pill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _Pill({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
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

/// A suggestion. Flatter and quieter than a chip — it fills the box rather than
/// answering, so it must not read as a button that commits to anything.
class _SampleChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

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
          color: CoachStyle.sampleBackground,
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

/// A boxed control: the schedule chips, the rating pair, the three closing
/// choices. One widget because the design draws them identically apart from
/// corner radius, and three near-copies would drift.
class _SelectableBox extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final double radius;
  final double verticalPadding;
  final double? height;

  const _SelectableBox({
    required this.label,
    required this.selected,
    required this.onTap,
    this.radius = 12,
    this.verticalPadding = 10,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: height?.h,
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: verticalPadding.h),
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
          style: TextStyle(
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w700,
            height: 1.35,
            color: selected ? CoachStyle.selectedText : CoachStyle.textBody,
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

  const _FormField({
    required this.controller,
    required this.hint,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CoachStyle.inputBackground,
        border: Border.all(color: CoachStyle.border, width: 1.5),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: TextStyle(
          fontSize: 13.5.sp,
          fontWeight: FontWeight.w600,
          color: CoachStyle.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w600,
            color: CoachStyle.textMuted,
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

  const _FilledButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? CoachStyle.skin : CoachStyle.border,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5.sp,
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
            color: listening ? CoachStyle.selectedText : CoachStyle.textChip,
          ),
        ),
      ),
    );
  }
}
