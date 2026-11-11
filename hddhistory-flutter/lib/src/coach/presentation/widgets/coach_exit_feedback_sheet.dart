part of '../../coach.dart';

/// Luồng 6, phần đuôi — "vừa rồi thế nào?", hỏi ngay sau ⟨Vẫn đóng⟩.
///
/// The one feedback door in the product since the 👍/👎 toast was removed
/// (2026-09-14). The plea asked them to stay and they said no; this asks the
/// one thing worth asking afterwards.
///
/// The chips carry praise AND complaint in one list, which is what let the
/// thumb go: somebody who ticks "hiểu đúng chuyện mình kể" has said the Coach
/// did well without being asked a yes/no question first. The note box is always
/// open rather than hiding behind a "Khác" chip — a closed list cannot hold the
/// sentence that actually explains the tick.
///
/// Nothing here can keep the reader in: ⟨Gửi đánh giá⟩, ⟨Để sau⟩ and a tap on
/// the barrier all end with the Coach closing. Somebody who has decided to
/// leave twice over must not be made to answer a form to get out.
class CoachExitFeedbackSheet extends StatefulWidget {
  /// `story` · `scene` · `recap` · `onboard` · `hub`, from the server. Anything
  /// else — including an API that does not send it — falls back to the story
  /// chips, which are the ones that make sense about a conversation.
  final String kind;

  const CoachExitFeedbackSheet._({required this.kind});

  /// Returns what they said, or null when they skipped — either way the
  /// caller closes the Coach next.
  static Future<CoachExitFeedback?> show(BuildContext context, {String kind = ''}) {
    return showModalBottomSheet<CoachExitFeedback>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (_) => CoachExitFeedbackSheet._(kind: kind),
    );
  }

  @override
  State<CoachExitFeedbackSheet> createState() => _CoachExitFeedbackSheetState();
}

class _CoachExitFeedbackSheetState extends State<CoachExitFeedbackSheet> {
  final Set<String> _chips = {};
  final TextEditingController _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ⟨Gửi đánh giá⟩ turns on for words alone, so the field has to rebuild it.
    _note.addListener(_onNoteChanged);
  }

  void _onNoteChanged() => setState(() {});

  @override
  void dispose() {
    _note.removeListener(_onNoteChanged);
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.coach;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final hub = widget.kind == 'hub';

    // Praise first, in the design's order, and a different list per kind — the
    // ids are the server's enum, which is also what decides whether a row needs
    // a person. `RATING_CHIPS_BY_KIND` on the API is the same list; if the two
    // ever disagree the server wins, because it refuses chips a kind never
    // offered.
    final chips = switch (widget.kind) {
      'scene' => [
          ('scene_realistic', l10n.rateChipSceneRealistic),
          ('scene_useful', l10n.rateChipSceneUseful),
          ('scene_unrealistic', l10n.rateChipSceneUnrealistic),
          ('scene_unnatural', l10n.rateChipSceneUnnatural),
          ('not_helpful', l10n.rateChipNotHelpful),
        ],
      'recap' => [
          ('recap_accurate', l10n.rateChipRecapAccurate),
          ('recap_on_point', l10n.rateChipRecapOnPoint),
          ('recap_wrong', l10n.rateChipRecapWrong),
          ('recap_bad_level', l10n.rateChipRecapBadLevel),
          ('not_helpful', l10n.rateChipNotHelpful),
        ],
      'onboard' => [
          ('onboard_easy', l10n.rateChipOnboardEasy),
          ('too_many_questions', l10n.rateChipOnboardTooMany),
          ('onboard_too_personal', l10n.rateChipOnboardTooPersonal),
          ('onboard_unclear', l10n.rateChipOnboardUnclear),
        ],
      // No praise chip: they never spoke to the Coach, so there is nothing to
      // praise. This kind asks why they never started instead.
      'hub' => [
          ('hub_unsure', l10n.rateChipHubUnsure),
          ('hub_nothing_fits', l10n.rateChipHubNothingFits),
          ('hub_just_looking', l10n.rateChipHubJustLooking),
          ('hub_busy', l10n.rateChipHubBusy),
        ],
      _ => [
          ('understood_me', l10n.rateChipUnderstood),
          ('right_questions', l10n.rateChipRightQuestions),
          ('too_long', l10n.rateChipTooLong),
          ('imposed_thinking', l10n.rateChipImposed),
          ('not_helpful', l10n.rateChipNotHelpful),
        ],
    };

    return Padding(
      // The note box lifts the sheet clear of the keyboard; without this the
      // field is typed into behind it.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 30.h + bottomInset),
        decoration: BoxDecoration(
          color: CoachStyle.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          boxShadow: const [
            BoxShadow(color: Color(0x380D121C), blurRadius: 40, offset: Offset(0, -12)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E8EF),
                  borderRadius: BorderRadius.circular(99.r),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            // Still the Coach asking, exactly as the plea before it — the
            // avatar and a left-ranged line, not a centred system prompt.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CoachSlime(mood: CoachSlimeMood.gentle, size: 46),
                SizedBox(width: 13.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hub ? l10n.rateSheetTitleHub : l10n.rateSheetTitle,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                          color: CoachStyle.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        hub ? l10n.rateSheetSubtitleHub : l10n.rateSheetSubtitle,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          color: CoachStyle.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: chips
                  .map(
                    (chip) => _Pill(
                      label: chip.$2,
                      selected: _chips.contains(chip.$1),
                      onTap: () {
                        AppHaptic.select();
                        setState(() {
                          if (!_chips.remove(chip.$1)) _chips.add(chip.$1);
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            // Always open, never behind a "Khác" chip: the sentence somebody
            // types is the only part of this sheet a closed list cannot hold.
            SizedBox(height: 14.h),
            _FormField(
              controller: _note,
              hint: l10n.rateNoteHint,
              enabled: true,
              height: 92,
              radius: 16,
              maxLines: 4,
            ),
            SizedBox(height: 18.h),
            _FilledButton(
              label: l10n.rateSend,
              // Words alone are an answer. Requiring a chip would throw away
              // the most specific thing anybody tells us.
              enabled: _chips.isNotEmpty || _note.text.trim().isNotEmpty,
              height: 52,
              radius: 99,
              fontSize: 15.5,
              onTap: () {
                AppHaptic.select();
                Navigator.of(context).pop(
                  CoachExitFeedback(chips: _chips.toList(), note: _note.text.trim()),
                );
              },
            ),
            SizedBox(height: 11.h),
            _PleaButton(
              label: l10n.rateLater,
              primary: false,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// What they said on the way out: the chips they picked, and their own words.
class CoachExitFeedback {
  final List<String> chips;
  final String note;

  const CoachExitFeedback({required this.chips, required this.note});
}
