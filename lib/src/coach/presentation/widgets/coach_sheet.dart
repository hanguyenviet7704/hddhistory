part of '../../coach.dart';

/// What closing the sheet asked for.
///
/// A value rather than navigation performed inside the sheet: the sheet does
/// not know what "go to course" means on the screen that opened it, and pushing
/// a route from under a closing modal is how a navigator ends up with an orphan.
@freezed
sealed class _CoachSheetResult with _$CoachSheetResult {
  const factory _CoachSheetResult.close() = _CoachSheetClose;
  const factory _CoachSheetResult.keepTalking() = _CoachSheetKeepTalking;
  const factory _CoachSheetResult.openCourse(String courseId) = _CoachSheetOpenCourse;
}

/// Opens the Coach sheet and settles what the reader chose on the way out.
///
/// Returns the course id when they asked for one, so the CALLER navigates —
/// after the modal is gone.
Future<String?> showCoachSheet(
  BuildContext context, {
  required CoachEntry entry,
  String? lessonId,
  String? habitId,
}) async {
  final cubit = AppDI.injector.get<CoachCubit>();

  /// The device's real safe-area insets, read HERE and carried inside.
  ///
  /// `showModalBottomSheet` strips the top padding from the MediaQuery it hands
  /// its child — reasonable for a sheet that stops short of the top, wrong for
  /// this one, which is full-bleed by design. Without this the header renders
  /// under the clock and the notch, which is exactly how it first shipped to
  /// the simulator.
  final insets = MediaQuery.viewPaddingOf(context);

  final result = await showModalBottomSheet<_CoachSheetResult>(
    context: context,
    // Full-bleed, as drawn: the design's sheet is `inset: 0`, not a card that
    // leaves the page showing behind it. A conversation about something
    // difficult should not have the app peeking round its edges.
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    constraints: const BoxConstraints.expand(),
    builder: (sheetContext) => MediaQuery(
      data: MediaQuery.of(sheetContext).copyWith(
        padding: insets,
        viewPadding: insets,
      ),
      child: BlocProvider.value(
        value: cubit,
        child: _CoachSheet(entry: entry, lessonId: lessonId, habitId: habitId),
      ),
    ),
  );

  // End the session ONLY when the reader chose to end it. A swipe-away, a
  // phone call or a backgrounded app is not "I'm done" — and treating it as
  // one threw the whole conversation away for a stray gesture. The server
  // resumes an ACTIVE session next time the sheet opens.
  if (result != null) await cubit.endSession();

  return switch (result) {
    _CoachSheetOpenCourse(courseId: final id) => id,
    _ => null,
  };
}

class _CoachSheet extends StatefulWidget {
  final CoachEntry entry;
  final String? lessonId;
  final String? habitId;

  const _CoachSheet({required this.entry, this.lessonId, this.habitId});

  @override
  State<_CoachSheet> createState() => _CoachSheetState();
}

class _CoachSheetState extends State<_CoachSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    final cubit = context.read<CoachCubit>();
    // The cubit resolves fixed lines through this rather than importing
    // `context.l10n` itself, so the same cubit can be driven with no widget
    // tree at all.
    cubit.promptResolver = (key) => coachPrompt(context, key) ?? '';
    cubit.open(
      entry: widget.entry,
      locale: LocaleSettings.currentLocale.languageCode,
      lessonId: widget.lessonId,
      habitId: widget.habitId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CoachCubit, CoachState>(
      listenWhen: (prev, curr) => prev.silent != curr.silent,
      listener: (context, state) {
        // A door that decided to stay quiet is not an error and gets no
        // message — the sheet simply goes away again.
        if (state.silent) Navigator.of(context).pop(const _CoachSheetResult.close());
      },
      builder: (context, state) {
        final cubit = context.read<CoachCubit>();
        final isSafety = state.ui.kind == CoachUiKind.safety;

        return Material(
          color: CoachStyle.sheetBackground,
          // The sheet is pinned to the full screen (BoxConstraints.expand), so it
          // does NOT shrink when the keyboard opens — the composer would sit under
          // it, which is exactly what shipped to the simulator first: messages
          // visible, nothing to type into. Inset the content by the keyboard.
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: Column(
              children: [
                _Header(
                  subtitle: coachStepLabel(context, state.step),
                  onClose: () => Navigator.of(context).pop(const _CoachSheetResult.close()),
                ),
                Expanded(
                  child: switch (state.status) {
                    CoachStatus.opening => const Center(child: CircularProgressIndicator()),
                    CoachStatus.failed => _Failed(onRetry: _start),
                    _ when isSafety => CoachSafetyPanel(hotlines: state.ui.hotlines),
                    _ => CoachMessageList(
                      messages: state.messages,
                      typing: state.typing,
                      courseInvite: state.courseInvite,
                    ),
                  },
                ),
                if (!isSafety && (state.status == CoachStatus.ready || state.status == CoachStatus.sending)) CoachComposer(state: state, cubit: cubit),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// White bar, hairline underneath, the Coach's face on the left.
///
/// Two lines, as drawn. The prototype fills the second one with its own step
/// ids ("③A hỏi lại nhắc hẹn") — instrumentation for whoever is reading the
/// drawing, not something to show a person — so the slot keeps its shape and
/// carries real words instead.
class _Header extends StatelessWidget {
  final String? subtitle;
  final VoidCallback onClose;

  const _Header({required this.subtitle, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      // The drawing's 56px top was measured on a 47pt status bar, so the rule
      // is "inset + 9" rather than a constant — a Dynamic Island phone needs
      // more, and an older one less.
      padding: EdgeInsets.fromLTRB(
        16.w,
        MediaQuery.viewPaddingOf(context).top + 9.h,
        16.w,
        12.h,
      ),
      decoration: const BoxDecoration(
        color: CoachStyle.surface,
        border: Border(bottom: BorderSide(color: CoachStyle.border)),
      ),
      child: Row(
        children: [
          const CoachFace.header(),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.coach.sheetTitle,
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                    color: CoachStyle.textPrimary,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      color: CoachStyle.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
              child: Text(
                context.l10n.coach.close,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: CoachStyle.textChip,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  final VoidCallback onRetry;

  const _Failed({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.coach.failedTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                height: 1.55,
                color: CoachStyle.textBody,
              ),
            ),
            SizedBox(height: 14.h),
            GestureDetector(
              onTap: onRetry,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 11.h),
                decoration: BoxDecoration(
                  color: CoachStyle.chipBackground,
                  border: Border.all(color: CoachStyle.border, width: 1.5),
                  borderRadius: BorderRadius.circular(99.r),
                ),
                child: Text(
                  context.l10n.coach.retry,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: CoachStyle.textChip,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
