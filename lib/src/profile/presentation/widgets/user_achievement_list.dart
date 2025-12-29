part of '../../profile.dart';

class UserAchievementList extends StatelessWidget {
  const UserAchievementList({
    super.key,
    this.padding,
  });

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AchievenmentProgressCubit, AchievenmentProgressState, List<AchievenmentResponseEntity>>(
      selector: (state) => state.achievenments,
      builder: (context, achievenments) {
        if (achievenments.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Achievements',
              style: AppStyle.text16.copyWith(
                color: AppCustomColor.textSecondary,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
            8.verticalSpace,
            Column(
              children: List.generate(
                achievenments.length,
                (index) {
                  final AchievenmentResponseEntity achievement = achievenments[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: index == achievenments.length - 1 ? 0 : 16.h),
                    child: UserAchievementCard(achievement: achievement),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
