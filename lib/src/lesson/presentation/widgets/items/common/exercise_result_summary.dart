part of '../../../../lesson.dart';

enum ResultType { correct, incorrect }

class ExerciseResultSummary extends StatelessWidget {
  final ResultType type;
  final VoidCallback onContinue;
  final VoidCallback? onExplain;
  final bool showExplanation;
  final String continueLabel;
  final String explainLabel;
  final String closeExplainLabel;
  final String? title;
  final Color? successAccentColor;
  final Color? errorAccentColor;
  final Color? successBackgroundColor;
  final Color? errorBackgroundColor;

  const ExerciseResultSummary({
    super.key,
    required this.type,
    required this.onContinue,
    this.onExplain,
    this.showExplanation = false,
    required this.continueLabel,
    required this.explainLabel,
    required this.closeExplainLabel,
    this.title,
    this.successAccentColor,
    this.errorAccentColor,
    this.successBackgroundColor,
    this.errorBackgroundColor,
  });

  bool get isCorrect => type == ResultType.correct;

  Color get _resolvedAccentColor => isCorrect ? (successAccentColor ?? const Color(0xFF1DA75E)) : (errorAccentColor ?? const Color(0xFFE34646));

  Color get _resolvedBackgroundColor => isCorrect ? (successBackgroundColor ?? const Color(0xFFEAFFEF)) : (errorBackgroundColor ?? const Color(0xFFFDEAE7));

  String _resolveTitle(BuildContext context) {
    if (title != null) return title!;
    return isCorrect ? context.text.exerciseFeedbackCorrect : context.text.exerciseFeedbackIncorrect;
  }

  String get _iconAsset => isCorrect ? AppAsset.icons.app.icTick.path : AppAsset.icons.app.icClose.path;

  @override
  Widget build(BuildContext context) {
    final explainText = showExplanation ? closeExplainLabel : explainLabel;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: _resolvedBackgroundColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Image.asset(_iconAsset, width: 24.w, height: 24.w),
                    8.horizontalSpace,
                    Expanded(
                      child: AppText(
                        _resolveTitle(context),
                        style: AppStyle.text16.copyWith(
                          color: _resolvedAccentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onExplain != null)
                Opacity(
                  opacity: 0.5,
                  child: GestureDetector(
                    onTap: onExplain,
                    child: Row(
                      children: [
                        showExplanation
                            ? Icon(Icons.close_rounded, color: const Color(0xFF0D121C), size: 20.w)
                            : SvgPicture.asset(
                                AppAsset.svg.app.icBookOpen,
                                width: 20.w,
                                height: 20.w,
                              ),
                        8.horizontalSpace,
                        AppText(
                          explainText,
                          style: AppStyle.text14.copyWith(
                            color: const Color(0xFF0D121C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          24.verticalSpace,
          SizedBox(
            width: double.infinity,
            height: 54.h,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: _resolvedAccentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1000.r),
                ),
              ),
              child: AppText(
                continueLabel,
                style: AppStyle.text16.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColorLight.surface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
