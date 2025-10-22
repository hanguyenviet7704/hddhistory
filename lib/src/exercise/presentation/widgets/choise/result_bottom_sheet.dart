part of '../../../exercise.dart';

enum ResultType { correct, incorrect }

class ResultBottomSheet extends StatelessWidget {
  final ResultType type;
  final VoidCallback onContinue;
  final VoidCallback? onExplain;

  const ResultBottomSheet({super.key, required this.type, required this.onContinue, this.onExplain});

  @override
  Widget build(BuildContext context) {
    final isCorrect = type == ResultType.correct;
    final backgroundColor = isCorrect ? const Color(0xFFEAFFEF) : const Color(0xFFFDEAE7);
    final buttonColor = isCorrect ? const Color(0xFF1DA75E) : const Color(0xFFE34646);
    final iconColor = isCorrect ? const Color(0xFF1DA75E) : const Color(0xFFE34646);
    final title = isCorrect ? 'Correct answer!' : 'Incorrect';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
                      child: Center(child: Icon(isCorrect ? Icons.check : Icons.close, color: Colors.white, size: 16)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(color: iconColor, fontSize: 16, fontWeight: FontWeight.w600, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (onExplain != null)
                Opacity(
                  opacity: 0.5,
                  child: GestureDetector(
                    onTap: onExplain,
                    child: const Row(
                      children: [
                        Icon(Icons.menu_book_outlined, color: Color(0xFF0D121C), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Explain',
                          style: TextStyle(color: Color(0xFF0D121C), fontSize: 14, fontWeight: FontWeight.w600, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1000)),
              ),
              child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}
