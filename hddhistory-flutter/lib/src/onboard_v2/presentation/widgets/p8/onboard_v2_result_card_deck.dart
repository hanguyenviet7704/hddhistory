part of '../../../onboard_v2.dart';

/// Bộ thẻ khoá học xếp chồng ở S10. Thẻ trên cùng đi theo ngón tay và hơi
/// nghiêng; thả tay quá 45px thì nó bay hẳn sang trái, thẻ dưới trồi lên.
///
/// Không dùng `PageView`: design cho thẻ đã lật bay chéo ra khỏi màn còn thẻ
/// kế tiếp nằm SAU nó chứ không nằm cạnh, nên phải là chồng thẻ thật.
class OnboardV2ResultCardDeck extends StatefulWidget {
  const OnboardV2ResultCardDeck({
    super.key,
    required this.courses,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  final List<CourseEntity> courses;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  static const deckHeight = 374.0;

  @override
  State<OnboardV2ResultCardDeck> createState() => _OnboardV2ResultCardDeckState();
}

class _OnboardV2ResultCardDeckState extends State<OnboardV2ResultCardDeck> {
  /// Vuốt quá ngần này (theo design) thì mới coi là đổi thẻ.
  static const _commitThreshold = 45.0;

  /// Hệ số nghiêng theo quãng kéo — 0,035 độ trên mỗi điểm ảnh.
  static const _tiltPerPixel = 0.035;

  /// Kéo ngược ở thẻ đầu/cuối thì nặng tay hẳn đi.
  static const _rubberBand = 0.3;

  double _dragDx = 0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final cardHeight = OnboardV2ResultCardDeck.deckHeight.h;
        return GestureDetector(
          key: const Key('onboard_v2_result_card_deck'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) => setState(() {
            _isDragging = true;
            _dragDx = 0;
          }),
          onHorizontalDragUpdate: (details) => setState(() => _dragDx = _resist(_dragDx + details.delta.dx)),
          onHorizontalDragEnd: (_) => _settle(),
          onHorizontalDragCancel: _settle,
          child: SizedBox(
            height: cardHeight,
            child: Stack(
              children: [
                for (var i = widget.courses.length - 1; i >= 0; i--)
                  _buildCard(index: i, cardWidth: cardWidth, cardHeight: cardHeight),
              ],
            ),
          ),
        );
      },
    );
  }

  double _resist(double dx) {
    final isFirst = widget.currentIndex == 0;
    final isLast = widget.currentIndex >= widget.courses.length - 1;
    if ((isFirst && dx > 0) || (isLast && dx < 0)) return dx * _rubberBand;
    return dx;
  }

  void _settle() {
    final dx = _dragDx;
    setState(() {
      _isDragging = false;
      _dragDx = 0;
    });
    if (dx.abs() <= _commitThreshold.w) return;
    final next = (widget.currentIndex + (dx < 0 ? 1 : -1)).clamp(0, widget.courses.length - 1);
    if (next == widget.currentIndex) return;
    AppHaptic.select();
    widget.onIndexChanged(next);
  }

  Widget _buildCard({required int index, required double cardWidth, required double cardHeight}) {
    final current = widget.currentIndex;
    final duration = _isDragging && index == current ? Duration.zero : const Duration(milliseconds: 420);
    const curve = Cubic(0.22, 0.61, 0.36, 1);
    // Tâm biến hình nằm DƯỚI thẻ (50% 120%) nên thẻ lật ra như quân bài bị
    // gạt đi chứ không xoay quanh chính giữa.
    const pivot = Alignment(0, 1.4);

    Offset slide;
    double turns;
    double scale;
    double opacity;

    if (index < current) {
      slide = const Offset(-1.3, 0);
      turns = -14 / 360;
      scale = 1;
      opacity = 0;
    } else if (index > current) {
      slide = Offset(0, 14.h / cardHeight);
      turns = 0;
      scale = 0.93;
      opacity = index == current + 1 ? 1 : 0;
    } else {
      slide = Offset(cardWidth == 0 ? 0 : _dragDx / cardWidth, 0);
      turns = _dragDx * _tiltPerPixel / 360;
      scale = 1;
      opacity = 1;
    }

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: index != current,
        child: AnimatedOpacity(
          duration: _isDragging && index == current ? Duration.zero : const Duration(milliseconds: 300),
          opacity: opacity,
          child: AnimatedSlide(
            duration: duration,
            curve: curve,
            offset: slide,
            child: AnimatedRotation(
              duration: duration,
              curve: curve,
              alignment: pivot,
              turns: turns,
              child: AnimatedScale(
                duration: duration,
                curve: curve,
                alignment: pivot,
                scale: scale,
                child: OnboardV2CoursePickerCard(course: widget.courses[index]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
