import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  const builder = LessonTimelineBuilder();

  group('LessonTimelineBuilder.collectLessonItems', () {
    test('builds completed theory items then active exercise body', () {
      final theoryItem = LearningItemEntity(
        id: 'theory-1',
        type: LearningItemType.theory,
        documents: const [
          DocumentEntity(id: 1),
          DocumentEntity(id: 2),
        ],
      );
      final exerciseItem = LearningItemEntity(
        id: 'exercise-1',
        type: LearningItemType.exercise,
        mainQuestions: const [
          QuestionEntity(id: 11),
          QuestionEntity(id: 12),
        ],
      );

      final state = LessonState(
        pageData: BasePageBreak<LearningItemEntity>(
          items: [theoryItem, exerciseItem],
        ),
        currentLearningItemIndex: 1,
        currentLessonIndex: 0,
      );

      const activeBody = SizedBox(key: Key('active'));
      final reviewQuestions = <int>[];

      final items = builder.collectLessonItems(
        state: state,
        activeBody: activeBody,
        buildReviewBody: (question) {
          reviewQuestions.add(question.id);
          return Text('review-${question.id}');
        },
      );

      expect(items.length, 3);
      expect(items[0], isA<DocumentWidget>());
      expect(items[1], isA<DocumentWidget>());
      expect(items[2], isA<LessonActiveTimelineItem>());
      expect(reviewQuestions, isEmpty);
    });

    test('uses review builder for prior exercise questions and active body for current', () {
      final exerciseItem = LearningItemEntity(
        id: 'exercise-2',
        type: LearningItemType.exercise,
        mainQuestions: const [
          QuestionEntity(id: 21),
          QuestionEntity(id: 22),
          QuestionEntity(id: 23),
        ],
      );

      final state = LessonState(
        pageData: BasePageBreak<LearningItemEntity>(
          items: [exerciseItem],
        ),
        currentLearningItemIndex: 0,
        currentLessonIndex: 2,
      );

      const activeBody = SizedBox(key: Key('active-question'));
      final reviewQuestions = <int>[];

      final items = builder.collectLessonItems(
        state: state,
        activeBody: activeBody,
        buildReviewBody: (question) {
          reviewQuestions.add(question.id);
          return Text('review-${question.id}');
        },
      );

      expect(items.length, 3);
      expect(items[0], isA<Text>());
      expect(items[1], isA<Text>());
      expect(items[2], isA<LessonActiveTimelineItem>());
      expect(reviewQuestions, [21, 22]);
    });

    testWidgets('keeps active body mounted after it scrolls offscreen', (tester) async {
      final controller = ScrollController();
      var disposeCount = 0;

      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              home: SizedBox(
                height: 360,
                child: ListView.builder(
                  controller: controller,
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    if (index == 7) {
                      return LessonActiveTimelineItem(
                        child: _DisposableProbe(
                          key: const Key('active-probe'),
                          onDispose: () => disposeCount++,
                        ),
                      );
                    }

                    return SizedBox(
                      height: 260,
                      child: Text('review-$index'),
                    );
                  },
                ),
              ),
            );
          },
        ),
      );

      for (var i = 0; i < 8 && find.byKey(const Key('active-probe')).evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -320));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('active-probe')), findsOneWidget);

      controller.jumpTo(0);
      await tester.pumpAndSettle();

      expect(disposeCount, 0);
    });
  });
}

class _DisposableProbe extends StatefulWidget {
  const _DisposableProbe({
    super.key,
    required this.onDispose,
  });

  final VoidCallback onDispose;

  @override
  State<_DisposableProbe> createState() => _DisposableProbeState();
}

class _DisposableProbeState extends State<_DisposableProbe> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 260, child: Text('active'));
  }
}
