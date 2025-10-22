part of '../../../exercise.dart';

class TextBubble extends StatelessWidget {
  final String text;
  final Color? avatarColor;

  const TextBubble({super.key, required this.text, this.avatarColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE3E8EF), width: 2),
          ),
          child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF364152), height: 1.5)),
        ),
        Positioned(
          left: -6,
          bottom: -6,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: avatarColor ?? const Color(0xFF554FF0), shape: BoxShape.circle),
            child: ClipOval(
              child: Image.network(
                'https://i.pravatar.cc/32',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: avatarColor ?? const Color(0xFF554FF0),
                    child: Icon(Icons.person, size: 16, color: Colors.white),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
