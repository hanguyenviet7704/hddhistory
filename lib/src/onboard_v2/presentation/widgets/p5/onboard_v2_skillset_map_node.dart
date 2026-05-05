part of '../../../onboard_v2.dart';

class OnboardV2SkillsetMapNode extends StatelessWidget {
  const OnboardV2SkillsetMapNode({
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          style: AppStyle.text16.copyWith(
            color: active ? AppCustomColor.textSecondary : AppCustomColor.textTertiary,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            height: 1.2,
          ),
        ),
        6.verticalSpace,
        SizedBox(
          height: active ? 68.w : 36.w,
          child: OverflowBox(
            maxWidth: active ? 68.w : 36.w,
            maxHeight: active ? 68.w : 36.w,
            alignment: Alignment.topCenter,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (active)
                  Container(
                    width: 68.w,
                    height: 68.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: OnboardV2GradientText.gradient,
                      boxShadow: [BoxShadow(color: AppCustomColor.brandPrimary.op(0.24), blurRadius: 20, spreadRadius: 2)],
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
                  child: SvgPicture.asset(iconPath, width: iconSize, height: iconSize),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
