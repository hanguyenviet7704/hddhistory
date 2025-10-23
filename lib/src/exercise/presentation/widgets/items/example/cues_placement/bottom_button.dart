part of '../../../../../exercise.dart';

class CuesBottomButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color? color;

  const CuesBottomButton({super.key, required this.text, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Container(
        height: 54,
        decoration: BoxDecoration(color: color ?? const Color(0xFF554FF0), borderRadius: BorderRadius.circular(1000)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(1000),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
