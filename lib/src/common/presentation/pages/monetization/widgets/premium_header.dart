part of '../monetization.dart';

class PremiumHeader extends StatelessWidget {
  final VoidCallback? onClose;

  const PremiumHeader({
    super.key,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(left: 38.w),
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: onClose,
          child: Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Icon(
              FontAwesomeIcons.xmark,
              color: AppCustomColor.black36,
            ),
          ),
        ),
      ),
    );
  }
}
