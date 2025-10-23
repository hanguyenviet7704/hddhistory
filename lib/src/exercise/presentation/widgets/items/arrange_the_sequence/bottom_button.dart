part of '../../../../exercise.dart';

class BottomButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback? onPressed;
  final String text;

  const BottomButton({super.key, required this.isEnabled, required this.onPressed, this.text = 'Check'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE3E8EF), width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled ? const Color(0xFF554FF0) : const Color(0xFFE3E8EF),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE3E8EF),
            disabledForegroundColor: const Color(0xFF7F8EA4),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1000)),
          ),
          child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5)),
        ),
      ),
    );
  }
}
