part of '../../../video_lesson.dart';

class _VideoLessonNotePreviewLine {
  const _VideoLessonNotePreviewLine({
    required this.segments,
    required this.listType,
  });

  final List<_VideoLessonNotePreviewSegment> segments;
  final String listType;
}

class _VideoLessonNotePreviewSegment {
  const _VideoLessonNotePreviewSegment({
    required this.text,
    required this.bold,
    required this.italic,
  });

  final String text;
  final bool bold;
  final bool italic;
}

_VideoLessonNotePreviewLine _appendEllipsisToPreviewLine(
  _VideoLessonNotePreviewLine line,
) {
  if (line.segments.isEmpty) {
    return _VideoLessonNotePreviewLine(
      segments: const [
        _VideoLessonNotePreviewSegment(
          text: '…',
          bold: false,
          italic: false,
        ),
      ],
      listType: line.listType,
    );
  }

  final segments = List<_VideoLessonNotePreviewSegment>.from(line.segments);
  final lastSegment = segments.removeLast();
  segments.add(
    _VideoLessonNotePreviewSegment(
      text: '${lastSegment.text.trimRight()}…',
      bold: lastSegment.bold,
      italic: lastSegment.italic,
    ),
  );
  return _VideoLessonNotePreviewLine(
    segments: segments,
    listType: line.listType,
  );
}

List<_VideoLessonNotePreviewLine> _buildVideoLessonNotePreviewLines(
  String rawContent,
) {
  final deltaJson = videoLessonNoteDocumentFromContent(rawContent).toDelta().toJson();
  final lines = <_VideoLessonNotePreviewLine>[];
  final currentSegments = <_VideoLessonNotePreviewSegment>[];

  for (final operation in deltaJson) {
    final insert = operation['insert'];
    if (insert is! String) continue;

    final attributes = (operation['attributes'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final isBold = attributes[quill.Attribute.bold.key] == true;
    final isItalic = attributes[quill.Attribute.italic.key] == true;
    final listType = (attributes[quill.Attribute.list.key] as String?) ?? '';

    var currentIndex = 0;
    while (currentIndex < insert.length) {
      final nextLineBreakIndex = insert.indexOf('\n', currentIndex);
      if (nextLineBreakIndex == -1) {
        final text = insert.substring(currentIndex);
        if (text.isNotEmpty) {
          currentSegments.add(
            _VideoLessonNotePreviewSegment(
              text: text,
              bold: isBold,
              italic: isItalic,
            ),
          );
        }
        break;
      }

      final text = insert.substring(currentIndex, nextLineBreakIndex);
      if (text.isNotEmpty) {
        currentSegments.add(
          _VideoLessonNotePreviewSegment(
            text: text,
            bold: isBold,
            italic: isItalic,
          ),
        );
      }
      lines.add(
        _VideoLessonNotePreviewLine(
          segments: List<_VideoLessonNotePreviewSegment>.from(currentSegments),
          listType: listType,
        ),
      );
      currentSegments.clear();
      currentIndex = nextLineBreakIndex + 1;
    }
  }

  return lines.where((line) => line.segments.isNotEmpty || line.listType.isNotEmpty).toList();
}
