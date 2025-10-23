part of '../../../../../exercise.dart';

class Avatar extends StatelessWidget {
  final double size;
  final String? imageUrl;

  const Avatar({
    super.key,
    this.size = 44,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: const Color(0xFFE3E8EF), shape: BoxShape.circle),
      child: ClipOval(
        child: Image.network(
          imageUrl ?? 'https://i.pravatar.cc/${size.toInt()}',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFFE3E8EF),
              child: Icon(Icons.person, size: size * 0.5, color: Colors.white),
            );
          },
        ),
      ),
    );
  }
}
