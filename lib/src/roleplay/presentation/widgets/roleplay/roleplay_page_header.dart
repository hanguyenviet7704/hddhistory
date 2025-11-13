part of '../../../roleplay.dart';

class RoleplayPageHeader extends StatelessWidget {
  final SectionEntity section;
  final bool useLightContent;

  const RoleplayPageHeader({
    super.key,
    required this.section,
    required this.useLightContent,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = useLightContent ? AppCustomColor.textWhite : AppCustomColor.textPrimary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _RoleplayBackButton(isLight: useLightContent),
        16.horizontalSpace,
        AppText(
          section.title,
          maxLines: 2,
          style: AppStyle.text20.copyWith(
            fontWeight: FontWeight.w700,
            color: textColor,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _RoleplayBackButton extends StatelessWidget {
  final bool isLight;

  const _RoleplayBackButton({required this.isLight});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Icon(
        FontAwesomeIcons.arrowLeftLong,
        size: 18.w,
        color: isLight ? Colors.white : AppCustomColor.textPrimary,
      ),
    );
  }
}
