part of '../../../course.dart';

class TopProgressBar extends StatelessWidget {
  const TopProgressBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Re-render on app-locale changes: the skillset title below resolves
    // BaseMultiLanguage.text against the CURRENT locale at build time, and the
    // BlocBuilder's buildWhen can't observe locale switches (HomeState doesn't
    // change), so without this the dropdown kept showing the previous
    // language's text until an unrelated rebuild.
    context.watch<LocaleCubit>();
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Center(
        child: GestureDetector(
          onTap: () {
            // CourseCubit/PageCubit aren't provided above the roadmap tree, so
            // resolve them from DI (both are singletons).
            // Jump straight to the current skillset's chip/section in Explore.
            final skillsetIndex = AppDI.injector.get<HomeCubit>().state.selectedSkillsetIndex;
            AppDI.injector.get<CourseCubit>()
              ..setAllCourseSource('course_switch')
              ..jumpToSkillset(skillsetIndex);
            // Switch to the Explore shell branch (index 3) instead of push()ing
            // the grid onto the Courses branch, which left the bottom nav stuck
            // on "Courses". Pass the index so a first-time Explore build lands on
            // the same skillset (kept-alive builds use jumpToSkillset above).
            AppDI.injector.get<PageCubit>().setCurrentIndex(3);
            CourseRoute(selectedTabIndex: skillsetIndex).go(context);
          },
          child: Container(
            height: 36.h,
            padding: EdgeInsets.only(left: 16.w, right: 12.w),
            decoration: BoxDecoration(
              color: AppCustomColor.backgroundWhite,
              borderRadius: BorderRadius.circular(120.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BlocBuilder<HomeCubit, HomeState>(
                  // Compare the full multilang object, NOT `.text`: `.text`
                  // resolves both sides under the locale at comparison time,
                  // so a locale switch (or a refetch returning the same
                  // titles) always compared equal and suppressed the rebuild.
                  buildWhen: (previous, current) => previous.currentSkillset.title != current.currentSkillset.title,
                  builder: (context, homeState) {
                    return AppText(
                      homeState.currentSkillset.title.text,
                      style: AppStyle.text12.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppCustomColor.textPrimary,
                      ),
                      maxLines: 1,
                    );
                  },
                ),
                8.horizontalSpace,
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16.w,
                  color: AppCustomColor.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
