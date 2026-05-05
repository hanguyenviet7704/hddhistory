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

  testWidgets('P5 map uses symmetric Figma node frames', (tester) async {
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

    Rect nodeRect(SkillsetOnboardingIntroduce introduce) {
      return tester.getRect(find.byKey(ValueKey('onboard_v2_skillset_map_node_${introduce.name}')));
    }

    final learn = nodeRect(SkillsetOnboardingIntroduce.whatILearnFades);
    final think = nodeRect(SkillsetOnboardingIntroduce.myThoughtsCircle);
    final feel = nodeRect(SkillsetOnboardingIntroduce.myFeelingsFeelLoud);
    final explore = nodeRect(SkillsetOnboardingIntroduce.nothingFeelsNew);
    final connect = nodeRect(SkillsetOnboardingIntroduce.iTalkToMany);
    final work = nodeRect(SkillsetOnboardingIntroduce.imBusyAllDay);
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
