part of '../../../monetization.dart';

@visibleForTesting
class PaywallCountdownParts {
  final String hours;
  final String minutes;
  final String seconds;

  const PaywallCountdownParts({
    required this.hours,
    required this.minutes,
    required this.seconds,
  });
}

@visibleForTesting
PaywallCountdownParts resolvePaywallCountdownParts(DateTime endAtUtc, DateTime nowUtc) {
  final remaining = endAtUtc.toUtc().difference(nowUtc.toUtc());
  final clamped = remaining.isNegative ? Duration.zero : remaining;

  return PaywallCountdownParts(
    hours: clamped.inHours.toString().padLeft(2, '0'),
    minutes: clamped.inMinutes.remainder(60).toString().padLeft(2, '0'),
    seconds: clamped.inSeconds.remainder(60).toString().padLeft(2, '0'),
  );
}

class _CountdownStrip extends StatefulWidget {
  final ResolvedPaywallStrategyEntity? strategy;
  final bool compact;

  const _CountdownStrip({
    required this.strategy,
    this.compact = false,
  });

  @override
  State<_CountdownStrip> createState() => _CountdownStripState();
}

class _CountdownStripState extends State<_CountdownStrip> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _CountdownStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.strategy?.endAtUtc == widget.strategy?.endAtUtc) return;
    _timer?.cancel();
    _startTimerIfNeeded();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    if (widget.strategy?.hasSaleCountdown != true) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final endAtUtc = widget.strategy?.endAtUtc;
    if (widget.strategy?.hasSaleCountdown != true || endAtUtc == null) return const SizedBox.shrink();

    final countdown = resolvePaywallCountdownParts(endAtUtc, DateTime.now().toUtc());

    if (widget.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            l10n.monetization.saleCountdownEndsIn,
            maxLines: 1,
            style: AppStyle.text12.copyWith(
              color: AppCustomColor.paywallSaleStripMuted,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          6.horizontalSpace,
          _CountdownSegment(value: countdown.hours),
          _CountdownColon(),
          _CountdownSegment(value: countdown.minutes),
          _CountdownColon(),
          _CountdownSegment(value: countdown.seconds),
        ],
      );
    }

    // Design's LIMITED OFFER card: bolt + label on the left, light timer chips
    // on the right, on a translucent white card — not the old centred pill,
    // which read as decoration rather than as a deadline.
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 9.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFD9D5F6)),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, size: 15.w, color: const Color(0xFF6E67D8)),
          6.horizontalSpace,
          Expanded(
            child: AppText(
              l10n.monetization.saleCountdownLabel.toUpperCase(),
              maxLines: 1,
              // Locale-proof: vi/ja run long against the fixed-width timer
              // chips, and a clipped "ƯU ĐÃI GIỚI HẠN THỜI G…" reads worse
              // than the same words a point smaller.
              enableFitScaleDown: true,
              style: AppStyle.text12.copyWith(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.69,
                color: const Color(0xFF6E67D8),
              ),
            ),
          ),
          8.horizontalSpace,
          _CountdownSegment(value: countdown.hours, light: true),
          _CountdownColon(light: true),
          _CountdownSegment(value: countdown.minutes, light: true),
          _CountdownColon(light: true),
          _CountdownSegment(value: countdown.seconds, light: true),
        ],
      ),
    );
  }
}

/// One timer cell. `light` is the design's full-width strip (lavender chip,
/// dark digits); the default dark chip stays for the compact strip inside the
/// purchase bar, which sits on a white card and needs the contrast.
class _CountdownSegment extends StatelessWidget {
  final String value;
  final bool light;

  const _CountdownSegment({required this.value, this.light = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 27.w),
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      decoration: BoxDecoration(
        color: light ? const Color(0xFFEDEAFD) : const Color(0xFF4B44CA),
        borderRadius: BorderRadius.circular(light ? 7.r : 8.r),
      ),
      child: AppText(
        value,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: AppStyle.text14.copyWith(
          fontSize: light ? 12.5.sp : null,
          color: light ? const Color(0xFF3A3355) : AppCustomColor.backgroundWhite,
          fontWeight: light ? FontWeight.w800 : FontWeight.w700,
          height: 1.75,
        ),
      ),
    );
  }
}

class _CountdownColon extends StatelessWidget {
  final bool light;

  const _CountdownColon({this.light = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: AppText(
        ':',
        maxLines: 1,
        style: AppStyle.text14.copyWith(
          fontSize: light ? 12.sp : null,
          color: light ? const Color(0xFFA8A2D6) : AppCustomColor.backgroundWhite,
          fontWeight: light ? FontWeight.w800 : FontWeight.w700,
          height: 1.4,
        ),
      ),
    );
  }
}
