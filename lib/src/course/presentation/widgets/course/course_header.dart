part of '../../../course.dart';

class CourseHeader extends StatelessWidget {
  const CourseHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
      child: BlocBuilder<CourseCubit, CourseState>(
        buildWhen: (prev, curr) =>
            prev.searchQuery != curr.searchQuery || prev.isSearchActive != curr.isSearchActive,
        builder: (context, state) {
          return GestureDetector(
            onTap: state.isSearchActive
                ? null
                : () {
                    context.read<CourseCubit>().activateSearch();
                  },
            child: Container(
              height: 48.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: state.isSearchActive
                    ? AppCustomColor.backgroundWhite
                    : AppCustomColor.backgroundGray,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: state.isSearchActive
                      ? AppCustomColor.brandPrimary
                      : AppCustomColor.borderDefault,
                  width: state.isSearchActive ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: AppCustomColor.textTertiary,
                    size: 20.w,
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: state.isSearchActive
                        ? TextField(
                            autofocus: true,
                            controller: context.read<CourseCubit>().searchController,
                            style: AppStyle.text14.copyWith(
                              color: AppCustomColor.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Finding...',
                              hintStyle: AppStyle.text14.copyWith(
                                color: AppCustomColor.textTertiary,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: context.read<CourseCubit>().onSearchChanged,
                          )
                        : AppText(
                            'Type title, keyword,...',
                            style: AppStyle.text14.copyWith(
                              color: AppCustomColor.textTertiary,
                            ),
                          ),
                  ),
                  if (state.isSearchActive)
                    GestureDetector(
                      onTap: () => context.read<CourseCubit>().clearSearch(),
                      child: Icon(
                        Icons.cancel_rounded,
                        color: AppCustomColor.textTertiary,
                        size: 20.w,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
