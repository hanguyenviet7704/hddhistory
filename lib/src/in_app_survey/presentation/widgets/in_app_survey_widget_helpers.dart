part of '../../in_app_survey.dart';

class _InAppSurveyColors {
  static const Color brandPrimary = Color(0xFF554FF0);
  static const Color brandText = Color(0xFF321DB5);
  static const Color brandWash = Color(0xFFF2F1FE);
  static const Color border = Color(0xFFEBF0F7);
  static const Color borderSecondary = Color(0xFFE3E8EF);
  static const Color textPrimary = Color(0xFF0D121C);
  static const Color textSecondary = Color(0xCC0D121C);
  static const Color textTertiary = Color(0x800D121C);
}

String _surveyText(BaseMultiLanguage? value) => value?.text.trim() ?? '';

BoxDecoration _surveyCardDecoration() {
  return BoxDecoration(
    color: _InAppSurveyColors.brandWash,
    borderRadius: BorderRadius.circular(20.r),
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFEDE8FE),
        _InAppSurveyColors.brandWash,
      ],
    ),
  );
}

class _InAppSurveyTitle extends StatelessWidget {
  const _InAppSurveyTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppText(
      text,
      forceHtmlRendering: true,
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.visible,
      style: AppStyle.textBold20.copyWith(
        color: _InAppSurveyColors.textPrimary,
        height: 1.5,
      ),
    );
  }
}

class _InAppSurveyGuide extends StatelessWidget {
  const _InAppSurveyGuide(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return AppText(
      text,
      forceHtmlRendering: true,
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.visible,
      style: AppStyle.text14.copyWith(
        color: _InAppSurveyColors.textTertiary,
        height: 1.75,
      ),
    );
  }
}

class _InAppSurveyPrimaryButton extends StatelessWidget {
  const _InAppSurveyPrimaryButton({
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: AppButton.primary(
        disabled: !enabled || isLoading,
        fullWidthBtn: true,
        height: 54.h,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        onPressed: enabled && !isLoading ? onPressed : null,
        child: isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : AppText(
                text,
                textAlign: TextAlign.center,
                maxLines: 1,
                enableFitScaleDown: true,
                style: AppStyle.textBold16.copyWith(color: Colors.white),
              ),
      ),
    );
  }
}

class _InAppSurveyRemoteGraphic extends StatelessWidget {
  const _InAppSurveyRemoteGraphic({
    required this.url,
    required this.size,
  });

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return SizedBox(width: size, height: size);

    final child = url.toLowerCase().endsWith('.svg')
        ? SvgPicture.network(
            url,
            width: size,
            height: size,
            fit: BoxFit.contain,
            placeholderBuilder: (_) => SizedBox(width: size, height: size),
          )
        : Image.network(
            url,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => SizedBox(width: size, height: size),
            loadingBuilder: (context, child, progress) => progress == null ? child : SizedBox(width: size, height: size),
          );

    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: child,
    );
  }
}
