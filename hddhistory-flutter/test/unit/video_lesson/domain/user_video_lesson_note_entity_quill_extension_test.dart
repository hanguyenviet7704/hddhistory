import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  test('falls back legacy plain text note content into a quill document', () {
    const rawContent = 'Line 1\nLine 2';
    final canonicalContent = videoLessonCanonicalizeNoteContent(rawContent);

    expect(videoLessonPlainTextFromNoteContent(rawContent), rawContent);
    expect(videoLessonNoteContentIsBlank(rawContent), isFalse);
    expect(videoLessonPlainTextFromNoteContent(canonicalContent), rawContent);
  });

  test('decodes encoded quill content into plain text preview', () {
    final document = quill.Document()..insert(0, 'Styled note');
    document.format(0, 'Styled note'.length, quill.Attribute.bold);
    final encodedContent = videoLessonEncodeNoteDocument(document);

    final note = UserVideoLessonNoteEntity(content: encodedContent);

    expect(videoLessonPlainTextFromNoteContent(encodedContent), 'Styled note');
    expect(note.plainTextPreview, 'Styled note');
  });

  test('treats empty quill documents as blank content', () {
    final encodedContent = videoLessonEncodeNoteDocument(quill.Document());

    expect(videoLessonNoteContentIsBlank(''), isTrue);
    expect(videoLessonNoteContentIsBlank(encodedContent), isTrue);
  });
}
