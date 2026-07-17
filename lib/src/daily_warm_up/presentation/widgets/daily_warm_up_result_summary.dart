part of '../../daily_warm_up.dart';

class DailyWarmUpResultSummary extends StatelessWidget {
  const DailyWarmUpResultSummary({
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

  bool get _isCorrect => type == ResultType.correct;

  Color get _accentColor => _isCorrect ? (successAccentColor ?? const Color(0xFF1DA75E)) : (errorAccentColor ?? const Color(0xFFE34646));

  Color get _backgroundColor => _isCorrect ? (successBackgroundColor ?? const Color(0xFFEAFFEF)) : (errorBackgroundColor ?? const Color(0xFFFDEAE7));

  String get _iconAsset => _isCorrect ? AppAsset.icons.app.icTick.path : AppAsset.icons.app.icClose.path;

  String _resolvedTitle(BuildContext context) {
    if (title != null) return title!;
    return _isCorrect ? context.l10n.exercise.exerciseFeedbackCorrect : context.l10n.exercise.exerciseFeedbackIncorrect;
  }

  @override
  Widget build(BuildContext context) {
    final explainText = showExplanation ? closeExplainLabel : explainLabel;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 35.h + MediaQuery.viewPaddingOf(context).bottom),
      color: _backgroundColor,
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
                        _resolvedTitle(context),
                        maxLines: 2,
                        style: AppStyle.text16.copyWith(
                          color: _accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onExplain != null) ...[
                12.horizontalSpace,
                Flexible(
                  child: GestureDetector(
                    key: const ValueKey('daily-warm-up-result-explain-action'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      AppHaptic.select();
                      onExplain!();
                    },
                    child: SizedBox(
                      height: 24.h,
                      child: Opacity(
                        opacity: 0.5,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            showExplanation
                                ? Icon(Icons.close_rounded, color: const Color(0xFF0D121C), size: 20.w)
                                : SvgPicture.asset(
                                    AppAsset.svg.app.icBookOpen,
                                    width: 20.w,
                                    height: 20.w,
                                  ),
                            8.horizontalSpace,
                            Flexible(
                              child: AppText(
                                explainText,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: AppStyle.text14.copyWith(
                                  color: const Color(0xFF0D121C),
                                  fontWeight: FontWeight.w600,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          24.verticalSpace,
          SizedBox(
            width: double.infinity,
            height: 54.h,
            child: ElevatedButton(
              onPressed: () {
                AppHaptic.select();
                onContinue();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1000.r),
                ),
              ),
              child: AppText(
                continueLabel,
                maxLines: 1,
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
