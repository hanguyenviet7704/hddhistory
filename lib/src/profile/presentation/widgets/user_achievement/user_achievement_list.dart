part of '../../../profile.dart';

class UserAchievementList extends StatelessWidget {
  const UserAchievementList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AchievenmentProgressCubit, AchievenmentProgressState, List<AchievenmentResponseEntity>>(
      selector: (state) => state.achievenments,
      builder: (context, achievenments) {
        final visible = achievenments.where((a) => a.totalCourse > 0).toList();
        if (visible.isEmpty) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundWhite,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppCustomColor.backgroundGray, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppCustomColor.borderDefault,
                blurRadius: 4.r,
                offset: Offset.zero,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < visible.length; i++) ...[
                if (i > 0) 32.verticalSpace,
                UserAchievementCard(achievement: visible[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}
