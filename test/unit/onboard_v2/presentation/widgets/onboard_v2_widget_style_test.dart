import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  testWidgets('selected option row uses gradient border', (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        OnboardV2SelectableOptionRow(
          label: 'Option',
          selected: true,
          onTap: () {},
        ),
      ),
    );

    final selectedDecorations = tester.widgetList<Container>(
      find.byWidgetPredicate(
        (widget) {
          if (widget is! Container) return false;
          final decoration = widget.decoration;
          return decoration is BoxDecoration && decoration.border is GradientBoxBorder;
        },
      ),
    );

    expect(selectedDecorations, hasLength(1));
  });

  testWidgets('P6 map renders path short titles', (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        const OnboardV2PathMap(
          activePaths: [
            OnboardingPath.thinkBetter,
            OnboardingPath.learnBetter,
          ],
        ),
      ),
    );

    for (final path in OnboardingPath.values) {
      expect(find.text(path.shortTitle), findsOneWidget);
    }
    expect(find.text('What'), findsNothing);
    expect(find.text('My'), findsNothing);
  });

  testWidgets('P6 map uses symmetric Figma node frames', (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        const OnboardV2PathMap(
          activePaths: [
            OnboardingPath.thinkBetter,
            OnboardingPath.learnBetter,
          ],
        ),
      ),
    );

    Rect nodeRect(OnboardingPath path) {
      return tester.getRect(find.byKey(ValueKey('onboard_v2_path_map_node_${path.name}')));
    }

    final learn = nodeRect(OnboardingPath.learnBetter);
    final think = nodeRect(OnboardingPath.thinkBetter);
    final feel = nodeRect(OnboardingPath.feelBetter);
    final explore = nodeRect(OnboardingPath.exploreBetter);
    final connect = nodeRect(OnboardingPath.connectBetter);
    final work = nodeRect(OnboardingPath.workBetter);
    const figmaRoundingTolerance = 1.0;

    expect(learn.center.dx, closeTo(connect.center.dx, figmaRoundingTolerance));
    expect(feel.center.dx, closeTo(work.center.dx, figmaRoundingTolerance));
    expect(think.center.dx, closeTo(explore.center.dx, figmaRoundingTolerance));
    expect(feel.center.dy, closeTo(think.center.dy, figmaRoundingTolerance));
    expect(work.center.dy, closeTo(explore.center.dy, figmaRoundingTolerance));
    expect(learn.center.dx, closeTo((feel.center.dx + think.center.dx) / 2, figmaRoundingTolerance));
    expect(connect.center.dx, closeTo((work.center.dx + explore.center.dx) / 2, figmaRoundingTolerance));
  });
}

Widget _buildHarness(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, _) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
}
