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
          overflow: TextOverflow.visible,
          style: AppStyle.text16.copyWith(
            color: active ? AppCustomColor.textSecondary : AppCustomColor.textTertiary,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        6.verticalSpace,
        Stack(
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
      ],
    );
  }
}
