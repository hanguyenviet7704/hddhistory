part of '../../monetization.dart';

class UserSubscriptionHeader extends StatelessWidget {
  const UserSubscriptionHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 1,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onBack,
            child: Padding(
              padding: EdgeInsets.all(10.w),
              child: Icon(Icons.arrow_back, size: 20.w, color: AppCustomColor.iconPrimary),
            ),
          ),
        ),
        12.horizontalSpace,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                t.monetization.manageTitle,
                style: AppStyle.textBold20.copyWith(color: AppCustomColor.textPrimary, height: 1.2),
              ),
              4.verticalSpace,
              AppText(
                t.monetization.manageSubtitle,
                maxLines: 2,
                style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
