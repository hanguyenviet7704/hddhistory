part of '../../../../exercise.dart';

/// Pool of available pause marks that can be dragged
/// Follows exact Figma styling from example implementation
class CuesPlacementAvailableMarks extends StatelessWidget {
  final List<OptionEntity> availableOptions;
  final int totalCount;
  final int availableCount;
  final Function(PauseMarkDragData data) onAcceptReturn;

  const CuesPlacementAvailableMarks({
    super.key,
    required this.availableOptions,
    required this.totalCount,
    required this.availableCount,
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
        final bool isHovering = candidateData.isNotEmpty && candidateData.first!.fromWordIndex != null;

        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isHovering ? const Color(0xFF554FF0).op(0.1) : const Color(0xFFF8F9FB),
            border: Border.all(
              color: const Color(0xFFE3E8EF),
              width: 2.w,
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with label and count badge
              Row(
                children: [
                  AppText(
                    'Available Pause Marks',
                    style: AppStyle.text14.copyWith(
                      color: const Color(0xFF7F8EA4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  8.horizontalSpace,
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: availableCount > 0 ? const Color(0xFF554FF0) : const Color(0xFFE3E8EF),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: AppText(
                      '$availableCount/$totalCount',
                      style: AppStyle.text12.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              12.verticalSpace,
              // Available marks with exact spacing
              if (availableOptions.isNotEmpty)
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  alignment: WrapAlignment.center,

                  children: availableOptions.map((option) {
                    return CuesPlacementPauseMark(
                      option: option,
                      isAvailable: true,
                    );
                  }).toList(),
                ),
              if (availableOptions.isEmpty)
                AppText(
                  'All pause marks have been placed',
                  style: AppStyle.text12.copyWith(
                    color: const Color(0xFF7F8EA4).op(0.6),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
