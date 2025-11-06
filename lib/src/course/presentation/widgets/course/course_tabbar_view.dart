part of '../../../course.dart';

class CourseTabBarView extends StatelessWidget {
  final TabController tabController;
  const CourseTabBarView({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, homeState) {
        final skillsets = homeState.skillsets;
        final tabCount = skillsets.length + 1; // "My course" + skillsets

        return TabBarView(
          controller: tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(tabCount, (index) {
            if (index == 0) return const MyCourseTab();
            
            final skillsetIndex = index - 1;
            if (skillsetIndex >= skillsets.length || skillsetIndex < 0) return const CourseEmptyState();

            return SkillSetTab(skillset: skillsets[skillsetIndex]);
          }),
        );
      },
    );
  }
}
