part of '../../../course.dart';

class TopProgressBar extends StatelessWidget {
  const TopProgressBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Center(
        child: GestureDetector(
          onTap: () {
            AppDI.injector.get<CourseCubit>().setAllCourseSource('course_switch');
            CourseRoute().push(context);
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
                  buildWhen: (previous, current) => previous.currentSkillset.title.text != current.currentSkillset.title.text,
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
