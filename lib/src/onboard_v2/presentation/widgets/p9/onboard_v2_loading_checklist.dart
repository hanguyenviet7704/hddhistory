part of '../../../onboard_v2.dart';

/// Bốn dòng "đang đọc câu trả lời" của S9. Mỗi dòng trôi lên, quay một nhịp
/// rồi đóng dấu tích xanh; dòng sau trễ hơn dòng trước, cả cụm mờ đi ở cuối
/// chu kỳ 6s và lặp lại.
///
/// Chu kỳ chỉ để trang trí — thời điểm rời màn do
/// [OnboardV2LoadingPage] quyết định (đủ 2,4s VÀ gợi ý đã xong).
class OnboardV2LoadingChecklist extends StatefulWidget {
  const OnboardV2LoadingChecklist({super.key, required this.lines});

  final List<String> lines;

  @override
  State<OnboardV2LoadingChecklist> createState() => _OnboardV2LoadingChecklistState();
}

class _OnboardV2LoadingChecklistState extends State<OnboardV2LoadingChecklist> with SingleTickerProviderStateMixin {
  static const _cycle = Duration(milliseconds: 6000);

  /// Độ trễ giữa hai dòng, theo TỈ LỆ chu kỳ (18% của 6s ≈ 1,08s).
  static const _stagger = 0.18;
  static const _rowFade = 0.05;
  static const _ringHold = 0.09;
  static const _checkPop = 0.13;
  static const _groupHoldEnd = 0.92;
  static const _groupFadeEnd = 0.96;
  static const _riseOffset = 10.0;
  static const _popCurve = Cubic(0.34, 1.56, 0.64, 1);

  late final AnimationController _controller;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _cycle);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.maybeOf(context);
    _reduceMotion = mediaQuery?.disableAnimations ?? WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (_reduceMotion) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < widget.lines.length; i++) ...[
              if (i > 0) 12.verticalSpace,
              _buildRow(i),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRow(int index) {
    final frame = _resolve(_controller.value, index);
    final row = Row(
      key: ValueKey('onboard_v2_loading_line_$index'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: AppText(
            widget.lines[index],
            maxLines: 2,
            overflow: TextOverflow.visible,
            style: AppStyle.text14.copyWith(color: AppCustomColor.streakTextMuted, fontWeight: FontWeight.w500, height: 1.45),
          ),
        ),
        10.horizontalSpace,
        SizedBox(
          width: 17.w,
          height: 17.w,
          child: Stack(
            children: [
              Opacity(
                opacity: frame.ringOpacity,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppCustomColor.onboardCheckIdleRing, width: 1.8.w),
                  ),
                ),
              ),
              Opacity(
                opacity: frame.checkOpacity,
                child: Transform.scale(
                  scale: frame.checkScale,
                  child: Container(
                    decoration: const BoxDecoration(color: AppCustomColor.onboardCheckDone, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Icon(Icons.check_rounded, size: 11.w, color: AppCustomColor.textWhite),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (_reduceMotion) return row;
    return Opacity(
      opacity: frame.rowOpacity,
      child: Transform.translate(offset: Offset(0, frame.rowOffsetY), child: row),
    );
  }

  _ChecklistFrame _resolve(double t, int index) {
    if (_reduceMotion) return const _ChecklistFrame(rowOpacity: 1, rowOffsetY: 0, ringOpacity: 0, checkOpacity: 1, checkScale: 1);

    final start = _stagger * index;

    // Dòng chữ.
    double rowOpacity;
    double rowOffsetY;
    if (t < start) {
      rowOpacity = 0;
      rowOffsetY = _riseOffset;
    } else if (t < start + _rowFade) {
      final eased = Curves.ease.transform((t - start) / _rowFade);
      rowOpacity = eased;
      rowOffsetY = _riseOffset * (1 - eased);
    } else if (t < _groupHoldEnd) {
      rowOpacity = 1;
      rowOffsetY = 0;
    } else if (t < _groupFadeEnd) {
      final eased = Curves.ease.transform((t - _groupHoldEnd) / (_groupFadeEnd - _groupHoldEnd));
      rowOpacity = 1 - eased;
      rowOffsetY = _riseOffset * eased;
    } else {
      rowOpacity = 0;
      rowOffsetY = _riseOffset;
    }

    // Vòng chờ: hiện cùng dòng chữ, tắt khi dấu tích đóng xong.
    double ringOpacity;
    if (t < start) {
      ringOpacity = 0;
    } else if (t < start + _rowFade) {
      ringOpacity = (t - start) / _rowFade;
    } else if (t < start + _ringHold) {
      ringOpacity = 1;
    } else if (t < start + _checkPop) {
      ringOpacity = 1 - (t - start - _ringHold) / (_checkPop - _ringHold);
    } else {
      ringOpacity = 0;
    }

    // Dấu tích: nảy ra từ 40% kích thước.
    double checkOpacity;
    double checkScale;
    if (t < start + _ringHold) {
      checkOpacity = 0;
      checkScale = 0.4;
    } else if (t < start + _checkPop) {
      final eased = _popCurve.transform((t - start - _ringHold) / (_checkPop - _ringHold));
      checkOpacity = eased.clamp(0.0, 1.0);
      checkScale = ui.lerpDouble(0.4, 1, eased)!;
    } else if (t < _groupHoldEnd) {
      checkOpacity = 1;
      checkScale = 1;
    } else if (t < _groupFadeEnd) {
      final eased = Curves.ease.transform((t - _groupHoldEnd) / (_groupFadeEnd - _groupHoldEnd));
      checkOpacity = 1 - eased;
      checkScale = ui.lerpDouble(1, 0.4, eased)!;
    } else {
      checkOpacity = 0;
      checkScale = 0.4;
    }

    return _ChecklistFrame(
      rowOpacity: rowOpacity.clamp(0.0, 1.0),
      rowOffsetY: rowOffsetY,
      ringOpacity: ringOpacity.clamp(0.0, 1.0),
      checkOpacity: checkOpacity.clamp(0.0, 1.0),
      checkScale: checkScale,
    );
  }
}

class _ChecklistFrame {
  const _ChecklistFrame({
    required this.rowOpacity,
    required this.rowOffsetY,
    required this.ringOpacity,
    required this.checkOpacity,
    required this.checkScale,
  });

  final double rowOpacity;
  final double rowOffsetY;
  final double ringOpacity;
  final double checkOpacity;
  final double checkScale;
}
