part of '../../../course.dart';

class _RoadmapNodeIndicator extends StatelessWidget {
  final String? iconUrl;
  final String defaultIconAsset;
  final bool isLocked;

  const _RoadmapNodeIndicator({
    required this.iconUrl,
    required this.defaultIconAsset,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(13.5.w),
      decoration: BoxDecoration(
        color: isLocked ? AppCustomColor.neutral100 : AppCustomColor.brandPrimary50,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: iconUrl != null
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: iconUrl!,
                  width: 28.w,
                  height: 28.w,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => SvgPicture.asset(
                    defaultIconAsset,
                    width: 24.w,
                    height: 24.w,
                    colorFilter: ColorFilter.mode(
                      isLocked ? AppCustomColor.textQuaternary : AppCustomColor.brandPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                  errorWidget: (context, url, error) => SvgPicture.asset(
                    defaultIconAsset,
                    width: 24.w,
                    height: 24.w,
                    colorFilter: ColorFilter.mode(
                      isLocked ? AppCustomColor.textQuaternary : AppCustomColor.brandPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              )
            : SvgPicture.asset(
                defaultIconAsset,
                width: 28.w,
                height: 28.w,
                colorFilter: ColorFilter.mode(
                  isLocked ? AppCustomColor.textQuaternary : AppCustomColor.brandPrimary,
                  BlendMode.srcIn,
                ),
              ),
      ),
    );
  }
}
