part of '../../../roleplay.dart';

class RoleplayIntroMissions extends StatelessWidget {
  final List<RoleplayMissionEntity> missions;

  const RoleplayIntroMissions({super.key, required this.missions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppText(
          context.text.roleplay.rolePlayIntroMissionTitle,
          textAlign: TextAlign.center,
          style: AppStyle.text24.copyWith(
            fontWeight: FontWeight.w700,
            color: AppCustomColor.textWhite,
            height: 36 / 24,
          ),
        ),
        16.verticalSpace,
        ...missions.asMap().entries.map(
          (entry) {
            final int index = entry.key;
            final RoleplayMissionEntity mission = entry.value;
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    '${index + 1}',
                    style: AppStyle.text24.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppCustomColor.textWhite.withValues(alpha: 0.8),
                      height: 36 / 24,
                    ),
                  ),
                  16.horizontalSpace,
                  AppText(
                    mission.content.text,
                    expandFlex: 1,
                    style: AppStyle.text16.copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppCustomColor.textWhite.withValues(alpha: 0.8),
                      height: 24 / 16,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
