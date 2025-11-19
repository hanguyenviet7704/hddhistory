part of '../../setting.dart';

class SettingProfileCard extends StatelessWidget {
  const SettingProfileCard({super.key, required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final String name = _resolveName(context);
    final String email = _resolveEmail(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppCustomColor.textPrimary.op(.05),
            blurRadius: 32,
            offset: Offset(0, 18.h),
          ),
        ],
      ),
      child: Row(
        children: [
          _SettingProfileAvatar(user: user),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.textBold16.copyWith(
                    color: AppCustomColor.textPrimary,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.text14.copyWith(
                    color: AppCustomColor.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppCustomColor.iconPrimary, size: 20.w),
        ],
      ),
    );
  }

  String _resolveName(BuildContext context) {
    if (user.name.trim().isNotEmpty) {
      return user.name.trim();
    }
    return 'Guest';
  }

  String _resolveEmail(BuildContext context) {
    if (user.email.trim().isNotEmpty) {
      return user.email.trim();
    }
    return 'Guest Email';
  }
}

class _SettingProfileAvatar extends StatelessWidget {
  const _SettingProfileAvatar({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final double size = 56.w;
    if (user.photoUrl.trim().isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: AnyImageWidget(
            url: user.photoUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final String fallbackInitial = _buildInitial(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppCustomColor.green1B,
      ),
      alignment: Alignment.center,
      child: Text(
        fallbackInitial,
        style: AppStyle.textBold20.copyWith(color: AppCustomColor.textWhite),
      ),
    );
  }

  String _buildInitial(BuildContext context) {
    String reference = user.name.trim();
    if (reference.isEmpty) {
      reference = user.email.trim();
    }
    if (reference.isEmpty) {
      reference = 'Guest';
    }
    final int rune = reference.runes.first;
    return String.fromCharCode(rune).toUpperCase();
  }
}
