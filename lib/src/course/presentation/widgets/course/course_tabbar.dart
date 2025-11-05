part of '../../../course.dart';

class CourseTabBar extends StatelessWidget {
  final TabController tabController;
  const CourseTabBar({super.key, required this.tabController});

  List<String> _buildTabList(List<SkillsetEntity> skillsets) {
    return [
      'My course',
      ...skillsets.map((skillset) => skillset.title.text),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, homeState) {
        return BlocBuilder<CourseCubit, CourseState>(
          builder: (context, courseState) {
            final skillsets = homeState.skillsets;
            final selectedIndex = courseState.selectedTabIndex;
            final tabList = _buildTabList(skillsets);

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              height: 48.h,
              child: TabBar(
                controller: tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.zero,
                labelPadding: EdgeInsets.zero,
                indicatorPadding: EdgeInsets.zero,
                indicator: const BoxDecoration(color: Colors.transparent),
                dividerHeight: 0,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                splashFactory: NoSplash.splashFactory,
                tabs: List.generate(tabList.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < tabList.length - 1 ? 8.w : 0,
                    ),
                    child: CourseTabChip(
                      label: tabList[index],
                      isSelected: selectedIndex == index,
                      onTap: () {
                        context.read<CourseCubit>().selectTab(index);
                      },
                    ),
                  );
                }),
              ),
            );
          },
        );
      },
    );
  }
}
