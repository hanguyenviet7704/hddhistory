part of '../../../data_collect.dart';

class MotivationStepContent extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String? subtitle;
  final bool isDarkBackground;

  const MotivationStepContent({
    super.key,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.isDarkBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color titleColor = isDarkBackground ? Colors.white : AppCustomColor.textBrand;
    final Color subtitleColor = isDarkBackground ? Colors.white.op(0.8) : AppCustomColor.textSecondary;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CacheNetworkGraphic(
            url: imageUrl,
            height: 260.h,
            width: 320.w,
            fit: BoxFit.contain,
          ),
          32.verticalSpace,
          AppText(
            title,
            textAlign: TextAlign.center,
            maxLines: 3,
            style: AppStyle.textBold20.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            12.verticalSpace,
            AppText(
              subtitle!,
              textAlign: TextAlign.center,
              maxLines: 4,
              style: AppStyle.text16.copyWith(
                color: subtitleColor,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
          80.verticalSpace,
        ],
      ),
    );
  }
}
