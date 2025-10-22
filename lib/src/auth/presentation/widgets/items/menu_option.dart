part of '../../../auth.dart';

class MenuOption extends StatelessWidget {
  final String icon;
  final String title;
  final Widget? rightWidget;
  final VoidCallback onTap;
  const MenuOption({super.key, required this.icon, required this.title, this.rightWidget, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Row(
          children: [
            SvgPicture.asset(icon, width: 24.w, height: 24.w),
            12.horizontalSpace,
            AppText(
              title,
              style: AppStyle.text20.copyWith(fontWeight: FontWeight.w500, color: AppCustomColor.black36),
            ),
            const Spacer(),
            if (rightWidget != null) rightWidget!,
            Icon(Icons.chevron_right, size: 24.r, color: AppCustomColor.grey9A),
          ],
        ),
      ),
    );
  }
}

class AboutMenu extends StatelessWidget {
  const AboutMenu({super.key});

  Future<void> _launchURL(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      // Handle error - could show a snackbar or dialog
      debugPrint('Error launching URL: $e');
    } finally {
      if (context.mounted) {
        context.back();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColorLight.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppCustomColor.grey69.withValues(alpha: 0.2),
            blurRadius: 24.r,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 20.h),
      constraints: BoxConstraints(minWidth: 300.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with back button and title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                // GestureDetector(
                //   onTap: onBack,
                //   child: Container(
                //     width: 32.w,
                //     height: 32.w,
                //     alignment: Alignment.center,
                //     child: Icon(
                //       Icons.arrow_back_ios_new,
                //       size: 16.r,
                //       color: AppCustomColor.black36,
                //     ),
                //   ),
                // ),
                // 12.horizontalSpace,
                AppText(
                  'context.text.roadmapAbout',
                  style: AppStyle.textBold24.copyWith(color: AppCustomColor.black36),
                ),
              ],
            ),
          ),
          12.verticalSpace,
          Divider(color: AppCustomColor.greyE3, height: 1.h),
          12.verticalSpace,
          // Menu options
          Column(
            children: [
              AboutMenuOption(
                title: 'context.text.roadmapPrivacy',
                onTap: () => _launchURL('https://meup.com/privacy.html', context),
              ),
              4.verticalSpace,
              AboutMenuOption(
                title: 'context.text.roadmapTermsOfUse',
                onTap: () => _launchURL('https://meup.com/terms.html', context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AboutMenuOption extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const AboutMenuOption({
    super.key,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.w, horizontal: 20.w),
        width: double.infinity,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: Colors.transparent,
        ),
        child: AppText(
          title,
          style: AppStyle.text18.copyWith(
            fontWeight: FontWeight.w600,
            color: AppCustomColor.black36,
          ),
        ),
      ),
    );
  }
}
