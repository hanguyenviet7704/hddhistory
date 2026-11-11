part of '../../../monetization.dart';

/// The "LogicSale" campaign's own countdown — a segment-targeted offer
/// resolved server-side (`GET /paywall-config/logic-sale`), independent of
/// the CMS-authored `saleStrategy.saleEvent` [_CountdownStrip] renders. Kept
/// as its own widget rather than folded into that one: a LogicSale can run
/// past 24 hours, where bare H:M:S stops being readable, so a day count is
/// spelled out ahead of it once the remainder crosses a day.
///
/// [endAt] is already a device-LOCAL deadline (see
/// `IapCubit._logicSaleLocalDeadline`): the server's `endAtUtc - nowUtc` gap
/// is captured once, at fetch time, and translated onto this device's own
/// clock. Every tick below only ever diffs against that same local clock, so
/// a device with the wrong time-of-day still counts down the right amount of
/// time — it only matters that the clock does not jump mid-session.
class _LogicSaleCountdownStrip extends StatefulWidget {
  final DateTime? endAt;

  const _LogicSaleCountdownStrip({required this.endAt});

  @override
  State<_LogicSaleCountdownStrip> createState() => _LogicSaleCountdownStripState();
}

class _LogicSaleCountdownStripState extends State<_LogicSaleCountdownStrip> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _LogicSaleCountdownStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endAt == widget.endAt) return;
    _timer?.cancel();
    _startTimerIfNeeded();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    if (widget.endAt == null) return;
    // The strip hides itself once the deadline passes (see build) — the timer
    // just has to keep ticking until that frame renders nothing.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final endAt = widget.endAt;
    if (endAt == null) return const SizedBox.shrink();

    final remaining = endAt.difference(DateTime.now().toUtc());
    if (remaining <= Duration.zero) return const SizedBox.shrink();

    final display = _formatRemaining(remaining);

    // Same translucent card + bolt-icon language as the sale-event strip
    // above it, so the two read as one family even though only one of them
    // is ever live for a given reader.
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 9.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFF6EDD5)),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, size: 15.w, color: const Color(0xFF9C7C28)),
          6.horizontalSpace,
          Expanded(
            child: AppText(
              l10n.monetization.logicSaleCountdownLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              enableFitScaleDown: true,
              style: AppStyle.text12.copyWith(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF9C7C28),
              ),
            ),
          ),
          8.horizontalSpace,
          AppText(
            display,
            maxLines: 1,
            style: AppStyle.text14.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF554B33),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRemaining(Duration remaining) {
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    final time = '$hours:$minutes:$seconds';
    if (days < 1) return time;
    return l10n.monetization.logicSaleCountdownWithDays(days: '$days', time: time);
  }
}
