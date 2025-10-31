part of '../../../../lesson.dart';

/// Pool of available pause marks that can be dragged
/// Shows all marks with placeholders for placed marks (similar to drag-and-drop module)
class CuesPlacementAvailableMarks extends StatelessWidget {
  final List<OptionEntity> allOptions; // All marks from the question
  final List<OptionEntity> availableOptions; // Only unplaced marks
  final Function(PauseMarkDragData data) onAcceptReturn;

  const CuesPlacementAvailableMarks({
    super.key,
    required this.allOptions,
    required this.availableOptions,
    required this.onAcceptReturn,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<PauseMarkDragData>(
      onWillAcceptWithDetails: (details) {
        // Only accept if the mark is being moved back from a placed position
        return details.data.fromWordIndex != null;
      },
      onAcceptWithDetails: (details) {
        if (details.data.fromWordIndex != null) {
          onAcceptReturn(details.data);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isDraggingFromSentence = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isDraggingFromSentence ? const Color(0xFFE3E8EF).withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          alignment: Alignment.center,
          child: Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            alignment: WrapAlignment.center,
            children: allOptions.map((option) {
              final isAvailable = availableOptions.any((availableOption) => availableOption.id == option.id);

              if (isAvailable) {
                // Mark is available - show as draggable
                return CuesPlacementPauseMark(
                  option: option,
                  isAvailable: true,
                );
              } else {
                // Mark is placed in sentence - show as drop target placeholder
                return DragTarget<PauseMarkDragData>(
                  onWillAcceptWithDetails: (details) {
                    final draggedOptionId = details.data.optionId;
                    final fromWordIndex = details.data.fromWordIndex;
                    // Accept if dragging from a placed position back to this placeholder
                    return draggedOptionId == option.id && fromWordIndex != null;
                  },
                  onAcceptWithDetails: (details) {
                    if (details.data.fromWordIndex != null) {
                      onAcceptReturn(details.data);
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isHovering = candidateData.isNotEmpty;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: isHovering
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF58CC02).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: _FadedPauseMarkPlaceholder(option: option),
                    );
                  },
                );
              }
            }).toList(),
          ),
        );
      },
    );
  }
}

/// Faded/grayed out placeholder for placed pause marks
class _FadedPauseMarkPlaceholder extends StatelessWidget {
  final OptionEntity option;

  const _FadedPauseMarkPlaceholder({required this.option});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.3,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: const Color(0xFFE3E8EF).withValues(alpha: 0.5),
          border: Border.all(color: const Color(0xFFE3E8EF), width: 2.w),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: CuesPlacementPauseMarkIcon(filled: false),
      ),
    );
  }
}
