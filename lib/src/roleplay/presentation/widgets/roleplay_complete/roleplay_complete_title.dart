part of '../../../roleplay.dart';

class RoleplayCompleteTitle extends StatelessWidget {
  final String text;

  const RoleplayCompleteTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return AppText(
      text,
      maxLines: 1,
      textAlign: TextAlign.center,
      style: AppStyle.textBold32.copyWith(
        color: AppCustomColor.textPrimary,
        height: 1.25,
      ),
    );
  }
}
