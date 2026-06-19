part of '../../../monetization.dart';

class _CountdownStrip extends StatefulWidget {
  final ResolvedPaywallStrategyEntity? strategy;

  const _CountdownStrip({required this.strategy});

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

    final remaining = endAtUtc.difference(DateTime.now().toUtc());
    final clamped = remaining.isNegative ? Duration.zero : remaining;
    final hours = clamped.inHours.toString().padLeft(2, '0');
    final minutes = clamped.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = clamped.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: AppCustomColor.backgroundWhite.withValues(alpha: 0.65)),
      ),
      child: AppText(
        '$hours:$minutes:$seconds',
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
