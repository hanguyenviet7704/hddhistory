part of '../../../exercise.dart';

class TapAndJumpScreen extends StatefulWidget {
  const TapAndJumpScreen({super.key});

  @override
  State<TapAndJumpScreen> createState() => _TapAndJumpScreenState();
}

class _TapAndJumpScreenState extends State<TapAndJumpScreen> {
  final List<String> _availableWords = ['short moment', 'silence', 'speaking'];
  final List<String?> _placedWords = [null, null, null];
  final List<String> _correctAnswers = ['short moment', 'silence', 'speaking'];

  final Map<int, GlobalKey> _wordKeys = {0: GlobalKey(), 1: GlobalKey(), 2: GlobalKey()};
  final GlobalKey _answerAreaKey = GlobalKey();

  OverlayEntry? _animatingOverlay;
  bool _isAnimating = false;

  bool get _isAllFilled => !_placedWords.contains(null);

  @override
  void dispose() {
    _animatingOverlay?.remove();
    super.dispose();
  }

  void _onWordTap(String word, GlobalKey cardKey) async {
    if (_isAnimating) return;

    final firstEmptySlot = _placedWords.indexWhere((w) => w == null);
    if (firstEmptySlot == -1) return;

    final startPosition = _getCardPosition(cardKey);

    setState(() {
      _isAnimating = true;
      _availableWords.remove(word);
    });

    await _animateWordToSlot(word, firstEmptySlot, startPosition);

    if (mounted) {
      setState(() {
        _placedWords[firstEmptySlot] = word;
        _isAnimating = false;
      });
    }
  }

  void _onSlotTap(int index) async {
    if (_isAnimating) return;
    final word = _placedWords[index];
    if (word == null) return;

    setState(() {
      _isAnimating = true;
      _placedWords[index] = null;
    });

    await _animateWordFromSlot(word, index);

    if (mounted) {
      setState(() {
        _availableWords.add(word);
        _isAnimating = false;
      });
    }
  }

  Future<void> _animateWordToSlot(String word, int slotIndex, Offset startPosition) async {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _AnimatedWordOverlay(
        word: word,
        startPosition: startPosition,
        endPosition: _getSlotPosition(slotIndex),
        onComplete: () {
          _animatingOverlay?.remove();
          _animatingOverlay = null;
        },
      ),
    );

    _animatingOverlay = overlayEntry;
    overlay.insert(overlayEntry);

    await Future.delayed(450.ms);
  }

  Future<void> _animateWordFromSlot(String word, int slotIndex) async {
    final overlay = Overlay.of(context);
    final endPosition = _getAnswerAreaPosition();

    final overlayEntry = OverlayEntry(
      builder: (context) => _AnimatedWordOverlay(
        word: word,
        startPosition: _getSlotPosition(slotIndex),
        endPosition: endPosition,
        onComplete: () {
          _animatingOverlay?.remove();
          _animatingOverlay = null;
        },
      ),
    );

    _animatingOverlay = overlayEntry;
    overlay.insert(overlayEntry);

    await Future.delayed(450.ms);
  }

  Offset _getSlotPosition(int index) {
    final key = _wordKeys[index];
    if (key?.currentContext == null) {
      return Offset(MediaQuery.of(context).size.width / 2, 300);
    }

    final RenderBox renderBox = key!.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    return Offset(position.dx, position.dy);
  }

  Offset _getCardPosition(GlobalKey cardKey) {
    if (cardKey.currentContext == null) {
      return Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height - 150);
    }

    final RenderBox renderBox = cardKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    return Offset(position.dx, position.dy);
  }

  Offset _getAnswerAreaPosition() {
    if (_answerAreaKey.currentContext == null) {
      return Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height - 150);
    }

    final RenderBox renderBox = _answerAreaKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    return Offset(position.dx + size.width / 2 - 50, position.dy + size.height / 2);
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
                    TapSentenceBuilder(placedWords: _placedWords, onSlotTap: _onSlotTap, wordKeys: _wordKeys),
                    const SizedBox(height: 12),
                    _buildHintText(),
                    const SizedBox(height: 12),
                    TapAnswerCardsArea(key: _answerAreaKey, availableWords: _availableWords, onWordTap: _onWordTap),
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
            'Tap words to fill the blanks',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF7F8EA4).withValues(alpha: 0.6), height: 1.5),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app, size: 14, color: const Color(0xFF7F8EA4).withValues(alpha: 0.4)),
              const SizedBox(width: 4),
              Text(
                'Tap to add • Tap again to remove',
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

class _AnimatedWordOverlay extends StatefulWidget {
  final String word;
  final Offset startPosition;
  final Offset endPosition;
  final VoidCallback? onComplete;

  const _AnimatedWordOverlay({required this.word, required this.startPosition, required this.endPosition, this.onComplete});

  @override
  State<_AnimatedWordOverlay> createState() => _AnimatedWordOverlayState();
}

class _AnimatedWordOverlayState extends State<_AnimatedWordOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: 400.ms, vsync: this);

    _positionAnimation = Tween<Offset>(begin: widget.startPosition, end: widget.endPosition).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(_controller);

    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _positionAnimation.value.dx,
          top: _positionAnimation.value.dy,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF554FF0).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF554FF0), width: 2),
                boxShadow: [BoxShadow(color: const Color(0xFF554FF0).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Text(
                widget.word,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF554FF0), height: 1.5),
              ),
            ),
          ),
        );
      },
    );
  }
}
