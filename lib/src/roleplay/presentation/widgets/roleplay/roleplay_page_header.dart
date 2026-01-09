part of '../../../roleplay.dart';

class RoleplayPageHeader extends StatelessWidget {
  final bool useLightContent;
  final String title;

  const RoleplayPageHeader({
    super.key,
    required this.useLightContent,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = useLightContent ? AppCustomColor.textWhite : AppCustomColor.textPrimary;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _RoleplayBackButton(isLight: useLightContent),
          AppText(
            title,
            maxLines: 2,
            style: AppStyle.text20.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.3,
            ),
          ),
          SizedBox(width: 18.w),
        ],
      ),
    );
  }
}

class _RoleplayBackButton extends StatelessWidget {
  final bool isLight;

  const _RoleplayBackButton({required this.isLight});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => CourseRoadmapRoute().go(context),
      icon: Icon(
        FontAwesomeIcons.xmark,
        size: 18.w,
        color: isLight ? Colors.white : AppCustomColor.textPrimary,
      ),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.w),
      splashRadius: 24.r,
    );
  }
}
