part of '../../../onboard_v2.dart';

class OnboardV2PathMapNode extends StatelessWidget {
  const OnboardV2PathMapNode({
    super.key,
    required this.label,
    required this.iconPath,
    required this.active,
  });

  final String label;
  final String iconPath;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final circleSize = active ? 58.w : 36.w;
    final iconSize = active ? 24.w : 16.w;
    final nodeSize = active ? 68.w : 36.w;

    return SizedBox(
      width: 100.w,
      height: 100.w,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: 100.w,
            height: 24.w,
            child: Center(
              child: AppText(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: AppStyle.text16.copyWith(
                  color: active ? AppCustomColor.textSecondary : AppCustomColor.textTertiary,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ),
          Positioned(
            left: (active ? 16 : 32).w,
            top: 30.w,
            width: nodeSize,
            height: nodeSize,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (active)
                  ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 4.364.r, sigmaY: 4.364.r),
                    child: Container(
                      width: 68.w,
                      height: 68.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: OnboardV2GradientText.gradient.colors.map((color) => color.withValues(alpha: 0.5)).toList(),
                        ),
                      ),
                    ),
                  ),
                Container(
                  width: circleSize,
                  height: circleSize,
                  padding: EdgeInsets.all(active ? 17.w : 10.w),
                  decoration: BoxDecoration(
                    color: active ? Colors.white : const Color(0xFFE4E2FD),
                    shape: BoxShape.circle,
                  ),
                  child: CacheNetworkGraphic(url: iconPath, width: iconSize, height: iconSize, fit: BoxFit.cover),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
