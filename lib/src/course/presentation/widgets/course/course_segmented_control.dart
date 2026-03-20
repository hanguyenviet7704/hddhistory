part of '../../../course.dart';

class CourseSegmentedControl extends StatelessWidget {
  const CourseSegmentedControl({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourseCubit, CourseState>(
      buildWhen: (previous, current) => previous.selectedTabIndex != current.selectedTabIndex,
      builder: (context, state) {
        final selectedIndex = state.selectedTabIndex == 1 ? 1 : 0;

        return Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: AppCustomColor.neutral100,
            borderRadius: BorderRadius.circular(999.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CourseSegmentedTab(
                label: context.l10n.allcourse.allcourseMyCourse,
                isSelected: selectedIndex == 0,
                onTap: () => context.read<CourseCubit>().selectTab(0),
              ),
              6.horizontalSpace,
              _CourseSegmentedTab(
                label: context.l10n.allcourse.allcourseAllCourses,
                isSelected: selectedIndex == 1,
                onTap: () => context.read<CourseCubit>().selectTab(1),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CourseSegmentedTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CourseSegmentedTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppCustomColor.backgroundWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(36.r),
          border: isSelected ? Border.all(color: AppCustomColor.borderDefault) : null,
        ),
        child: AppText(
          label,
          style: (isSelected ? AppStyle.textBold12 : AppStyle.text12).copyWith(
            color: isSelected ? AppCustomColor.brandPrimary : AppCustomColor.textTertiary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
