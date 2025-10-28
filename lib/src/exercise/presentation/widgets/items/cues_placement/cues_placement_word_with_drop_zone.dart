part of '../../../../exercise.dart';

/// A word with a drop zone after it for placing pause marks
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The word
        AppText(
          word,
          style: AppStyle.text16.copyWith(
            color: const Color(0xFF364152),
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        4.horizontalSpace,
        // Drop zone after the word
        if (!hasChecked || markState != null)
          DragTarget<PauseMarkDragData>(
            onAcceptWithDetails: (details) {
              onAcceptMark(wordIndex, details.data);
            },
            builder: (context, candidateData, rejectedData) {
              final bool isHovering = candidateData.isNotEmpty;

              // If there's already a mark here, show it
              if (placedMark != null) {
                return GestureDetector(
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
                );
              }

              // Otherwise show an empty drop zone
              return Container(
                width: 40.w,
                height: 32.h,
                decoration: BoxDecoration(
                  color: isHovering ? const Color(0xFFEFF0FE) : Colors.transparent,
                  border: Border.all(
                    color: isHovering ? const Color(0xFF554FF0) : const Color(0xFFE3E8EF),
                    width: 2.w,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: isHovering
                    ? Icon(
                        Icons.add,
                        size: 20.w,
                        color: const Color(0xFF554FF0),
                      )
                    : null,
              );
            },
          ),
      ],
    );
  }
}
