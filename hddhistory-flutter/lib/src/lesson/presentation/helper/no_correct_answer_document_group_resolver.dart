part of '../../lesson.dart';

class NoCorrectAnswerDocumentGroupResolved {
  final String groupId;
  final List<ContentDocumentEntity> documents;

  const NoCorrectAnswerDocumentGroupResolved({
    required this.groupId,
    required this.documents,
  });
}

NoCorrectAnswerDocumentGroupResolved? resolveNoCorrectAnswerDocumentGroup({
  required QuestionEntity question,
  required int selectedAnswerIndex,
}) {
  final payload = _noCorrectPayload(question);
  if (payload == null) return null;
  if (selectedAnswerIndex < 0 || selectedAnswerIndex >= payload.options.length) return null;

  final selectedOption = payload.options[selectedAnswerIndex];
  final documentGroupId = selectedOption.documentGroupId.trim();
  if (documentGroupId.isEmpty) return null;

  return resolveNoCorrectAnswerDocumentGroupById(
    question: question,
    groupId: documentGroupId,
  );
}

NoCorrectAnswerDocumentGroupResolved? resolveNoCorrectAnswerDocumentGroupById({
  required QuestionEntity question,
  required String groupId,
}) {
  final payload = _noCorrectPayload(question);
  if (payload == null) return null;

  final normalizedGroupId = groupId.trim();
  if (normalizedGroupId.isEmpty) return null;

  for (final group in payload.documentGroups) {
    if (group.id == normalizedGroupId) {
      return NoCorrectAnswerDocumentGroupResolved(
        groupId: group.id,
        documents: group.documents,
      );
    }
  }

  return null;
}

QuestionSingleChoiceNoCorrectAnswerPayloadEntity? _noCorrectPayload(QuestionEntity question) {
  final payload = question.typedPayload;
  if (payload is! QuestionSingleChoiceNoCorrectAnswerPayloadEntity) return null;
  return payload;
}
