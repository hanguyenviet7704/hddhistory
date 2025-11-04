part of '../../home.dart';

class SkillsetCardWidget extends StatelessWidget {
  final SkillsetEntity skillset;
  final VoidCallback? onTap;

  const SkillsetCardWidget({
    super.key,
    required this.skillset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 155.w,
        height: 155.w,
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: AppCustomColor.white,
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
            // Skillset image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppCustomColor.greyF5,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                  ),
                ),
                child: skillset.image.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.r),
                          topRight: Radius.circular(16.r),
                        ),
                        child: Image.network(
                          skillset.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported,
                              color: AppCustomColor.grey9A,
                              size: 40.w,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.category,
                        color: AppCustomColor.grey9A,
                        size: 40.w,
                      ),
              ),
            ),
            // Skillset info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Skillset title
                    AppText(
                      skillset.title.text,
                      style: AppStyle.textBold14.copyWith(
                        color: AppCustomColor.black36,
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 4.h),
                    // Course count
                    AppText(
                      '${skillset.courses.length} courses',
                      style: AppStyle.text12.copyWith(
                        color: AppCustomColor.grey69,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
