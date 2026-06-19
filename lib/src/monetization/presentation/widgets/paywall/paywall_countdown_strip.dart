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
            style: AppStyle.text10.copyWith(
              color: AppCustomColor.textBrand.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
              height: 1.75,
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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: AppCustomColor.backgroundWhite.withValues(alpha: 0.65)),
      ),
      child: AppText(
        '${countdown.hours}:${countdown.minutes}:${countdown.seconds}',
        textAlign: TextAlign.center,
        maxLines: 1,
        style: AppStyle.text12.copyWith(
          color: AppCustomColor.textBrand,
          fontWeight: FontWeight.w700,
          height: 1.5,
        ),
      ),
    );
  }
}

class _CountdownSegment extends StatelessWidget {
  final String value;

  const _CountdownSegment({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 27.w),
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      decoration: BoxDecoration(
        color: const Color(0xFF4B44CA),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: AppText(
        value,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: AppStyle.text14.copyWith(
          color: AppCustomColor.backgroundWhite,
          fontWeight: FontWeight.w700,
          height: 1.75,
        ),
      ),
    );
  }
}

class _CountdownColon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: AppText(
        ':',
        maxLines: 1,
        style: AppStyle.text12.copyWith(
          color: AppCustomColor.textBrand.withValues(alpha: 0.7),
          fontWeight: FontWeight.w700,
          height: 1.75,
        ),
      ),
    );
  }
}
