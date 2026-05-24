part of '../../daily_warm_up.dart';

class DailyWarmUpCourseCard extends StatelessWidget {
  const DailyWarmUpCourseCard({super.key, required this.course});

  final CourseEntity course;

  @override
  Widget build(BuildContext context) {
    final imageUrl = course.image;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4B44CA).withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 4),
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
                    height: 116.h,
                    color: const Color(0xFFF2F1FE),
                    alignment: Alignment.center,
                    child: Icon(Icons.menu_book_rounded, color: const Color(0xFF4B44CA), size: 40.w),
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 116.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(height: 116.h, color: const Color(0xFFF2F1FE)),
                  ),
          ),
          16.verticalSpace,
          AppText(
            context.l10n.dailyWarmUp.course,
            style: AppStyle.text12.copyWith(color: const Color(0xFF7F8EA4), fontWeight: FontWeight.w600),
          ),
          6.verticalSpace,
          AppText(
            course.title.text,
            textAlign: TextAlign.center,
            maxLines: 3,
            style: AppStyle.text18.copyWith(color: const Color(0xFF0D121C), fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
