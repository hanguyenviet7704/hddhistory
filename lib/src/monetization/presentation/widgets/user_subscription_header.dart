part of '../../monetization.dart';

class UserSubscriptionHeader extends StatelessWidget {
  const UserSubscriptionHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: const BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        border: Border(
          bottom: BorderSide(color: AppCustomColor.borderDefault),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18.w,
                  color: AppCustomColor.textTertiary,
                ),
              ),
            ),
          ),
          AppText(
            t.monetization.subscriptionTitle,
            style: AppStyle.text16.copyWith(
              fontWeight: FontWeight.w600,
              color: AppCustomColor.textTertiary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
