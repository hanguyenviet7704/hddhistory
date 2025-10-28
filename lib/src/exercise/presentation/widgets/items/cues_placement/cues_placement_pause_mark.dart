part of '../../../../exercise.dart';

/// Data class for dragging pause marks
class PauseMarkDragData {
  final int optionId;
  final int? fromWordIndex; // null if from available pool

  const PauseMarkDragData({
    required this.optionId,
    this.fromWordIndex,
  });
}

/// Draggable pause mark widget with exact Figma styling
class CuesPlacementPauseMark extends StatelessWidget {
  final OptionEntity option;
  final int? fromWordIndex; // null if from available pool
  final AnswerState? state;
  final bool isAvailable; // true if from available pool, false if placed in grid

  const CuesPlacementPauseMark({
    super.key,
    required this.option,
    this.fromWordIndex,
    this.state,
    this.isAvailable = false,
  });

  Color get backgroundColor {
    if (state == null) return Colors.white;
    return switch (state!) {
      AnswerState.selected => const Color(0xFFEFF0FE),
      AnswerState.correct => const Color(0xFFEAFFEF),
      AnswerState.incorrect => const Color(0xFFFDEAE7),
      _ => Colors.white,
    };
  }

  Color get borderColor {
    if (state == null) return const Color(0xFFE3E8EF);
    return switch (state!) {
      AnswerState.selected => const Color(0xFF554FF0),
      AnswerState.correct => const Color(0xFF1DA75E),
      AnswerState.incorrect => const Color(0xFFE34646),
      _ => const Color(0xFFE3E8EF),
    };
  }

  /// Normal state widget
  Widget get _normalWidget {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2.w),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: CuesPlacementPauseMarkIcon(filled: true),
    );
  }

  /// Widget when being dragged (shows faded/disabled state)
  Widget get _draggingWidget {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE3E8EF).withValues(alpha: 0.5),
        border: Border.all(color: const Color(0xFFE3E8EF), width: 2.w),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: CuesPlacementPauseMarkIcon(filled: false),
    );
  }

  /// Feedback widget while dragging (with shadow)
  Widget get _feedbackWidget {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        border: Border.all(color: const Color(0xFF554FF0), width: 2.w),
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8.sp,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: CuesPlacementPauseMarkIcon(filled: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If already checked, don't make it draggable
    if (state != null && state != AnswerState.selected) {
      return _normalWidget;
    }

    return Draggable<PauseMarkDragData>(
      data: PauseMarkDragData(
        optionId: option.id,
        fromWordIndex: fromWordIndex,
      ),
      feedback: Material(
        color: Colors.transparent,
        child: _feedbackWidget,
      ),
      childWhenDragging: _draggingWidget,
      child: _normalWidget,
    );
  }
}
