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
  static const _itemExtent = 52.0;
  static const _wheelHeight = 156.0;

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
    final itemExtent = _itemExtent.h;
    return SizedBox(
      height: _wheelHeight.h,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: itemExtent,
        // Design vẽ ba dòng phẳng, không phải trụ tròn — kéo đường kính lên và
        // gần như tắt phối cảnh để mặt cong biến mất.
        perspective: 0.00001,
        diameterRatio: 20,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (_) {
          AppHaptic.select();
          _scheduleEmit();
        },
        childDelegate: ListWheelChildLoopingListDelegate(
          children: [
            for (var i = 0; i < count; i++)
              _WheelLabel(controller: controller, index: i, count: count, itemExtent: itemExtent, text: label(i)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _wheel(_hour, 24, (i) => i.toString().padLeft(2, '0'))),
        AppText(
          ':',
          maxLines: 1,
          style: AppStyle.text40.copyWith(fontWeight: FontWeight.w700, color: AppCustomColor.textPrimary, height: 1),
        ),
        Expanded(child: _wheel(_minute, 4, (i) => _minutes[i].toString().padLeft(2, '0'))),
      ],
    );
  }
}

/// Một nấc của bánh xe. Chữ to dần và đậm dần khi tiến về giữa — design cho số
/// đang chọn 44px/700 màu chữ chính, hai số kề 24px/500 màu nhạt.
class _WheelLabel extends StatelessWidget {
  const _WheelLabel({
    required this.controller,
    required this.index,
    required this.count,
    required this.itemExtent,
    required this.text,
  });

  final FixedExtentScrollController controller;
  final int index;
  final int count;
  final double itemExtent;
  final String text;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final distance = _distanceFromCentre();
        final fontSize = ui.lerpDouble(44, 24, distance)!;
        return Center(
          child: AppText(
            text,
            maxLines: 1,
            style: AppStyle.text40.copyWith(
              fontSize: fontSize.sp,
              height: 1,
              fontWeight: distance < 0.5 ? FontWeight.w700 : FontWeight.w500,
              color: Color.lerp(AppCustomColor.textPrimary, AppCustomColor.onboardWheelIdle, distance),
            ),
          ),
        );
      },
    );
  }

  /// 0 = đúng giữa, 1 = cách giữa một nấc trở lên. Danh sách cuộn vòng nên phải
  /// gói khoảng cách về nửa vòng gần nhất, không thì số cuối và số đầu bị coi
  /// là cách nhau cả vòng.
  double _distanceFromCentre() {
    if (!controller.hasClients || !controller.position.hasPixels || itemExtent <= 0) {
      return (controller.initialItem % count) == index ? 0 : 1;
    }
    var delta = (controller.offset / itemExtent - index) % count;
    if (delta > count / 2) delta -= count;
    if (delta < -count / 2) delta += count;
    return delta.abs().clamp(0.0, 1.0);
  }
}
