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
          // The Profile page already applies the horizontal page margin (20.w),
          // so this section adds no horizontal padding of its own — otherwise
          // the margins double up. Sections sit directly on the white sheet
          // (Figma 10736:51182) — no outlined/shadowed card.
          decoration: BoxDecoration(
            color: studyThemeCardColor(context),
            borderRadius: BorderRadius.circular(20.r),
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
