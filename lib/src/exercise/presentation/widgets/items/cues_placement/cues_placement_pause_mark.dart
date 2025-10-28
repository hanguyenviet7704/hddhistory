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

/// Draggable pause mark widget
class CuesPlacementPauseMark extends StatelessWidget {
  final OptionEntity option;
  final int? fromWordIndex; // null if from available pool
  final AnswerState? state;

  const CuesPlacementPauseMark({
    super.key,
    required this.option,
    this.fromWordIndex,
    this.state,
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

  @override
  Widget build(BuildContext context) {
    final markWidget = Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2.w),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: AppText(
        option.text,
        style: AppStyle.text20.copyWith(
          height: 1.0,
        ),
      ),
    );

    // If already checked, don't make it draggable
    if (state != null && state != AnswerState.selected) {
      return markWidget;
    }

    return Draggable<PauseMarkDragData>(
      data: PauseMarkDragData(
        optionId: option.id,
        fromWordIndex: fromWordIndex,
      ),
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.7,
          child: markWidget,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: markWidget,
      ),
      child: markWidget,
    );
  }
}
