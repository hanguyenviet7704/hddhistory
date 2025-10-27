part of '../../../../exercise.dart';

class SentenceBuilder extends StatelessWidget {
  final Map<int, String> placedWords;
  final String targetArea;
  final int answerCount;
  final Function(int index, String word, int? fromIndex) onWordPlaced;
  final Function(int index) onWordRemoved;

  const SentenceBuilder({
    super.key,
    required this.placedWords,
    required this.targetArea,
    required this.answerCount,
    required this.onWordPlaced,
    required this.onWordRemoved,
  });

  List<Widget> _buildSentenceWidgets() {
    final widgets = <Widget>[];
    final parts = targetArea.split('___');

    for (int i = 0; i < parts.length; i++) {
      // Add text before blank
      if (parts[i].trim().isNotEmpty) {
        widgets.add(
          AppText(
            parts[i].trim(),
            maxLines: 5,
            style: AppStyle.text20.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D121C),
              height: 1.5,
            ),
          ),
        );
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE3E8EF).withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: _buildSentenceWidgets(),
      ),
    );
  }
}
