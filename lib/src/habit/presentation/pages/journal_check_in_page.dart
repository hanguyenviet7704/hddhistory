part of '../../habit.dart';

/// One of the three mood levels on the journal check-in.
///
/// Three levels, and the stored value is **1-based** — `mood: 0` is falsy in
/// both Dart and JS, so a 0-based scale would be silently dropped by every
/// `if (mood)` / `mood ?? fallback` on the way to the API and in the admin.
/// See the API's `habit-checkin.schema.ts`.
enum JournalMood {
  tough(1),
  okay(2),
  great(3);

  const JournalMood(this.value);

  /// What goes on the wire. Never 0.
  final int value;

  /// The design's own emoji live in the part of `_MeUp App.dc.html` past the
  /// 256KiB read cap, so these are chosen to match the three labels. Swap them
  /// if the design specifies different glyphs — nothing else depends on them.
  String get emoji => switch (this) {
    JournalMood.tough => '😕',
    JournalMood.okay => '🙂',
    JournalMood.great => '😄',
  };

  /// Resolve a stored mood back to its level. Null for a check-in with no mood
  /// (a quick tap, or a row written before the journal shipped) and for any
  /// out-of-range value, so a bad number renders as "no mood" instead of
  /// throwing in a list.
  static JournalMood? fromValue(int? value) =>
      JournalMood.values.where((mood) => mood.value == value).firstOrNull;
}

/// Journal check-in (design "5 · Habit" → Flow · Practice with a journal).
///
/// Reached from the habit's "Practice now" CTA. The picker that leads here is
/// titled "How do you want to check in?" — so saving a journal **is** the day's
/// check-in, not a separate activity: it posts `done: true` with
/// `method: journal` plus the mood and the free text, and the streak follows
/// from that single write.
class JournalCheckInPage extends StatefulWidget {
  final UserHabitEntity userHabit;

  const JournalCheckInPage({super.key, required this.userHabit});

  /// Pushed imperatively rather than through a typed go_router route because it
  /// carries a [UserHabitEntity], and the repo has no `$extra` typed routes to
  /// follow. Mirrors [UpgradeHabitPage.push], including re-providing the
  /// HabitCubit singleton for the case where the caller is on the root
  /// navigator and the provider isn't in scope.
  ///
  /// Resolves to `true` when a check-in was filed, so the caller can refresh.
  static Future<bool?> push(BuildContext context, {required UserHabitEntity userHabit}) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: AppDI.injector.get<HabitCubit>(),
          child: JournalCheckInPage(userHabit: userHabit),
        ),
      ),
    );
  }

  @override
  State<JournalCheckInPage> createState() => _JournalCheckInPageState();
}

class _JournalCheckInPageState extends State<JournalCheckInPage> {
  final TextEditingController _noteController = TextEditingController();
  JournalMood? _mood;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// The design ships the save button in a disabled state, gated on the mood:
  /// it is the one answer the screen actually asks for ("How did it go today?"),
  /// while the text below it is optional. Submitting stays blocked while a
  /// request is in flight so a double tap can't file two check-ins.
  bool get _canSave => _mood != null && !_isSubmitting;

  void _pickMood(JournalMood mood) {
    AppHaptic.select();
    setState(() => _mood = mood);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _isSubmitting = true);

    final note = _noteController.text;
    // Goes through submitPracticeAttempt, not checkIn: the picker treats journal
    // as one of the practice methods, so it should leave an attempt row (with
    // the mood) alongside the check-in. The server writes both in this ONE
    // request — calling checkIn as well would race it on the same
    // {userHabitId, date} row.
    final ok = await context.read<HabitCubit>().submitPracticeAttempt(
      userHabitId: widget.userHabit.id,
      method: HabitCheckinMethodEntity.journal,
      mood: _mood!.value,
      note: note,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!ok) {
      context.showDSnackBar(message: context.l10n.common.errorSomethingHappened, type: MessageType.error);
      return;
    }

