part of '../../../../exercise.dart';

enum ResultType { correct, incorrect }

class ResultBottomSheet extends StatelessWidget {
  final ResultType type;
  final VoidCallback onContinue;
  final VoidCallback? onExplain;

  const ResultBottomSheet({super.key, required this.type, required this.onContinue, this.onExplain});

  bool get isCorrect => type == ResultType.correct;
  Color get backgroundColor => isCorrect ? const Color(0xFFEAFFEF) : const Color(0xFFFDEAE7);
  Color get buttonColor => isCorrect ? const Color(0xFF1DA75E) : const Color(0xFFE34646);
  Color get iconColor => isCorrect ? const Color(0xFF1DA75E) : const Color(0xFFE34646);
  String get title => isCorrect ? 'Correct answer!' : 'Incorrect';
  String get iconAsset => isCorrect ? AppAsset.icons.app.icTick.path : AppAsset.icons.app.icClose.path;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Image.asset(iconAsset, width: 24.w, height: 24.w),
                    8.horizontalSpace,
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(color: iconColor, fontSize: 16, fontWeight: FontWeight.w600, height: 1.5),
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
                        SvgPicture.asset(AppAsset.svg.app.icBook, width: 20.w, height: 20.w),
                        8.horizontalSpace,
                        AppText(
                          'Explain',
                          style: AppStyle.text14.copyWith(color: const Color(0xFF0D121C), fontWeight: FontWeight.w600),
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
            height: 54,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1000)),
              ),
              child: AppText(
                context.text.onboardingSkipGreetingButton,
                style: AppStyle.text16.copyWith(fontWeight: FontWeight.w600, color: AppColorLight.surface),
              ),
            ),
          ),
          16.verticalSpace,
        ],
      ),
    );
  }
}
