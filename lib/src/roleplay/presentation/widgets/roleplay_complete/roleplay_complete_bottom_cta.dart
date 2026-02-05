part of '../../../roleplay.dart';

class RoleplayCompleteBottomCTA extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double bottomPadding;

  const RoleplayCompleteBottomCTA({
    super.key,
    required this.label,
    required this.onPressed,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h + bottomPadding),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 54.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppCustomColor.brandPrimary,
            borderRadius: BorderRadius.circular(1000.r),
          ),
          alignment: Alignment.center,
          child: AppText(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: AppStyle.text16.copyWith(
              color: AppCustomColor.textWhite,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
