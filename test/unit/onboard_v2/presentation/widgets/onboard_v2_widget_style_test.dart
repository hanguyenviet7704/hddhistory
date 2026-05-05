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

  testWidgets('P5 map renders skillset short titles', (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        const OnboardV2SkillsetMap(
          activeIntroduces: [
            SkillsetOnboardingIntroduce.myThoughtsCircle,
            SkillsetOnboardingIntroduce.whatILearnFades,
          ],
        ),
      ),
    );

    for (final introduce in SkillsetOnboardingIntroduce.values) {
      expect(find.text(introduce.shortTitle), findsOneWidget);
    }
    expect(find.text('What'), findsNothing);
    expect(find.text('My'), findsNothing);
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
