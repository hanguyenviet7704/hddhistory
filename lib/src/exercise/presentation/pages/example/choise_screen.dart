part of '../../../exercise.dart';

class ChoiseScreen extends StatefulWidget {
  final int? initialQuestionIndex;

  const ChoiseScreen({super.key, this.initialQuestionIndex});

  @override
  State<ChoiseScreen> createState() => _ChoiseScreenState();
}

class _ChoiseScreenState extends State<ChoiseScreen> {
  late int currentQuestionIndex;
  late ChoiceQuestion currentQuestion;

  Set<int> selectedAnswers = {};
  bool hasChecked = false;
  ResultType? resultType;

  @override
  void initState() {
    super.initState();
    currentQuestionIndex = widget.initialQuestionIndex ?? 0;
    _loadQuestion();
  }

  void _loadQuestion() {
    currentQuestion = mockChoiceQuestions[currentQuestionIndex];
  }

  void _toggleAnswer(int index) {
    if (hasChecked) return;

    setState(() {
      if (currentQuestion.isMultiChoice) {
        if (selectedAnswers.contains(index)) {
          selectedAnswers.remove(index);
        } else {
          selectedAnswers.add(index);
        }
      } else {
        selectedAnswers = {index};
      }
    });
  }

  void _checkAnswers() {
    setState(() {
      hasChecked = true;
      if (currentQuestion.isMultiChoice) {
        final correctSet = currentQuestion.correctAnswersIndices ?? {};
        if (selectedAnswers.length == correctSet.length && selectedAnswers.every((index) => correctSet.contains(index))) {
          resultType = ResultType.correct;
        } else {
          resultType = ResultType.incorrect;
        }
      } else {
        if (selectedAnswers.isNotEmpty && selectedAnswers.first == currentQuestion.correctAnswerIndex) {
          resultType = ResultType.correct;
        } else {
          resultType = ResultType.incorrect;
        }
      }
    });
  }

  void _continue() {
    Navigator.of(context).pop();
  }

  AnswerState _getAnswerState(int index) {
    if (!hasChecked) {
      return selectedAnswers.contains(index) ? AnswerState.selected : AnswerState.normal;
    }

    if (currentQuestion.isMultiChoice) {
      final correctSet = currentQuestion.correctAnswersIndices ?? {};
      if (correctSet.contains(index)) {
        return selectedAnswers.contains(index) ? AnswerState.correct : AnswerState.disabled;
      } else if (selectedAnswers.contains(index)) {
        return AnswerState.incorrect;
      } else {
        return AnswerState.disabled;
      }
    } else {
      if (index == currentQuestion.correctAnswerIndex) {
        return AnswerState.correct;
      } else if (selectedAnswers.contains(index)) {
        return AnswerState.incorrect;
      } else {
        return AnswerState.disabled;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCheck = selectedAnswers.isNotEmpty && !hasChecked;

    return Scaffold(
      backgroundColor: Colors.white,
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
                    QuestionBubble(question: currentQuestion.question),
                    const SizedBox(height: 12),
                    if (currentQuestion.hasImage && currentQuestion.imageUrl != null) ...[
                      ImageCard(imageUrl: currentQuestion.imageUrl),
                      const SizedBox(height: 12),
                    ],
                    if (currentQuestion.hasAudio) ...[AudioPlayerWidget(audioUrl: currentQuestion.audioUrl), const SizedBox(height: 12)],
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(
                        currentQuestion.instructionText,
                        style: const TextStyle(color: Color(0xFF7F8EA4), fontSize: 12, fontWeight: FontWeight.w500, height: 1.5),
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: currentQuestion.answers.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return ChoiceAnswerCard(
                          text: currentQuestion.answers[index],
                          isMultiChoice: currentQuestion.isMultiChoice,
                          state: _getAnswerState(index),
                          onTap: () => _toggleAnswer(index),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            if (!hasChecked) BottomButton(isEnabled: canCheck, onPressed: canCheck ? _checkAnswers : null, text: 'Check'),
            if (hasChecked && resultType != null) ResultBottomSheet(type: resultType!, onContinue: _continue, onExplain: () {}),
          ],
        ),
      ),
    );
  }
}
