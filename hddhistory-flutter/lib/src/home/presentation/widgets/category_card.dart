part of '../../home.dart';

class CategoryCardWidget extends StatelessWidget {
  final CategoryEntity category;
  final VoidCallback? onTap;

  const CategoryCardWidget({
    super.key,
    required this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              AppHaptic.select();
              onTap!();
            },
      child: Container(
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundGray,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category title
                  AppText(
                    category.title.text,
                    style: AppStyle.textBold14.copyWith(
                      color: AppCustomColor.textPrimary,
                    ),
                    maxLines: 2,
                  ),
                  4.verticalSpace,
                  // Course count
                  AppText(
                    context.l10n.home.coursesCount(count: category.courses.length),
                    style: AppStyle.text12.copyWith(
                      color: AppCustomColor.textTertiary,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            // Category image
            Expanded(
              child: category.image.isNotEmpty
                  ? CacheNetworkGraphic(
                      borderRadius: BorderRadius.all(Radius.circular(16.r)),
                      url: category.image,
                      alignment: Alignment.bottomRight,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    )
                  : Icon(
                      Icons.category,
                      color: AppCustomColor.textTertiary,
                      size: 40.w,
                    ),
            ),

            // Category info
          ],
        ),
      ),
    );
  }
}
