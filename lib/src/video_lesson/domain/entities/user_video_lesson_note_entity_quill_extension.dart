part of '../../video_lesson.dart';

quill.Document videoLessonNoteDocumentFromContent(String rawContent) {
  final trimmedContent = rawContent.trim();
  if (trimmedContent.isEmpty) return quill.Document();

  try {
    final decoded = jsonDecode(rawContent);
    if (decoded is List) {
      return quill.Document.fromJson(decoded);
    }
  } catch (_) {
    // Fallback to the legacy plain-text note format.
  }

  final document = quill.Document();
  final plainText = rawContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n').replaceAll(RegExp(r'\n+$'), '');
  if (plainText.isEmpty) return document;
  document.insert(0, plainText);
  return document;
}

String videoLessonEncodeNoteDocument(quill.Document document) => jsonEncode(document.toDelta().toJson());

String videoLessonCanonicalizeNoteContent(String rawContent) => videoLessonEncodeNoteDocument(videoLessonNoteDocumentFromContent(rawContent));

String videoLessonPlainTextFromNoteContent(String rawContent) => videoLessonNoteDocumentFromContent(rawContent).toPlainText().trimRight();

bool videoLessonNoteContentIsBlank(String rawContent) => videoLessonPlainTextFromNoteContent(rawContent).trim().isEmpty;

extension UserVideoLessonNoteEntityQuillExtension on UserVideoLessonNoteEntity {
  quill.Document get quillDocument => videoLessonNoteDocumentFromContent(content);

  String get plainTextPreview => videoLessonPlainTextFromNoteContent(content);
}
