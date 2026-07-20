part of '../../../roleplay.dart';

class RoleplayCompleteBottomCTA extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double bottomPadding;
  final bool isLoading;

  const RoleplayCompleteBottomCTA({
    super.key,
    required this.label,
    required this.onPressed,
    required this.bottomPadding,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h + bottomPadding),
      child: GestureDetector(
        onTap: isLoading
            ? null
            : () {
                AppHaptic.celebrate();
                onPressed();
              },
        child: Container(
          height: 54.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppCustomColor.brandPrimary,
            borderRadius: BorderRadius.circular(1000.r),
          ),
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : AppText(
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
