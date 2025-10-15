part of '../../../onboard.dart';

class CharacterIllustrationWidget extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;

  const CharacterIllustrationWidget({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return imagePath.isNotEmpty
        ? Image.asset(
            imagePath,
            width: 109.w,
          )
        : Icon(
            Icons.person,
            size: 60.w,
            color: Colors.grey[600],
          );
  }
}