    HabitTracking.noteCheckin(widget.userHabit, hasNote: note.trim().isNotEmpty);
    await PracticeDonePage.push(context, userHabit: widget.userHabit);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    // Flat grey page, NOT a ThemedBackground. The design hardcodes `#F5F5FA`
    // here while it themes other surfaces, and it is the same flat grey as the
    // habit detail sheet this screen is opened from — journal and detail are the
    // habit's "form" surfaces, where the study-theme photo belongs to learning
    // content (the quiz) instead. Over a photo the white cards also lost their
    // 1.5px borders and the disabled save button its contrast.
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundGray,
      body: SafePage(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              12.verticalSpace,
              _header(context),
              26.verticalSpace,
              AppText(
                context.l10n.habit.journalTitle,
                // Design 26/800 — heavier than textBold26's w700.
                style: AppStyle.text26.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: AppCustomColor.textPrimary,
                ),
              ),
              6.verticalSpace,
              AppText(
                DateTime.now().parseString('MMM d, yyyy'),
                style: AppStyle.text14.copyWith(color: AppCustomColor.textTertiary),
              ),
              22.verticalSpace,
              _moodRow(context),
              20.verticalSpace,
              Expanded(child: _noteCard(context)),
              16.verticalSpace,
              DButton(
                text: context.l10n.habit.journalSaveButton,
                backgroundColor: AppCustomColor.brandPrimary,
                // The design ships this button visibly disabled until a mood is
                // picked. Passing the disabled fill explicitly is required:
                // `backgroundColor` alone only styles the enabled state, and the
                // Material default rendered as no fill at all.
                disabledBackgroundColor: AppCustomColor.brandPrimary100,
                size: Size.fromHeight(56.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999.r)),
                style: AppStyle.text18.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _canSave ? AppCustomColor.textWhite : AppCustomColor.textTertiary,
                ),
                onPressed: _canSave ? _save : null,
              ),
              12.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        HabitDomainIcon(skillsetId: widget.userHabit.habit?.skillsetId ?? '', size: 38),
        12.horizontalSpace,
        Expanded(
          child: AppText(
            widget.userHabit.displayTitle,
            maxLines: 2,
            // Design 15/700; the app's scale has no 15.
            style: AppStyle.text16.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: AppCustomColor.textPrimary,
            ),
          ),
        ),
        8.horizontalSpace,
        GestureDetector(
          onTap: () {
            AppHaptic.select();
            Navigator.of(context).pop();
          },
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 34.w,
            height: 34.w,
            child: Icon(Icons.close, size: 24.w, color: AppCustomColor.textTertiary),
          ),
        ),
      ],
    );
  }

  Widget _moodRow(BuildContext context) {
    return Row(
      children: [
        for (final mood in JournalMood.values) ...[
          if (mood != JournalMood.values.first) 10.horizontalSpace,
          Expanded(child: _moodButton(context, mood)),
        ],
      ],
    );
  }

  Widget _moodButton(BuildContext context, JournalMood mood) {
    final isSelected = _mood == mood;
    final label = switch (mood) {
      JournalMood.tough => context.l10n.habit.journalMoodTough,
      JournalMood.okay => context.l10n.habit.journalMoodOkay,
      JournalMood.great => context.l10n.habit.journalMoodGreat,
    };

    return GestureDetector(
      onTap: () => _pickMood(mood),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 6.w),
        decoration: BoxDecoration(
          color: isSelected ? AppCustomColor.brandPrimary100 : AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isSelected ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(mood.emoji, style: AppStyle.text24),
            7.verticalSpace,
            AppText(
              label,
              maxLines: 1,
              style: AppStyle.text13.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected ? AppCustomColor.brandPrimary : AppCustomColor.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: AppCustomColor.textPrimary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _noteController,
        expands: true,
        maxLines: null,
        textAlignVertical: TextAlignVertical.top,
        // Matches the API's @MaxLength(1000) on the check-in note, so the limit
        // is felt in the keyboard rather than as a 400 on save.
        maxLength: 1000,
        textInputAction: TextInputAction.newline,
        style: AppStyle.text16.copyWith(color: AppCustomColor.textPrimary, height: 1.55),
        decoration: InputDecoration(
          hintText: context.l10n.habit.journalPlaceholder,
          hintStyle: AppStyle.text16.copyWith(color: AppCustomColor.textTertiary),
          counterText: '',
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
