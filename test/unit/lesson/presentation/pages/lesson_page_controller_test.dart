import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  testWidgets('retries auto-scroll when the last item is mounted on a later frame', (tester) async {
    final visibilityChanges = <bool>[];
    final controller = LessonPageController(
      onBottomButtonVisibilityChanged: visibilityChanges.add,
      onClearSuppressNextAutoScroll: () {},
      isMounted: () => true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 320,
            child: _DeferredLastItemHarness(controller: controller),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(controller.scrollController.offset, greaterThan(400));
    expect(visibilityChanges, contains(false));

    controller.dispose();
  });

  testWidgets('auto-scroll reaches a lazily built last item that starts offscreen', (tester) async {
    final controller = LessonPageController(
      onBottomButtonVisibilityChanged: (_) {},
      onClearSuppressNextAutoScroll: () {},
      isMounted: () => true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 320,
            child: _LazyLastItemHarness(controller: controller),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lazy-last-item')), findsOneWidget);
    expect(controller.scrollController.offset, greaterThan(2000));

    controller.dispose();
  });
}

class _DeferredLastItemHarness extends StatefulWidget {
  const _DeferredLastItemHarness({
    required this.controller,
  });

  final LessonPageController controller;

  @override
  State<_DeferredLastItemHarness> createState() => _DeferredLastItemHarnessState();
}

class _DeferredLastItemHarnessState extends State<_DeferredLastItemHarness> {
  bool _showLastItem = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _showLastItem = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    widget.controller.handleAutoScroll(
      itemCount: 2,
      shouldSuppressAutoScroll: false,
    );

    return ListView(
      controller: widget.controller.scrollController,
      children: [
        const SizedBox(height: 500, child: ColoredBox(color: Colors.red)),
        if (_showLastItem)
          KeyedSubtree(
            key: widget.controller.lastItemKey,
            child: const SizedBox(
              key: Key('last-item'),
              height: 320,
              child: ColoredBox(color: Colors.blue),
            ),
          ),
      ],
    );
  }
}

class _LazyLastItemHarness extends StatelessWidget {
  const _LazyLastItemHarness({
    required this.controller,
  });

  final LessonPageController controller;

  @override
  Widget build(BuildContext context) {
    controller.handleAutoScroll(
      itemCount: 12,
      shouldSuppressAutoScroll: false,
    );

    return ListView.builder(
      controller: controller.scrollController,
      itemCount: 12,
      itemBuilder: (context, index) {
        if (index == 11) {
          return KeyedSubtree(
            key: controller.lastItemKey,
            child: const SizedBox(
              key: Key('lazy-last-item'),
              height: 320,
              child: ColoredBox(color: Colors.green),
            ),
          );
        }

        return const SizedBox(
          height: 260,
          child: ColoredBox(color: Colors.orange),
        );
      },
    );
  }
}
