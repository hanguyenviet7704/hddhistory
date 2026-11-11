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
            color: const Color(0xFF94762A).withValues(alpha: 0.15),
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
                    color: const Color(0xFFFEFAF1),
                    alignment: Alignment.center,
                    child: Icon(Icons.menu_book_rounded, color: const Color(0xFF94762A), size: 40.w),
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 208,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(height: 208, color: const Color(0xFFFEFAF1)),
                  ),
          ),
          20.verticalSpace,
          AppText(
            context.l10n.dailyWarmUp.course.toUpperCase(),
            style: AppStyle.text12.copyWith(color: const Color(0xFFB5860F), fontWeight: FontWeight.w700),
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
