part of '../../exercise.dart';

class ArrangeTheSequenceScreen extends StatefulWidget {
  const ArrangeTheSequenceScreen({super.key});

  @override
  State<ArrangeTheSequenceScreen> createState() => _ArrangeTheSequenceScreenState();
}

class _ArrangeTheSequenceScreenState extends State<ArrangeTheSequenceScreen> {
  List<String> answers = [
    'A temporary stop or break in action 1',
    'A temporary stop or break in action 2',
    'A temporary stop or break in action 3',
    'A temporary stop or break in action 4',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            ArrangeHeader(progress: 0.3, onClose: () => Navigator.of(context).pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const PracticeTag(),
                    const SizedBox(height: 12),
                    const QuestionBubble(question: 'What is pause?'),
                    const SizedBox(height: 12),
                    const ImageCard(),
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Arrange the sequence',
                        style: TextStyle(color: Color(0xFF7F8EA4), fontSize: 14, fontWeight: FontWeight.w500, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      // dragStartBehavior: DragStartBehavior.down,
                      itemCount: answers.length,
                      proxyDecorator: (child, index, animation) {
                        // return Material(
                        //   color: Colors.transparent,
                        //   child: Container(
                        //     decoration: BoxDecoration(
                        //       color: Colors.white,
                        //       border: Border.all(color: const Color(0xFFE3E8EF), width: 2),
                        //       borderRadius: BorderRadius.circular(12),
                        //       boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
                        //     ),
                        //     child: child,
                        //   ),
                        // );
                        return child;
                      },
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final item = answers.removeAt(oldIndex);
                          answers.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        return Padding(
                          key: Key('$index'),
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SequenceAnswerCard(text: answers[index], index: index),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            BottomButton(isEnabled: true, onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
