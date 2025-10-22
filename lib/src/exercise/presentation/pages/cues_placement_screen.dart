part of '../../exercise.dart';

class CuesPlacementScreen extends StatefulWidget {
  const CuesPlacementScreen({super.key});

  @override
  State<CuesPlacementScreen> createState() => _CuesPlacementScreenState();
}

class _CuesPlacementScreenState extends State<CuesPlacementScreen> {
  final List<String> baseWords = [
    "I'm",
    "really",
    "anxious",
    "about",
    "the",
    "job",
    "interview",
    "tomorrow",
    "because",
    "it",
    "feels",
    "like",
    "such",
    "an",
    "important",
    "opportunity.",
  ];

  List<dynamic> wordsWithMarks = [];
  int availableMarks = 3;
  int totalMarks = 3;
  int? hoveringWordIndex;

  @override
  void initState() {
    super.initState();
    wordsWithMarks = List.from(baseWords);
  }

  void _addPauseMark(int afterIndex) {
    if (availableMarks <= 0) return;

    setState(() {
      int insertIndex = afterIndex + 1;
      for (int i = 0; i < afterIndex; i++) {
        if (wordsWithMarks[i] is Map && wordsWithMarks[i]['type'] == 'pause') {
          insertIndex++;
        }
      }

      if (insertIndex <= wordsWithMarks.length) {
        wordsWithMarks.insert(insertIndex, {'type': 'pause', 'id': DateTime.now().millisecondsSinceEpoch});
        availableMarks--;
      }
    });
  }

  void _removePauseMark(int index) {
    setState(() {
      wordsWithMarks.removeAt(index);
      availableMarks++;
    });
  }

  void _handleWordAccept(int index, Map<String, dynamic> data) {
    setState(() {
      hoveringWordIndex = null;
    });

    if (data['action'] == 'place_new') {
      int baseWordIndex = 0;
      for (int i = 0; i <= index; i++) {
        if (wordsWithMarks[i] is String) {
          baseWordIndex++;
        }
      }
      _addPauseMark(baseWordIndex - 1);
    } else if (data['action'] == 'move_existing') {
      int fromIndex = data['from_index'];
      setState(() {
        final pauseMark = wordsWithMarks[fromIndex];
        wordsWithMarks.removeAt(fromIndex);

        int targetIndex = index;
        if (fromIndex < index) {
          targetIndex--;
        }

        int insertIndex = targetIndex + 1;
        if (insertIndex <= wordsWithMarks.length) {
          wordsWithMarks.insert(insertIndex, pauseMark);
        }
      });
    }
  }

  void _handleWordHoverChange(int index) {
    if (hoveringWordIndex != index) {
      setState(() {
        hoveringWordIndex = index;
      });
    }
  }

  void _handleWordHoverExit() {
    setState(() {
      hoveringWordIndex = null;
    });
  }

  void _handlePauseMarkDragEnd() {
    setState(() {
      hoveringWordIndex = null;
    });
  }

  void _handleAvailableMarksAccept(Map<String, dynamic> data) {
    setState(() {
      hoveringWordIndex = null;
    });
    if (data['action'] == 'move_existing') {
      int fromIndex = data['from_index'];
      _removePauseMark(fromIndex);
    }
  }

  void _handleAvailableMarksHover() {
    if (hoveringWordIndex != null) {
      setState(() {
        hoveringWordIndex = null;
      });
    }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause Marks Placed'),
        content: Text('You placed ${totalMarks - availableMarks} pause marks'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CuesStatusBar(),
            CuesProgressBar(onClose: () => Navigator.of(context).pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    const PracticeTag(),
                    const SizedBox(height: 8),
                    const InstructionBubble(instruction: 'Read the paraphrase below and decide which words should be stressed.'),
                    const SizedBox(height: 12),
                    const TextBubble(text: 'I\'m really anxious about the job interview tomorrow because it feels like such an important opportunity.'),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Place the pause mark after the word',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF7F8EA4).op(0.6), height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    WordGrid(
                      wordsWithMarks: wordsWithMarks,
                      hoveringWordIndex: hoveringWordIndex,
                      onWordAccept: _handleWordAccept,
                      onWordHoverChange: _handleWordHoverChange,
                      onWordHoverExit: _handleWordHoverExit,
                      onPauseMarkDragEnd: _handlePauseMarkDragEnd,
                    ),
                    const SizedBox(height: 20),
                    AvailablePauseMarks(
                      totalMarks: totalMarks,
                      availableMarks: availableMarks,
                      onAccept: _handleAvailableMarksAccept,
                      onHover: _handleAvailableMarksHover,
                      onDragEnd: _handlePauseMarkDragEnd,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            CuesBottomButton(text: 'Check', onTap: _showResultDialog),
            const HomeIndicator(),
          ],
        ),
      ),
    );
  }
}
