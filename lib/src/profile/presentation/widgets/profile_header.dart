part of '../../profile.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.isEditing,
    required this.onBack,
    required this.onActionTap,
  });

  final bool isEditing;
  final VoidCallback onBack;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        border: Border(bottom: BorderSide(color: AppCustomColor.borderDefault, width: 1)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 36.w,
              height: 36.w,
              child: IconButton(
                padding: EdgeInsets.zero,
                splashRadius: 20.w,
                icon: Icon(Icons.arrow_back_ios_new, color: AppCustomColor.textTertiary, size: 18.w),
                onPressed: onBack,
              ),
            ),
          ),
          Text(
            context.text.setting.settingProfileLabel,
            style: AppStyle.text16.copyWith(
              color: AppCustomColor.textTertiary,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size(48.w, 32.h),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onActionTap,
              child: Text(
                isEditing ? context.text.setting.settingProfileDoneEditButton : context.text.setting.settingEditProfileButton,
                style: AppStyle.text16.copyWith(
                  color: AppCustomColor.brandPrimary,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
