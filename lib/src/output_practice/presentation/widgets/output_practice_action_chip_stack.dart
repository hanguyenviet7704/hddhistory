part of '../../output_practice.dart';

class OutputPracticeActionChipStack extends StatelessWidget {
  const OutputPracticeActionChipStack({
    super.key,
    required this.helperLabel,
    required this.chips,
    required this.onChipTap,
    required this.resolveLabel,
  });

  final String helperLabel;
  final List<OutputPracticeActionChipVm> chips;
  final ValueChanged<OutputPracticeActionChipVm> onChipTap;
  final String Function(OutputPracticeActionChipVm chip) resolveLabel;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                helperLabel,
                style: AppStyle.text12.copyWith(
                  fontWeight: FontWeight.w500,
                  color: const Color(0x80362F82),
                  height: 1.75,
                ),
              ),
              8.horizontalSpace,
              Icon(
                Icons.subdirectory_arrow_left_rounded,
                size: 18.w,
                color: const Color(0x80362F82),
              ),
            ],
          ),
          8.verticalSpace,
          ...chips.map((chip) {
            final isSummary = chip.kind == OutputPracticeActionKind.summaryDecision;
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: GestureDetector(
                onTap: () => onChipTap(chip),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSummary ? const Color(0x994B44CA) : const Color(0x80362F82),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: AppText(
                    resolveLabel(chip),
                    style: AppStyle.text14.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      height: 1.75,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
