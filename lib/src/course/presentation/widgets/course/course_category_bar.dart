part of '../../../course.dart';

class CourseCategoryBar extends StatelessWidget {
  final List<SkillsetEntity> skillsets;
  final int activeCategoryIndex;
  final Function(int) onCategoryTap;
  final ItemScrollController categoryScrollController;

  const CourseCategoryBar({
    super.key,
    required this.skillsets,
    required this.activeCategoryIndex,
    required this.onCategoryTap,
    required this.categoryScrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 12.h),
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: SizedBox(
        height: 34.h,
        child: ScrollablePositionedList.builder(
          scrollDirection: Axis.horizontal,
          itemCount: skillsets.length,
          itemScrollController: categoryScrollController,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(
                right: index < skillsets.length - 1 ? 12.w : 0,
              ),
              child: CourseCategoryChip(
                label: skillsets[index].title.text,
                isSelected: activeCategoryIndex == index,
                onTap: () => onCategoryTap(index),
              ),
            );
          },
        ),
      ),
    );
  }
}
