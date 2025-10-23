part of '../../../../../exercise.dart';


class TapAnswerCardsArea extends StatelessWidget {
  final List<String> availableWords;
  final Function(String word, GlobalKey cardKey) onWordTap;

  const TapAnswerCardsArea({super.key, required this.availableWords, required this.onWordTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8EF), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: availableWords.isEmpty
          ? Container(
              height: 45,
              alignment: Alignment.center,
              child: Text(
                'All words used',
                style: TextStyle(fontSize: 14, color: const Color(0xFF7F8EA4).withValues(alpha: 0.5), fontStyle: FontStyle.italic),
              ),
            )
          : Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: availableWords.asMap().entries.map((entry) {
                final index = entry.key;
                final word = entry.value;
                final cardKey = GlobalKey();
                return TapAnswerCard(
                  key: cardKey,
                  word: word,
                  onTap: () => onWordTap(word, cardKey),
                ).animate().fadeIn(duration: 200.ms, delay: (index * 50).ms).slideY(begin: 0.2, end: 0, duration: 200.ms, delay: (index * 50).ms);
              }).toList(),
            ),
    );
  }
}
