part of '../../../onboard_branching.dart';

class OnboardBranchingLoadingView extends StatefulWidget {
  const OnboardBranchingLoadingView({
    super.key,
    required this.onCompleted,
  });

  final VoidCallback onCompleted;

  @override
  State<OnboardBranchingLoadingView> createState() => _OnboardBranchingLoadingViewState();
}

class _OnboardBranchingLoadingViewState extends State<OnboardBranchingLoadingView> {
  Timer? _timer;
  bool _didComplete = false;
  static const double _targetProgress = 1;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), _finishOnce);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _finishOnce() {
    if (_didComplete) return;
    _didComplete = true;
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 36.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: _targetProgress),
            duration: const Duration(seconds: 3),
            builder: (context, value, _) {
              final percent = (value * 100).round();
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 135.w,
                    height: 135.w,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 12,
                      backgroundColor: const Color(0x4DFFFFFF),
                      color: Colors.white,
                    ),
                  ),
                  AppText(
                    '$percent%',
                    style: AppStyle.textBold24.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              );
            },
          ),
          32.verticalSpace,
          AppText(
            context.text.onboarding.onboardingLoadingPersonalizationText,
            textAlign: TextAlign.center,
            maxLines: 3,
            style: AppStyle.text14.copyWith(
              color: const Color(0xCCFFFFFF),
            ),
          ),
          4.verticalSpace,
          AppText(
            context.text.onboarding.onboardingBranchingLoadingSubtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppStyle.textBold20.copyWith(
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
