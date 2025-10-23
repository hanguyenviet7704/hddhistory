part of '../../../exercise.dart';

class CuesPlacementLessonBody extends StatefulWidget {
  final String sentence;
  final List<String> words;
  final int totalPauseMarks;
  final Function(int placedMarks) onAnswerChecked;

  const CuesPlacementLessonBody({
    super.key,
    required this.sentence,
    required this.words,
    required this.totalPauseMarks,
    required this.onAnswerChecked,
  });

  @override
  State<CuesPlacementLessonBody> createState() => _CuesPlacementLessonBodyState();
}

class _CuesPlacementLessonBodyState extends State<CuesPlacementLessonBody> {
  late List<String> _baseWords;
  List<dynamic> _wordsWithMarks = [];
  late int _availableMarks;
  late int _totalMarks;
  int? _hoveringWordIndex;

  @override
  void initState() {
    super.initState();
    _baseWords = List.from(widget.words);
    _wordsWithMarks = List.from(_baseWords);
    _totalMarks = widget.totalPauseMarks;
    _availableMarks = widget.totalPauseMarks;
  }

  void _addPauseMark(int afterIndex) {
    if (_availableMarks <= 0) return;

    setState(() {
      int insertIndex = afterIndex + 1;
      for (int i = 0; i < afterIndex; i++) {
        if (_wordsWithMarks[i] is Map && _wordsWithMarks[i]['type'] == 'pause') {
          insertIndex++;
        }
      }

      if (insertIndex <= _wordsWithMarks.length) {
        _wordsWithMarks.insert(insertIndex, {'type': 'pause', 'id': DateTime.now().millisecondsSinceEpoch});
        _availableMarks--;
      }
    });
  }

  void _removePauseMark(int index) {
    setState(() {
      _wordsWithMarks.removeAt(index);
      _availableMarks++;
    });
  }

  void _handleWordAccept(int index, Map<String, dynamic> data) {
    setState(() {
      _hoveringWordIndex = null;
    });

    if (data['action'] == 'place_new') {
      int baseWordIndex = 0;
      for (int i = 0; i <= index; i++) {
        if (_wordsWithMarks[i] is String) {
          baseWordIndex++;
        }
      }
      _addPauseMark(baseWordIndex - 1);
    } else if (data['action'] == 'move_existing') {
      int fromIndex = data['from_index'];
      setState(() {
        final pauseMark = _wordsWithMarks[fromIndex];
        _wordsWithMarks.removeAt(fromIndex);

        int targetIndex = index;
        if (fromIndex < index) {
          targetIndex--;
        }

        int insertIndex = targetIndex + 1;
        if (insertIndex <= _wordsWithMarks.length) {
          _wordsWithMarks.insert(insertIndex, pauseMark);
        }
      });
    }
  }

  void _handleWordHoverChange(int index) {
    if (_hoveringWordIndex != index) {
      setState(() {
        _hoveringWordIndex = index;
      });
    }
  }

  void _handleWordHoverExit() {
    setState(() {
      _hoveringWordIndex = null;
    });
  }

  void _handlePauseMarkDragEnd() {
    setState(() {
      _hoveringWordIndex = null;
    });
  }

  void _handleAvailableMarksAccept(Map<String, dynamic> data) {
    setState(() {
      _hoveringWordIndex = null;
    });
    if (data['action'] == 'move_existing') {
      int fromIndex = data['from_index'];
      _removePauseMark(fromIndex);
    }
  }

  void _handleAvailableMarksHover() {
    if (_hoveringWordIndex != null) {
      setState(() {
        _hoveringWordIndex = null;
      });
    }
  }

  void _showResultDialog() {
    final placedMarks = _totalMarks - _availableMarks;
    widget.onAnswerChecked(placedMarks);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause Marks Placed'),
        content: Text('You placed $placedMarks pause marks'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const CuesPracticeTag(),
          const SizedBox(height: 8),
          const InstructionBubble(instruction: 'Read the paraphrase below and decide which words should be stressed.'),
          const SizedBox(height: 12),
          TextBubble(text: widget.sentence),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Place the pause mark after the word',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF7F8EA4).op(0.6),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          WordGrid(
            wordsWithMarks: _wordsWithMarks,
            hoveringWordIndex: _hoveringWordIndex,
            onWordAccept: _handleWordAccept,
            onWordHoverChange: _handleWordHoverChange,
            onWordHoverExit: _handleWordHoverExit,
            onPauseMarkDragEnd: _handlePauseMarkDragEnd,
          ),
          const SizedBox(height: 20),
          AvailablePauseMarks(
            totalMarks: _totalMarks,
            availableMarks: _availableMarks,
            onAccept: _handleAvailableMarksAccept,
            onHover: _handleAvailableMarksHover,
            onDragEnd: _handlePauseMarkDragEnd,
          ),
          const SizedBox(height: 20),
          CuesBottomButton(
            text: 'Check',
            onTap: _showResultDialog,
          ),
        ],
      ),
    );
  }
}
