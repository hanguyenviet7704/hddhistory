part of '../../../exercise.dart';

class ChoiceQuestion {
  final String question;
  final List<String> answers;
  final String instructionText;
  final bool isMultiChoice;
  final bool hasImage;
  final bool hasAudio;
  final String? imageUrl;
  final String? audioUrl;
  final int? correctAnswerIndex;
  final Set<int>? correctAnswersIndices;

  const ChoiceQuestion({
    required this.question,
    required this.answers,
    this.instructionText = 'Select the best answer',
    this.isMultiChoice = false,
    this.hasImage = false,
    this.hasAudio = false,
    this.imageUrl,
    this.audioUrl,
    this.correctAnswerIndex,
    this.correctAnswersIndices,
  });
}

final List<ChoiceQuestion> mockChoiceQuestions = [
  ChoiceQuestion(
    question: 'What is pause?',
    answers: ['A temporary stop or break in action', 'A permanent end of an activity', 'Speeding up a process quickly', 'When something never starts at all'],
    hasImage: true,
    imageUrl: 'https://via.placeholder.com/335x183',
    correctAnswerIndex: 0,
  ),
  ChoiceQuestion(
    question: 'In which of the following situations should you use paraphrasing skills?',
    answers: [
      'When the speaker shows strong emotions (stress, frustration)',
      'Jumping in with your own opinion right away',
      'In a disagreement, to clarify the other person\'s meaning.',
      'When you want the speaker to share more details',
    ],
    instructionText: 'Select all that apply',
    isMultiChoice: true,
    hasAudio: true,
    audioUrl: 'https://example.com/audio.mp3',
    correctAnswersIndices: {0, 2, 3},
  ),
  ChoiceQuestion(question: 'Which color is the sky on a clear day?', answers: ['Blue', 'Red', 'Green', 'Yellow'], correctAnswerIndex: 0),
  ChoiceQuestion(
    question: 'What are the primary colors?',
    answers: ['Red', 'Blue', 'Green', 'Yellow'],
    instructionText: 'Select all that apply',
    isMultiChoice: true,
    correctAnswersIndices: {0, 1, 3},
  ),
];
