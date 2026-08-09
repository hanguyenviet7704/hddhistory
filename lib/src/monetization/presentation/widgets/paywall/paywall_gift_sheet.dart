part of '../../../monetization.dart';
// PaywallGiftSheet đã bị gỡ: popup mở thẳng bản paywall rút gọn
// (_PaywallCompactBody). File này giữ lại các mảnh sheet dùng chung.

/// Live countdown to [endAtUtc]. Stateful on purpose: as a plain build-time
/// computation the digits froze at whatever second the sheet opened on —
/// nothing above it rebuilds while the reader just looks at the offer.
class _CountdownRow extends StatefulWidget {
  final DateTime endAtUtc;

  const _CountdownRow({required this.endAtUtc});

  @override
  State<_CountdownRow> createState() => _CountdownRowState();
}

class _CountdownRowState extends State<_CountdownRow> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      // Down to zero there is nothing left to tick toward — the row parks on
      // 00:00:00 rather than burning a timer for the rest of the sheet's life.
      if (!widget.endAtUtc.isAfter(DateTime.now().toUtc())) {
        _ticker?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parts = resolvePaywallCountdownParts(widget.endAtUtc, DateTime.now().toUtc());
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppText(
          l10n.monetization.giftSheetEndsIn,
          style: AppStyle.text12.copyWith(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8F8AB9),
          ),
        ),
        8.horizontalSpace,
        _chip(parts.hours),
        _colon(),
        _chip(parts.minutes),
        _colon(),
        _chip(parts.seconds),
      ],
    );
  }

  Widget _chip(String value) => Container(
    constraints: BoxConstraints(minWidth: 38.w),
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
    decoration: BoxDecoration(
      color: const Color(0xFFEDEAFD),
      borderRadius: BorderRadius.circular(9.r),
    ),
    child: AppText(
      value,
      textAlign: TextAlign.center,
      style: AppStyle.text16.copyWith(
        fontWeight: FontWeight.w800,
        color: const Color(0xFF3A3355),
      ),
    ),
  );

  Widget _colon() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 5.w),
    child: AppText(
      ':',
      style: AppStyle.text16.copyWith(
        fontWeight: FontWeight.w800,
        color: const Color(0xFFA8A2D6),
      ),
    ),
  );
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF2F1FA),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34.w,
          height: 34.w,
          child: Icon(
            Icons.close_rounded,
            size: 18.w,
            color: const Color(0xFF6B659B),
          ),
        ),
      ),
    );
  }
}
