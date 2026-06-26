part of '../utils.dart';

class FilterTabBar extends StatelessWidget {
  const FilterTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.padding,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return Semantics(
            label: tabs[index],
            button: true,
            selected: isSelected,
            child: InkWell(
              onTap: () => onTabSelected(index),
              borderRadius: BorderRadius.circular(20.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppCustomColor.brandPrimary
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppCustomColor.brandPrimary
                        : AppCustomColor.borderDefault,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  tabs[index],
                  style: AppStyle.text14.copyWith(
                    color: isSelected
                        ? AppCustomColor.backgroundWhite
                        : AppCustomColor.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
