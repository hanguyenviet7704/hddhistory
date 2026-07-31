import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

/// The keypoint deck's viewportFraction (see `_peekViewportFraction`).
const _fraction = 0.937;

void main() {
  group('keypointDeckPage', () {
    testWidgets('reports the jump target while the deck is still laying out its reveal', (tester) async {
      // The listen-mode resume path in one frame: KeypointCardCubit reveals
      // cards narration read ahead to (itemCount grows) and viewCard() makes
      // the shell jumpToPage() past the OLD last card — the jump lands before
      // the extended PageView has laid out, so the position's extents still
      // describe the old deck while the revealed cards first build.
      final controller = PageController(initialPage: 3, viewportFraction: _fraction);
      addTearDown(controller.dispose);

      var itemCount = 4;
      late StateSetter rebuildHost;
      final pagesSeenByCard6 = <double>[];

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuildHost = setState;
              return PageView.builder(
                controller: controller,
                scrollDirection: Axis.vertical,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (index == 6) {
                    pagesSeenByCard6.add(keypointDeckPage(controller, settledIndex: 6));
                  }
                  return Text('card $index');
                },
              );
            },
          ),
        ),
      );

      // Settled on the old live edge before backgrounding.
      expect(keypointDeckPage(controller, settledIndex: 3), 3.0);

      // Resume: the shell's Bloc listener jumps first, the rebuild with the
      // extended itemCount lands in the same frame.
      controller.jumpToPage(6);
      rebuildHost(() => itemCount = 7);
      await tester.pump();

      // The frame that first builds card 6 must already see it as the live
      // page — a clamped read reports the old last card (3), which dims the
      // on-screen card and, with nothing notifying after layout fixes the
      // extents, freezes it dimmed until the next drag.
      expect(pagesSeenByCard6, isNotEmpty);
      expect(pagesSeenByCard6.last, 6.0);
    });

    testWidgets('settles on exact integers after an in-range jump', (tester) async {
      // Guards the slot's `distance == 0` check: float dust from deriving the
      // page would wrap the live card in a near-1.0 Opacity, whose saveLayer
      // still defeats the frosted card's BackdropFilter.
      final controller = PageController(viewportFraction: _fraction);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: PageView.builder(
            controller: controller,
            scrollDirection: Axis.vertical,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) => Text('card $index'),
          ),
        ),
      );

      controller.jumpToPage(2);
      await tester.pump();

      expect(keypointDeckPage(controller, settledIndex: 2), 2.0);
    });
  });
}
