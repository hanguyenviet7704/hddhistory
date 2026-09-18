part of '../../../onboard_v2.dart';

/// Bánh xe chọn giờ `HH:mm` của S8 — 24 giờ × 4 phút (bước 15), cuộn vòng.
/// Mọi giá trị nhả ra đều khớp regex guard của
/// [OnboardV2Cubit.setReminderTime].
class OnboardV2TimeWheel extends StatefulWidget {
  const OnboardV2TimeWheel({super.key, required this.value, required this.onChanged});

  /// `HH:mm`.
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<OnboardV2TimeWheel> createState() => _OnboardV2TimeWheelState();
}

class _OnboardV2TimeWheelState extends State<OnboardV2TimeWheel> {
  static const _minutes = [0, 15, 30, 45];

  /// A flick crosses many items before settling — `ListWheelScrollView` fires
  /// `onSelectedItemChanged` once PER item crossed, up to ~24 times. The
  /// haptic stays per-item (that's the intended feel), but emitting the value
  /// on every one of those would mean up to 24 state emits + analytics events
  /// + rebuilds for a single flick. Debounce so only the value the wheel
  /// SETTLES on gets emitted.
  static const _emitDebounce = Duration(milliseconds: 250);

  late FixedExtentScrollController _hour;
  late FixedExtentScrollController _minute;
  Timer? _emitTimer;

  /// Set while a debounced emit is pending or while the user's finger is on
  /// the wheel, so [didUpdateWidget]'s programmatic `jumpToItem` sync (e.g. a
  /// preset chip tapped elsewhere) never fights an in-progress scroll.
  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();
    final parsed = _parse(widget.value);
    _hour = FixedExtentScrollController(initialItem: parsed.$1);
    _minute = FixedExtentScrollController(initialItem: _minutes.indexOf(parsed.$2).clamp(0, 3));
  }

  @override
  void didUpdateWidget(covariant OnboardV2TimeWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    if (_isUserScrolling) return;
    final parsed = _parse(widget.value);
    if (_hour.hasClients && _hour.selectedItem % 24 != parsed.$1) _hour.jumpToItem(parsed.$1);
    final minuteIndex = _minutes.indexOf(parsed.$2).clamp(0, 3);
    if (_minute.hasClients && _minute.selectedItem % 4 != minuteIndex) _minute.jumpToItem(minuteIndex);
  }

  @override
  void dispose() {
    _emitTimer?.cancel();
    _hour.dispose();
    _minute.dispose();
    super.dispose();
  }

  (int, int) _parse(String value) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
    return (int.tryParse(match?.group(1) ?? '') ?? 21, int.tryParse(match?.group(2) ?? '') ?? 0);
  }

  /// Called on every item crossed while flinging — resets the debounce timer
  /// so only the value the wheel is on ~250ms after the LAST item crossing
  /// (i.e. once it has settled) actually gets emitted.
  void _scheduleEmit() {
    _isUserScrolling = true;
    _emitTimer?.cancel();
    _emitTimer = Timer(_emitDebounce, () {
      _isUserScrolling = false;
      _emit();
    });
  }

  void _emit() {
    if (!_hour.hasClients || !_minute.hasClients) return;
    final hour = _hour.selectedItem % 24;
    final minute = _minutes[_minute.selectedItem % 4];
    widget.onChanged('${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
  }

  Widget _wheel(FixedExtentScrollController controller, int count, String Function(int) label) {
    return SizedBox(
      width: 88.w,
      height: 156.h,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 52.h,
        perspective: 0.003,
        diameterRatio: 1.6,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (_) {
          AppHaptic.select();
          _scheduleEmit();
        },
        childDelegate: ListWheelChildLoopingListDelegate(
          children: [
            for (var i = 0; i < count; i++)
              Center(
                child: AppText(
                  label(i),
                  maxLines: 1,
                  style: AppStyle.text32.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.textPrimary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(color: AppCustomColor.backgroundGray, borderRadius: BorderRadius.circular(20.r)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _wheel(_hour, 24, (i) => i.toString().padLeft(2, '0')),
          AppText(
            ':',
            maxLines: 1,
            style: AppStyle.text32.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.textPrimary),
          ),
          _wheel(_minute, 4, (i) => _minutes[i].toString().padLeft(2, '0')),
        ],
      ),
    );
  }
}
