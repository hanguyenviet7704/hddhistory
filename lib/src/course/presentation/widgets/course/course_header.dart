part of '../../../course.dart';

class CourseHeader extends StatelessWidget {
  const CourseHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: BlocBuilder<CourseCubit, CourseState>(
        buildWhen: (prev, curr) =>
            prev.searchQuery != curr.searchQuery || prev.isSearchActive != curr.isSearchActive,
        builder: (context, state) {
          return GestureDetector(
            onTap: state.isSearchActive
                ? null
                : () {
                    AppHaptic.select();
                    context.read<CourseCubit>().activateSearch();
                  },
            child: Container(
              height: 56.h,
              padding: EdgeInsets.only(
                left: 22.w,
                right: state.isSearchActive ? 14.w : 4.w,
                top: 4.h,
                bottom: 4.h,
              ),
              decoration: BoxDecoration(
                color: state.isSearchActive
                    ? AppCustomColor.backgroundWhite
                    : AppCustomColor.backgroundGray,
                borderRadius: BorderRadius.circular(50.r),
                border: Border.all(
                  color: state.isSearchActive
                      ? AppCustomColor.brandPrimary.withValues(alpha: 0.6)
                      : AppCustomColor.borderDefault,
                  width: 2,
                ),
                boxShadow: state.isSearchActive
                    ? [const BoxShadow(color: Color(0xFFEBF0F7), blurRadius: 2)]
                    : null,
              ),
              child: Row(
                children: [
                  Semantics(
                    label: context.l10n.allcourse.searchSemanticLabel,
                    child: Icon(
                      Icons.search_rounded,
                      color: AppCustomColor.textTertiary,
                      size: 24.w,
                    ),
                  ),
                  8.horizontalSpace,
                  Expanded(
                    child: state.isSearchActive
                        ? TextField(
                            autofocus: true,
                            controller: context.read<CourseCubit>().searchController,
                            style: AppStyle.text16.copyWith(
                              color: AppCustomColor.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: context.l10n.allcourse.searchPlaceholderActive,
                              hintStyle: AppStyle.text16.copyWith(
                                color: AppCustomColor.textTertiary,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            textInputAction: TextInputAction.search,
                            // Live filtering happens via onChanged; results show
                            // as the user types. "Recent" now tracks viewed
                            // courses, so there's nothing to persist on submit.
                            onChanged: context.read<CourseCubit>().onSearchChanged,
                          )
                        : AppText(
                            context.l10n.allcourse.searchPlaceholder,
                            style: AppStyle.text16.copyWith(
                              color: AppCustomColor.textTertiary,
                            ),
                          ),
                  ),
                  if (state.isSearchActive)
                    Semantics(
                      label: context.l10n.allcourse.searchClearSemanticLabel,
                      button: true,
                      child: GestureDetector(
                        // Spec: "X" clears the entered text (staying in search
                        // → shows Recent); tapping it again when empty exits.
                        onTap: () {
                          AppHaptic.select();
                          final cubit = context.read<CourseCubit>();
                          if (state.searchQuery.isEmpty) {
                            cubit.deactivateSearch();
                          } else {
                            cubit.clearSearchText();
                          }
                        },
                        child: Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: const BoxDecoration(
                            color: AppCustomColor.neutral300,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14.w,
                            color: AppCustomColor.backgroundWhite,
                          ),
                        ),
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
