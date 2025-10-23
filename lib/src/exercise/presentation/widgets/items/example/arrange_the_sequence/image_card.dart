part of '../../../../../exercise.dart';

class ImageCard extends StatelessWidget {
  final String? imageUrl;

  const ImageCard({super.key, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: 183,
        decoration: BoxDecoration(color: const Color(0xFFF8F2EE), borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(16),
        child: imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.image_outlined, size: 64, color: Color(0xFFCDD5DF)));
                  },
                ),
              )
            : const Center(child: Icon(Icons.image_outlined, size: 64, color: Color(0xFFCDD5DF))),
      ),
    );
  }
}
