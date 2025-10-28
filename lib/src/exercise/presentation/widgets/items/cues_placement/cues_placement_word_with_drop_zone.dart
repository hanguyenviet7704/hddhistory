part of '../../../../exercise.dart';

/// A word with a drop zone after it for placing pause marks
/// Follows exact Figma styling from example implementation
class CuesPlacementWordWithDropZone extends StatelessWidget {
  final String word;
  final int wordIndex;
  final OptionEntity? placedMark; // The pause mark placed after this word
  final AnswerState? markState;
  final Function(int wordIndex, PauseMarkDragData data) onAcceptMark;
  final Function(int wordIndex) onRemoveMark;
  final bool hasChecked;

  const CuesPlacementWordWithDropZone({
    super.key,
    required this.word,
    required this.wordIndex,
    this.placedMark,
    this.markState,
    required this.onAcceptMark,
    required this.onRemoveMark,
    this.hasChecked = false,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<PauseMarkDragData>(
      onAcceptWithDetails: (details) {
        onAcceptMark(wordIndex, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final bool isHovering = candidateData.isNotEmpty;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Word card with hover styling
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: isHovering ? const Color(0xFF554FF0) : const Color(0xFFE3E8EF),
                  width: isHovering ? 3.w : 2.w,
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: AppText(
                word,
                style: AppStyle.text14.copyWith(
                  color: const Color(0xFF364152),
                  height: 1.75,
                ),
              ),
            ),
            // Show either: placed mark, hover indicator, or nothing
            if (placedMark != null) ...[
              // Show placed mark
              2.horizontalSpace,
              GestureDetector(
                onTap: hasChecked
                    ? null
                    : () {
                        onRemoveMark(wordIndex);
                      },
                child: CuesPlacementPauseMark(
                  option: placedMark!,
                  fromWordIndex: wordIndex,
                  state: markState,
                ),
              ),
            ] else if (isHovering && !hasChecked) ...[
              // Show hover indicator while dragging
              Container(
                width: 40.w,
                height: 37.h,
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF554FF0).op(0.1),
                  border: Border.all(
                    color: const Color(0xFF554FF0),
                    width: 2.w,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: const Center(
                  child: CuesPlacementPauseMarkIcon(filled: true),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
