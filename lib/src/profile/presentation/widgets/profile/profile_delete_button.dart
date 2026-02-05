part of '../../../profile.dart';

class ProfileDeleteButton extends StatelessWidget {
  const ProfileDeleteButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999.r),
        onTap: onTap,
        child: Container(
          height: 54.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppCustomColor.backgroundError,
            borderRadius: BorderRadius.circular(999.r),
          ),
          child: Text(
            context.text.setting.settingProfileDesstructiveButton,
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.errorRed,
              height: 1.75,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
