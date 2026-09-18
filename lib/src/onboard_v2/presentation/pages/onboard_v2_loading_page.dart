part of '../../onboard_v2.dart';

/// S9 — màn "đang chọn khoá cho bạn". Không header, không CTA: chỉ 4 dòng tick
/// hiện lần lượt trong lúc `POST /onboarding-answers` chạy.
///
/// Điều kiện sang S10: đã hiện ít nhất 2,4 s VÀ gợi ý không còn `loading`.
/// Trần 12 s — quá thì vẫn sang, S10 tự hiện màn dự phòng + Thử lại, tốt hơn
/// là để user ngồi nhìn spinner vô hạn.
class OnboardV2LoadingPage extends StatefulWidget {
  const OnboardV2LoadingPage({super.key});

  @override
  State<OnboardV2LoadingPage> createState() => _OnboardV2LoadingPageState();
}

class _OnboardV2LoadingPageState extends State<OnboardV2LoadingPage> {
  static const _minDuration = Duration(milliseconds: 2400);
  static const _maxDuration = Duration(seconds: 12);
  static const _lineStep = Duration(milliseconds: 500);
  static const _lineCount = 4;

  late DateTime _startedAt;
  int _visibleLines = 0;

  @override
  void initState() {
    super.initState();
    _startedAt = context.read<OnboardV2Cubit>().state.loadingStartedAt ?? DateTime.now();
    for (var i = 0; i < _lineCount; i++) {
      unawaited(_revealLine(i));
    }
    unawaited(_scheduleMinimumHold());
    unawaited(_scheduleTimeout());
  }

  Future<void> _revealLine(int index) async {
    if (index > 0) await Future<void>.delayed(_lineStep * index);
    if (!mounted || _visibleLines > index) return;
    setState(() => _visibleLines = index + 1);
  }

  Future<void> _scheduleMinimumHold() async {
    final elapsed = DateTime.now().difference(_startedAt);
    final remaining = _minDuration - elapsed;
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
    _tryFinish();
  }

  Future<void> _scheduleTimeout() async {
    final elapsed = DateTime.now().difference(_startedAt);
    final remaining = _maxDuration - elapsed;
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
    if (!mounted) return;
    context.read<OnboardV2Cubit>().finishLoading();
  }

  void _tryFinish() {
    if (!mounted) return;
    final cubit = context.read<OnboardV2Cubit>();
    if (cubit.state.currentPage != OnboardV2PageStep.p9Loading) return;
    if (DateTime.now().difference(_startedAt) < _minDuration) return;
    if (cubit.state.recommendStatus == OnboardV2RecommendStatus.loading) return;
    cubit.finishLoading();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingL10n = context.l10n.onboarding;
    final onboardData = context.select<OnboardV2Cubit, OnboardEntity>((cubit) => cubit.state.onboardData);
    final lines = [
      onbCopy(onboardData, 'onboardingV3P9Line1', fallback: onboardingL10n.onboardingV3P9Line1),
      onbCopy(onboardData, 'onboardingV3P9Line2', fallback: onboardingL10n.onboardingV3P9Line2),
      onbCopy(onboardData, 'onboardingV3P9Line3', fallback: onboardingL10n.onboardingV3P9Line3),
      onbCopy(onboardData, 'onboardingV3P9Line4', fallback: onboardingL10n.onboardingV3P9Line4),
    ];

    return BlocListener<OnboardV2Cubit, OnboardV2State>(
      listenWhen: (previous, current) => previous.recommendStatus != current.recommendStatus,
      listener: (_, _) => _tryFinish(),
      child: PopScope(
        canPop: false,
        child: OnboardV2ScreenShell(
          cta: const SizedBox.shrink(),
          child: Column(
            children: [
              72.verticalSpace,
              SizedBox(
                width: 44.w,
                height: 44.w,
                child: CircularProgressIndicator(strokeWidth: 3.w, color: AppCustomColor.brandPrimary),
              ),
              32.verticalSpace,
              AppText(
                onbCopy(onboardData, 'onboardingV3P9HeadingPrefix', fallback: onboardingL10n.onboardingV3P9HeadingPrefix),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.visible,
                style: AppStyle.text28.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w800, height: 1.4),
              ),
              OnboardV2GradientText(
                onbCopy(onboardData, 'onboardingV3P9HeadingHighlight', fallback: onboardingL10n.onboardingV3P9HeadingHighlight),
                textAlign: TextAlign.center,
                style: AppStyle.text28.copyWith(fontWeight: FontWeight.w800, height: 1.4),
              ),
              40.verticalSpace,
              for (var i = 0; i < lines.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: AnimatedOpacity(
                    key: ValueKey('onboard_v2_loading_line_$i'),
                    opacity: i < _visibleLines ? 1 : 0,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOut,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22.w,
                          height: 22.w,
                          decoration: BoxDecoration(color: AppCustomColor.brandPrimary, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Icon(Icons.check_rounded, size: 14.w, color: AppCustomColor.textWhite),
                        ),
                        10.horizontalSpace,
                        Flexible(
                          child: AppText(
                            lines[i],
                            maxLines: 2,
                            overflow: TextOverflow.visible,
                            style: AppStyle.text16.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
