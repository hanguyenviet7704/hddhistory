part of '../../daily_warm_up.dart';

class DailyWarmUpSentenceBuilder extends StatelessWidget {
  const DailyWarmUpSentenceBuilder({
    super.key,
    required this.placedOptionIds,
    required this.options,
    required this.targetArea,
    required this.answerCount,
    required this.onOptionPlaced,
    required this.onOptionRemoved,
    required this.getSlotState,
  });

  final Map<int, int> placedOptionIds;
  final List<OptionEntity> options;
  final String targetArea;
  final int answerCount;
  final void Function(int slotIndex, int optionId) onOptionPlaced;
  final ValueChanged<int> onOptionRemoved;
  final SlotState Function(int index) getSlotState;

  List<Widget> _buildSentenceWidgets() {
    final widgets = <Widget>[];
    final parts = targetArea.split('___');

    for (var i = 0; i < parts.length; i++) {
      final words = parts[i].trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
      for (final word in words) {
        widgets.add(
          AppText(
            word,
            style: AppStyle.text16.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D121C),
            ),
          ),
        );
      }

      if (i < answerCount) widgets.add(_buildBlankSlot(i));
    }

    for (var i = parts.length; i < answerCount; i++) {
      widgets.add(_buildBlankSlot(i));
    }

    return widgets;
  }

  Widget _buildBlankSlot(int index) {
    final placedOption = _dailyWarmUpOptionById(options, placedOptionIds[index] ?? 0);
    return BlankSlot(
      index: index,
      placedWord: placedOption?.labelText,
      onWordPlaced: (word, fromIndex) {
        final movedOptionId = fromIndex == null ? null : placedOptionIds[fromIndex];
        final option = movedOptionId == null ? _dailyWarmUpFirstAvailableByLabel(options, placedOptionIds, word) : _dailyWarmUpOptionById(options, movedOptionId);
        if (option != null) onOptionPlaced(index, option.id);
      },
      onWordRemoved: (_, fromIndex) => onOptionRemoved(fromIndex),
      onDragCancelled: (_, _) {},
      slotState: getSlotState(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('daily-warm-up-sentence-builder'),
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            width: 2,
            color: Color(0xFFE3E8EF),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Wrap(
        spacing: 6.w,
        runSpacing: 10.h,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: _buildSentenceWidgets(),
      ),
    );
  }
}
