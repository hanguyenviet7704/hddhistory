part of '../../../../lesson.dart';

class SentenceBuilder extends StatelessWidget {
  final Map<int, String> placedWords;
  final String targetArea;
  final int answerCount;
  final Function(int index, String word, int? fromIndex) onWordPlaced;
  final Function(int index) onWordRemoved;
  final SlotState Function(int index) getSlotState;

  const SentenceBuilder({
    super.key,
    required this.placedWords,
    required this.targetArea,
    required this.answerCount,
    required this.onWordPlaced,
    required this.onWordRemoved,
    required this.getSlotState,
  });

  List<Widget> _buildSentenceWidgets() {
    final widgets = <Widget>[];
    final parts = targetArea.split('___');

    for (int i = 0; i < parts.length; i++) {
      // Add words from this text part, split by space
      if (parts[i].trim().isNotEmpty) {
        final words = parts[i].trim().split(' ');
        for (var word in words) {
          if (word.isNotEmpty) {
            widgets.add(
              AppText(
                word,
                style: AppStyle.text16.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF0D121C)),
              ),
            );
          }
        }
      }

      // Add blank slot if not the last part
      if (i < answerCount) {
        widgets.add(
          BlankSlot(
            index: i,
            placedWord: placedWords[i],
            onWordPlaced: (word, fromIndex) => onWordPlaced(i, word, fromIndex),
            onWordRemoved: (word, fromIndex) => onWordRemoved(fromIndex),
            onDragCancelled: null,
            slotState: getSlotState(i),
          ),
        );
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: ShapeDecoration(
        color: Colors.white /* Background-White */,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 2,
            color: const Color(0xFFE3E8EF) /* Border-border-secondary */,
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
