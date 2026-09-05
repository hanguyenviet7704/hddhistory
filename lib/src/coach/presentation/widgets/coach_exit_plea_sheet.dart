part of '../../coach.dart';

enum CoachExitDecision { stay, leave }

/// Luồng 6 — "Níu lại khi user rời đi".
///
/// A small sheet from the bottom, not a cover: the reader still sees the line
/// they were answering behind it. One written sentence, two buttons, no third
/// option and no text box — "đây là chỗ dễ thành níu kéo phiền, nên nó có trần
/// chặt hơn mọi luồng khác".
class CoachExitPleaSheet extends StatelessWidget {
  final String line;

  const CoachExitPleaSheet._({required this.line});

  static Future<CoachExitDecision?> show(BuildContext context, String line) {
    return showModalBottomSheet<CoachExitDecision>(
      context: context,
      backgroundColor: Colors.transparent,
      // Light, so the conversation behind stays legible: "user vẫn thấy câu
      // mình đang trả lời dở phía sau".
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (_) => CoachExitPleaSheet._(line: line),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.coach;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      // design: radius 28, padding 22/20/30.
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
          // The grabber: this is a sheet that came up from the bottom, and it
          // says so before the reader reads a word of it.
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
          // The Coach asks this, so the Coach is in it — the avatar beside the
          // line, the line ranged left like every other thing it says. Centred
          // text with no avatar read as a system dialog (owner, 2026-09-05).
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CoachSlime(mood: CoachSlimeMood.gentle, size: 46),
              SizedBox(width: 13.w),
              Expanded(
                child: Text(
                  line,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                    color: CoachStyle.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          // Stacked, not side by side: staying is the offer, leaving is always
          // available and needs no button of its own weight.
          _PleaButton(
            label: l10n.exitPleaStay,
            primary: true,
            onTap: () => Navigator.of(context).pop(CoachExitDecision.stay),
          ),
          SizedBox(height: 11.h),
          _PleaButton(
            label: l10n.exitPleaLeave,
            primary: false,
            onTap: () => Navigator.of(context).pop(CoachExitDecision.leave),
          ),
        ],
      ),
    );
  }
}

class _PleaButton extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _PleaButton({required this.label, required this.primary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () {
          AppHaptic.select();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          // design: 52 tall and a pill for the offer, 48 and plain text for
          // the way out.
          height: (primary ? 52 : 48).h,
          alignment: Alignment.center,
          decoration: primary
              ? BoxDecoration(
                  color: CoachStyle.skin,
                  borderRadius: BorderRadius.circular(99.r),
                )
              : null,
          child: Text(
            label,
            style: TextStyle(
              fontSize: (primary ? 15.5 : 14).sp,
              fontWeight: primary ? FontWeight.w800 : FontWeight.w700,
              color: primary ? AppCustomColor.textWhite : CoachStyle.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
