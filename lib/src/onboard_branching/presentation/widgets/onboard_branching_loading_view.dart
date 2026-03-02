part of '../../onboard_branching.dart';

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
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 56.w,
            height: 56.w,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF554FF0),
            ),
          ),
          24.verticalSpace,
          AppText(
            context.text.onboarding.onboardingLoadingPersonalizationText,
            textAlign: TextAlign.center,
            maxLines: 3,
            style: AppStyle.text16.copyWith(
              color: const Color(0xFF364152),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
