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
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (_) => CoachExitPleaSheet._(line: line),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n.coach;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 18.h + bottomInset),
      decoration: BoxDecoration(
        color: CoachStyle.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            line,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: CoachStyle.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _PleaButton(
                  label: l10n.exitPleaStay,
                  primary: true,
                  onTap: () => Navigator.of(context).pop(CoachExitDecision.stay),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _PleaButton(
                  label: l10n.exitPleaLeave,
                  primary: false,
                  onTap: () => Navigator.of(context).pop(CoachExitDecision.leave),
                ),
              ),
            ],
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
          height: 46.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary ? AppCustomColor.brandPrimary : CoachStyle.sampleBackground,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: primary ? AppCustomColor.textWhite : CoachStyle.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
