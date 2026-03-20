part of '../../../profile.dart';

class UserAchievementList extends StatelessWidget {
  const UserAchievementList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          context.l10n.setting.achievementsTitle,
          style: AppStyle.text16.copyWith(
            color: AppCustomColor.textSecondary,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
        8.verticalSpace,
        BlocSelector<AchievenmentProgressCubit, AchievenmentProgressState, List<AchievenmentResponseEntity>>(
          selector: (state) => state.achievenments,
          builder: (context, achievenments) {
            if (achievenments.isEmpty) return const SizedBox.shrink();
            return Column(
              children: List.generate(
                achievenments.length,
                (index) => UserAchievementCard(achievement: achievenments[index]),
              ),
            );
          },
        ),
      ],
    );
  }
}
