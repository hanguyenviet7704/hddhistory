part of '../../video_lesson.dart';

class _VideoLessonFormattedNotePreview extends StatelessWidget {
  const _VideoLessonFormattedNotePreview({
    required this.note,
  });

  final UserVideoLessonNoteEntity note;

  @override
  Widget build(BuildContext context) {
    final lines = _buildVideoLessonNotePreviewLines(note.content);
    if (lines.isEmpty) {
      return AppText(
        note.plainTextPreview,
        maxLines: 6,
        style: AppStyle.text16.copyWith(
          color: AppCustomColor.textPrimary,
          height: 1.55,
        ),
      );
    }

    final previewLines = lines.take(6).toList();
    final previewChildren = <Widget>[];
    var orderedIndex = 0;
    var previousListType = '';
    for (final line in previewLines) {
      if (line.listType == quill.Attribute.ol.value) {
        orderedIndex = previousListType == quill.Attribute.ol.value ? orderedIndex + 1 : 1;
      } else {
        orderedIndex = 0;
      }
      previewChildren.add(
        _VideoLessonFormattedNotePreviewLine(
          line: line,
          orderedIndex: orderedIndex,
        ),
      );
      previousListType = line.listType;
      if (line != previewLines.last) {
        previewChildren.add(4.verticalSpace);
      }
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 148.h),
      child: ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: previewChildren,
        ),
      ),
    );
  }
}

class _VideoLessonFormattedNotePreviewLine extends StatelessWidget {
  const _VideoLessonFormattedNotePreviewLine({
    required this.line,
    required this.orderedIndex,
  });

  final _VideoLessonNotePreviewLine line;
  final int orderedIndex;

  @override
  Widget build(BuildContext context) {
    final content = RichText(
      text: TextSpan(
        children: [
          if (line.segments.isEmpty)
            TextSpan(
              text: ' ',
              style: AppStyle.text16.copyWith(
                color: AppCustomColor.textPrimary,
                height: 1.55,
              ),
            )
          else
            for (final segment in line.segments)
              TextSpan(
                text: segment.text,
                style: AppStyle.text16.copyWith(
                  color: AppCustomColor.textPrimary,
                  height: 1.55,
                  fontWeight: segment.bold ? FontWeight.w700 : FontWeight.w400,
                  fontStyle: segment.italic ? FontStyle.italic : FontStyle.normal,
                ),
              ),
        ],
      ),
    );

    if (line.listType == quill.Attribute.ul.value) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 9.h, right: 8.w),
            child: Container(
              width: 4.r,
              height: 4.r,
              decoration: const BoxDecoration(
                color: AppCustomColor.textPrimary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(child: content),
        ],
      );
    }

    if (line.listType == quill.Attribute.ol.value) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18.w,
            child: AppText(
              '$orderedIndex.',
              style: AppStyle.text16.copyWith(
                color: AppCustomColor.textPrimary,
                height: 1.55,
              ),
            ),
          ),
          6.horizontalSpace,
          Expanded(child: content),
        ],
      );
    }

    return content;
  }
}

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

List<_VideoLessonNotePreviewLine> _buildVideoLessonNotePreviewLines(String rawContent) {
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
