part of '../../../video_lesson.dart';

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

    final isTruncated = lines.length > 5;
    final previewLines = lines.take(5).toList();
    if (isTruncated && previewLines.isNotEmpty) {
      previewLines[previewLines.length - 1] = _appendEllipsisToPreviewLine(previewLines.last);
    }
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
      constraints: BoxConstraints(maxHeight: 136.h),
      child: ClipRect(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: previewChildren,
          ),
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
            padding: EdgeInsets.only(top: 10.h, right: 8.w),
            child: Container(
              width: 5.r,
              height: 5.r,
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
            width: 20.w,
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
