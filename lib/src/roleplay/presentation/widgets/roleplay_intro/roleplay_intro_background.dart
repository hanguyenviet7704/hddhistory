part of '../../../roleplay.dart';

class RoleplayIntroBackground extends StatelessWidget {
  final String imageUrl;

  const RoleplayIntroBackground({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppCustomColor.roleplayIntroBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: CacheNetworkGraphic(
                url: imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.zero,
              ),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0),
                  AppCustomColor.roleplayIntroBackground,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
