part of '../../../roleplay.dart';

class RoleplayIntroHeroCard extends StatelessWidget {
  final String imageUrl;

  const RoleplayIntroHeroCard({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(16.r);

    return Container(
      width: 237.w,
      height: 300.h,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            offset: Offset(0, 20.h),
            blurRadius: 30.r,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl.isEmpty) {
      return Image.asset(
        AppAsset.images.common.introBg.path,
        fit: BoxFit.cover,
      );
    }

    return CacheNetworkGraphic(
      url: imageUrl,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.zero,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
