part of '../../course.dart';

class TopProgressBar extends StatelessWidget {
  final VoidCallback? onTap;

  const TopProgressBar({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40.h,
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          decoration: BoxDecoration(
            color: AppCustomColor.greyE3,
            borderRadius: BorderRadius.circular(120.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BlocSelector<HomeCubit, HomeState, String>(
                selector: (state) => state.courseName,
                builder: (context, courseName) {
                  return AppText(
                    courseName,
                    style: AppStyle.text14.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppCustomColor.textPrimary,
                    ),
                    maxLines: 1,
                  );
                },
              ),
              8.horizontalSpace,
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20.w,
                color: AppCustomColor.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
