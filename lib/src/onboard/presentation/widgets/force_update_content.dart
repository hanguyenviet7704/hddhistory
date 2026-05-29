part of '../../onboard.dart';

class ForceUpdateContent extends StatelessWidget {
  final VoidCallback? onUpdatePressed;

  const ForceUpdateContent({
    super.key,
    this.onUpdatePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          'Atualização necessária',
          style: AppStyle.textBold32.copyWith(
            color: const Color(0xFF0D121C),
            height: 40.h / 32.sp,
          ),
        ),
        AppText(
          'Atualização necessária',
          style: AppStyle.text20.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF364152),
            height: 32.h / 20.sp,
          ),
        ),

        DButton(
          onPressed: onUpdatePressed,
          customChild: AppText(
            'Atualizar',
            style: AppStyle.text20.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
