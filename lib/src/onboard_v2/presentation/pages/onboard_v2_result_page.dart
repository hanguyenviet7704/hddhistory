part of '../../onboard_v2.dart';

/// S10 — 3 khoá gợi ý do server xếp hạng (§3.4), vuốt ngang trên một chồng thẻ,
/// thẻ đầu mang nhãn "PHÙ HỢP NHẤT". Không lùi được: câu trả lời đã gửi, quay
/// lại chỉ sinh ra một lượt hỏi thừa.
class OnboardV2ResultPage extends StatefulWidget {
  const OnboardV2ResultPage({super.key});

  @override
  State<OnboardV2ResultPage> createState() => _OnboardV2ResultPageState();
}

class _OnboardV2ResultPageState extends State<OnboardV2ResultPage> {
  /// Chỉ bật khi user bấm "Thử lại" TỪ màn này. `recommendStatus == loading`
  /// một mình KHÔNG đủ để hiện spinner: trần 12 s của S9 đẩy user sang đây khi
  /// gợi ý vẫn đang chạy, mà spinner thì không có lối thoát.
  bool _isRetrying = false;

  // ATT request moved to OnboardV2Page's currentPage listener — PageView
  // pre-builds this page while p8→p9 is still animating, so firing it from
  // here ran the OS ATT prompt seconds after the user answered the
  // notification prompt on S8 (iOS commonly drops an ATT request made while
  // another system alert is dismissing). See
  // OnboardV2Page._requestTrackingPermissionOnce.

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OnboardV2Cubit>().state;
    final onboardingL10n = context.l10n.onboarding;
    final onboardData = state.onboardData;
    return PopScope(
      canPop: false,
      child: OnboardV2ScreenShell(
        backgroundColor: AppCustomColor.backgroundWhite,
        cta: _buildCta(state, onboardingL10n),
        child: Column(
          children: [
            16.verticalSpace,
            AppText(
              onbCopy(onboardData, 'onboardingV2P8Eyebrow', fallback: onboardingL10n.onboardingV2P8Eyebrow),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.visible,
              style: AppStyle.text12.copyWith(
                fontSize: 11.sp,
                color: AppCustomColor.onboardMutedLabel,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.22,
                height: 1.4,
              ),
            ),
            8.verticalSpace,
            OnboardV2GradientHeading(
              prefix: onbCopy(onboardData, 'onboardingV3P10HeadingPrefix', fallback: onboardingL10n.onboardingV3P10HeadingPrefix),
              highlight: onbCopy(onboardData, 'onboardingV3P10HeadingHighlight', fallback: onboardingL10n.onboardingV3P10HeadingHighlight),
              textAlign: TextAlign.center,
              fontSize: 24,
              maxLines: 2,
            ),
            16.verticalSpace,
            if (_isRetrying)
              SizedBox(
                height: OnboardV2ResultCardDeck.deckHeight.h,
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (state.hasRecommendedCourses)
              _CourseDeckSection(state: state)
            else
              // Gồm cả trường hợp `recommendStatus == loading` do chạm trần 12 s
              // ở S9: vẫn phải là màn dự phòng có nút Thử lại.
              const _FallbackContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildCta(OnboardV2State state, Translations$onboarding$en onboardingL10n) {
    final onboardData = state.onboardData;
    final selectCta = onbCopy(onboardData, 'onboardingV3P10Cta', fallback: onboardingL10n.onboardingV3P10Cta);
    final course = state.currentCourse;

    if (!_isRetrying && course != null && course.id.isNotEmpty) {
      return OnboardV2BottomCta(
        label: selectCta,
        onPressed: () => context.read<OnboardV2Cubit>().goToThemeWithCourse(course),
        hasGlow: true,
      );
    }

    return OnboardV2BottomCta(
      label: onboardingL10n.onboardingV2RetryCta,
      isLoading: _isRetrying,
      onPressed: () => unawaited(_handleRetry()),
      secondaryLabel: onbCopy(onboardData, 'onboardingV2P8CatalogCta', fallback: onboardingL10n.onboardingV2P8CatalogCta),
      onSecondaryPressed: () => context.read<OnboardV2Cubit>().goToThemeWithoutCourse(),
    );
  }

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    await context.read<OnboardV2Cubit>().retryRecommendation();
    if (!mounted) return;
    setState(() => _isRetrying = false);
  }
}

class _CourseDeckSection extends StatelessWidget {
  const _CourseDeckSection({required this.state});

  final OnboardV2State state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardV2Cubit>();
    final course = state.currentCourse;
    final isFirstCourse = state.currentCourseIndex == 0;
    final hasMultipleCourses = state.recommendedCourses.length > 1;
    // Server nói khoá này khớp ĐÚNG mong muốn user chọn ở câu 3, không phải
    // khớp nhãn vấn đề.
    final matchesDesire = course != null && (state.matchReasons[course.id]?.desire ?? false);

    return Column(
      children: [
        SizedBox(
          height: 28.h,
          child: isFirstCourse ? _BestMatchedLabel(onboardData: state.onboardData) : null,
        ),
        14.verticalSpace,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 26.w),
          child: OnboardV2ResultCardDeck(
            courses: state.recommendedCourses,
            currentIndex: state.currentCourseIndex,
            onIndexChanged: cubit.setCurrentCourseIndex,
          ),
        ),
        if (hasMultipleCourses) ...[
          26.verticalSpace,
          Row(
            key: const Key('onboard_v2_course_indicator_row'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(state.recommendedCourses.length, (index) {
              final active = index == state.currentCourseIndex;
              return AnimatedContainer(
                key: ValueKey('onboard_v2_course_indicator_$index'),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: active ? 20.w : 7.w,
                height: 7.w,
                margin: EdgeInsets.symmetric(horizontal: 3.5.w),
                decoration: BoxDecoration(
                  color: active ? AppCustomColor.brandPrimary : AppCustomColor.onboardDotIdle,
                  borderRadius: BorderRadius.circular(99.r),
                ),
              );
            }),
          ),
        ],
        if (matchesDesire) ...[
          14.verticalSpace,
          AppText(
            context.l10n.onboarding.onboardingV3ResultReasonDesire,
            key: const Key('onboard_v2_result_reason_desire'),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.visible,
            style: AppStyle.text12.copyWith(color: AppCustomColor.brandPrimary, fontWeight: FontWeight.w700, height: 1.5),
          ),
        ],
        14.verticalSpace,
      ],
    );
  }
}

class _BestMatchedLabel extends StatelessWidget {
  const _BestMatchedLabel({required this.onboardData});

  final OnboardEntity onboardData;

  @override
  Widget build(BuildContext context) {
    final onboardingL10n = context.l10n.onboarding;
    return Row(
      key: const Key('onboard_v2_course_best_matched_label'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _labelStar(),
        9.horizontalSpace,
        AppText(
          onbCopy(onboardData, 'onboardingV2P8Label', fallback: onboardingL10n.onboardingV2P8Label).toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 1,
          style: AppStyle.text14.copyWith(
            color: AppCustomColor.brandPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.56,
            height: 1.4,
          ),
        ),
        9.horizontalSpace,
        _labelStar(),
      ],
    );
  }

  Widget _labelStar() => Icon(Icons.star_rounded, size: 12.w, color: const Color(0xFF8B85E8));
}

class _FallbackContent extends StatelessWidget {
  const _FallbackContent();

  @override
  Widget build(BuildContext context) {
    final onboardingL10n = context.l10n.onboarding;
    return SizedBox(
      height: OnboardV2ResultCardDeck.deckHeight.h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded, size: 80.w, color: AppCustomColor.brandPrimary),
          24.verticalSpace,
          AppText(
            onboardingL10n.onboardingV2P8FallbackTitle,
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
            style: AppStyle.text24.copyWith(color: AppCustomColor.textBrand, fontWeight: FontWeight.w800),
          ),
          12.verticalSpace,
          AppText(
            onboardingL10n.onboardingV2P8FallbackCopy,
            textAlign: TextAlign.center,
            overflow: TextOverflow.visible,
            style: AppStyle.text16.copyWith(color: AppCustomColor.textSecondary),
          ),
        ],
      ),
    );
  }
}
