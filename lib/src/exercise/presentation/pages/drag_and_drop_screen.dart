part of '../../exercise.dart';

class DragAndDropScreen extends StatefulWidget {
  const DragAndDropScreen({super.key});

  @override
  State<DragAndDropScreen> createState() => _DragAndDropScreenState();
}

class _DragAndDropScreenState extends State<DragAndDropScreen> {
  final List<String> _availableWords = ['short moment', 'silence', 'speaking'];

  final List<String?> _placedWords = [null, null, null];

  final List<String> _correctAnswers = ['short moment', 'silence', 'speaking'];

  bool get _isAllFilled => !_placedWords.contains(null);

  void _onWordPlacedInSlot(int index, String word, int? fromIndex) {
    setState(() {
      if (fromIndex != null) {
        _placedWords[fromIndex] = null;
      } else {
        _availableWords.remove(word);
      }

      _placedWords[index] = word;
    });
  }

  void _onWordReturnedFromSlot(String word, int fromIndex) {
    setState(() {
      _placedWords[fromIndex] = null;
      if (!_availableWords.contains(word)) {
        _availableWords.add(word);
      }
    });
  }

  void _onDragCancelled(String word, int index) {
    setState(() {
      if (_placedWords[index] == null) {
        _placedWords[index] = word;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            DragDropHeader(progress: 0.3, onClose: () => Navigator.of(context).pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PracticeTag(),
                    const SizedBox(height: 12),
                    const QuestionBubble(question: 'What is pause?'),
                    const SizedBox(height: 12),
                    SentenceBuilder(
                      placedWords: _placedWords,
                      onWordPlaced: _onWordPlacedInSlot,
                      onWordRemoved: (word, fromIndex) {},
                      onDragCancelled: _onDragCancelled,
                    ),
                    const SizedBox(height: 12),
                    _buildHintText(),
                    const SizedBox(height: 12),
                    AnswerCardsArea(availableWords: _availableWords, onWordReturnedFromSlot: _onWordReturnedFromSlot),
                  ],
                ),
              ),
            ),
            BottomButton(isEnabled: _isAllFilled, onPressed: _checkAnswers),
          ],
        ),
      ),
    );
  }

  Widget _buildHintText() {
    return Center(
      child: Column(
        children: [
          Text(
            'Long press and drag words to fill the blanks',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF7F8EA4).withValues(alpha: 0.6), height: 1.5),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app, size: 14, color: const Color(0xFF7F8EA4).withValues(alpha: 0.4)),
              const SizedBox(width: 4),
              Text(
                'Hold to drag • Drag back to remove',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: const Color(0xFF7F8EA4).withValues(alpha: 0.4), height: 1.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _checkAnswers() {
    bool allCorrect = true;
    for (int i = 0; i < _placedWords.length; i++) {
      if (_placedWords[i] != _correctAnswers[i]) {
        allCorrect = false;
        break;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: allCorrect ? const Color(0xFFEAFFEF) : const Color(0xFFFDEAE7),
        title: Row(
          children: [
            Icon(allCorrect ? Icons.check_circle : Icons.cancel, color: allCorrect ? const Color(0xFF1DA75E) : const Color(0xFFE34646), size: 24),
            const SizedBox(width: 8),
            Text(
              allCorrect ? 'Correct answer!' : 'Incorrect',
              style: TextStyle(color: allCorrect ? const Color(0xFF1DA75E) : const Color(0xFFE34646), fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (allCorrect) {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: allCorrect ? const Color(0xFF1DA75E) : const Color(0xFFE34646),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1000)),
              ),
              child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}
