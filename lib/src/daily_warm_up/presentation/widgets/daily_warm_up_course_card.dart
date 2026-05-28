part of '../../daily_warm_up.dart';

class DailyWarmUpCourseCard extends StatelessWidget {
  const DailyWarmUpCourseCard({super.key, required this.course});

  final CourseEntity course;

  @override
  Widget build(BuildContext context) {
    final imageUrl = course.image;

    return Container(
      width: 307,
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4B44CA).withValues(alpha: 0.15),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: imageUrl.isEmpty
                ? Container(
                    height: 208,
                    width: double.infinity,
                    color: const Color(0xFFF2F1FE),
                    alignment: Alignment.center,
                    child: Icon(Icons.menu_book_rounded, color: const Color(0xFF4B44CA), size: 40.w),
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 208,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(height: 208, color: const Color(0xFFF2F1FE)),
                  ),
          ),
          20.verticalSpace,
          AppText(
            context.l10n.dailyWarmUp.course.toUpperCase(),
            style: AppStyle.text12.copyWith(color: const Color(0xFF554FF0), fontWeight: FontWeight.w700),
          ),
          8.verticalSpace,
          AppText(
            course.title.text,
            textAlign: TextAlign.center,
            maxLines: 3,
            style: AppStyle.text16.copyWith(color: const Color(0xFF0D121C), fontWeight: FontWeight.w700, height: 1.5),
          ),
        ],
      ),
    );
  }
}
