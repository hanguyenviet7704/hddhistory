part of '../../monetization.dart';

class PaywallHeader extends StatelessWidget {
  const PaywallHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onClose,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: AppCustomColor.surfaceMuted,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.close, size: 18.sp, color: AppCustomColor.textPrimary),
          ),
        ),
        12.horizontalSpace,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                title,
                maxLines: 2,
                style: AppStyle.textBold24.copyWith(color: AppCustomColor.textPrimary),
              ),
              6.verticalSpace,
              AppText(
                subtitle,
                maxLines: 3,
                style: AppStyle.text16.copyWith(color: AppCustomColor.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
