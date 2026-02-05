part of '../../../course.dart';

class CourseTabBar extends StatelessWidget {
  final TabController tabController;
  const CourseTabBar({super.key, required this.tabController});

  List<String> _buildTabList(BuildContext context, List<SkillsetEntity> skillsets) {
    return [
      context.text.allcourse.allcourseMyCourse,
      ...skillsets.map((skillset) => skillset.title.text),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HomeCubit, HomeState, List<SkillsetEntity>>(
      selector: (state) => state.skillsets,
      builder: (context, skillsets) {
        return BlocBuilder<CourseCubit, CourseState>(
          builder: (context, courseState) {
            final selectedIndex = courseState.selectedTabIndex;
            final tabList = _buildTabList(context, skillsets);

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
