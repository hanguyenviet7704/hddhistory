part of '../../../course.dart';

class RoadmapSessionHeader extends StatelessWidget {
  final BaseMultiLanguage title;
  final BaseMultiLanguage description;

  const RoadmapSessionHeader({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    if (title.text.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(4.w, 0, 4.w, 24.h),
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 12.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFFEBF0F7),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          AppText(
            title.text.toUpperCase(),
            style: AppStyle.textBold12.copyWith(
              color: AppCustomColor.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),

          if (description.text.isNotEmpty) ...[
            4.verticalSpace,
            AppText(
              description.text,
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              style: AppStyle.text12.copyWith(
                color: AppCustomColor.textTertiary,
                height: 1.75,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
