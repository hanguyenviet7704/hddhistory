part of '../../../roleplay.dart';

class RoleplayHeroBackground extends StatelessWidget {
  final String imageUrl;

  const RoleplayHeroBackground({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(color: AppCustomColor.backgroundWhite);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CacheNetworkGraphic(
          url: imageUrl,
          fit: BoxFit.cover,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                // const Color(0xFF2F7EA6).op(0.70),
                // const Color(0xFF2F7EA6).op(0.38),
                // const Color(0xFF123D52).op(0.78),
                Colors.black.withValues(alpha: 0.65),
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.75),
              ],
              stops: const [0, 0.45, 1],
            ),
          ),
        ),
      ],
    );
  }
}
