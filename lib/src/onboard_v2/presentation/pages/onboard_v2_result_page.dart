part of '../../onboard_v2.dart';

/// S10 — 3 khoá gợi ý do server xếp hạng (§3.4), vuốt ngang, card đầu mang nhãn
/// "PHÙ HỢP NHẤT". Không lùi được: câu trả lời đã gửi, quay lại chỉ sinh ra một
/// lượt hỏi thừa.
class OnboardV2ResultPage extends StatefulWidget {
  const OnboardV2ResultPage({super.key});

  @override
  State<OnboardV2ResultPage> createState() => _OnboardV2ResultPageState();
}

class _OnboardV2ResultPageState extends State<OnboardV2ResultPage> {
  late final PageController _courseController;

  /// Chỉ bật khi user bấm "Thử lại" TỪ màn này. `recommendStatus == loading`
  /// một mình KHÔNG đủ để hiện spinner: trần 12 s của S9 đẩy user sang đây khi
  /// gợi ý vẫn đang chạy, mà spinner thì không có lối thoát.
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _courseController = PageController(viewportFraction: _p10CourseViewportFraction);
    // ATT request moved to OnboardV2Page's currentPage listener — PageView
    // pre-builds this page while p8→p9 is still animating, so firing it from
    // here ran the OS ATT prompt seconds after the user answered the
    // notification prompt on S8 (iOS commonly drops an ATT request made while
    // another system alert is dismissing). See OnboardV2Page._requestTrackingPermissionOnce.
  }

  @override
  void dispose() {
    _courseController.dispose();
    super.dispose();
  }

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
            12.verticalSpace,
            AppText(
              onbCopy(onboardData, 'onboardingV2P8Eyebrow', fallback: onboardingL10n.onboardingV2P8Eyebrow),
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textPrimary.op(0.5), height: 1.75),
            ),
            AppText(
              onbCopy(onboardData, 'onboardingV2P8Title', fallback: onboardingL10n.onboardingV2P8Title),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.visible,
              style: AppStyle.text20.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w700, height: 1.5),
            ),
            24.verticalSpace,
            if (_isRetrying)
              SizedBox(
                height: 340.w,
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (state.hasRecommendedCourses)
              _CourseCarousel(controller: _courseController, state: state)
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

const _p10CourseViewportFraction = 0.82;
const _p10SideCourseCardScale = 220 / 260;

class _CourseCarousel extends StatelessWidget {
  const _CourseCarousel({required this.controller, required this.state});

  final PageController controller;
  final OnboardV2State state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardV2Cubit>();
    final course = state.currentCourse;
    final isFirstCourse = state.currentCourseIndex == 0;
    final hasMultipleCourses = state.recommendedCourses.length > 1;
    return Column(
      children: [
        if (isFirstCourse) _BestMatchedLabel(onboardData: state.onboardData) else 21.verticalSpace,
        12.verticalSpace,
        SizedBox(
          height: 260.w,
          child: OverflowBox(
            minWidth: MediaQuery.sizeOf(context).width,
            maxWidth: MediaQuery.sizeOf(context).width,
            alignment: Alignment.center,
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width,
              height: 260.w,
              child: PageView.builder(
                key: const Key('onboard_v2_result_page_view'),
                controller: controller,
                itemCount: state.recommendedCourses.length,
                onPageChanged: cubit.setCurrentCourseIndex,
                itemBuilder: (context, index) {
                  final course = state.recommendedCourses[index];
                  return AnimatedBuilder(
                    animation: controller,
                    builder: (context, child) {
                      final page = controller.hasClients ? (controller.page ?? controller.initialPage.toDouble()) : state.currentCourseIndex.toDouble();
                      final distance = (page - index).abs().clamp(0.0, 1.0);
                      final scale = 1.0 - (distance * (1.0 - _p10SideCourseCardScale));
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: OnboardV2CoursePickerCard(course: course),
                  );
                },
              ),
            ),
          ),
        ),
        if (hasMultipleCourses) ...[
          12.verticalSpace,
          Row(
            key: const Key('onboard_v2_course_indicator_row'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(state.recommendedCourses.length, (index) {
              final active = index == state.currentCourseIndex;
              return AnimatedContainer(
                key: ValueKey('onboard_v2_course_indicator_$index'),
                duration: const Duration(milliseconds: 180),
                width: 8.w,
                height: 8.w,
                margin: EdgeInsets.symmetric(horizontal: 6.w),
                decoration: BoxDecoration(
                  color: active ? AppCustomColor.brandPrimary : AppCustomColor.borderSecondary,
                  borderRadius: BorderRadius.circular(100.r),
                ),
              );
            }),
          ),
        ],
        24.verticalSpace,
        if (course != null)
          _CurrentCourseText(
            course: course,
            // "Vì bạn muốn …" — chỉ hiện khi server nói khoá này khớp ĐÚNG mong
            // muốn user chọn ở câu 3, không phải khớp nhãn vấn đề.
            matchesDesire: state.matchReasons[course.id]?.desire ?? false,
          ),
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
        8.horizontalSpace,
        AppText(
          onbCopy(onboardData, 'onboardingV2P8Label', fallback: onboardingL10n.onboardingV2P8Label).toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 1,
          style: AppStyle.text12.copyWith(color: AppCustomColor.brandPrimary, fontWeight: FontWeight.w700, height: 1.75),
        ),
        8.horizontalSpace,
        _labelStar(),
      ],
    );
  }

  Widget _labelStar() {
    return Icon(Icons.star_rounded, size: 8.w, color: AppCustomColor.brandPrimary.op(0.35));
  }
}

class _CurrentCourseText extends StatelessWidget {
  const _CurrentCourseText({required this.course, required this.matchesDesire});

  final CourseEntity course;
  final bool matchesDesire;

  @override
  Widget build(BuildContext context) {
    final onboardingL10n = context.l10n.onboarding;
    final title = course.title.text.trim().isNotEmpty ? course.title.text.trim() : onboardingL10n.onboardingV2P8CourseTitleFallback;
    final description = course.description.text.trim();
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          AppText(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppStyle.text24.copyWith(color: AppCustomColor.textPrimary, fontWeight: FontWeight.w700, height: 1.5),
          ),
          if (description.isNotEmpty) ...[
            4.verticalSpace,
            AppText(
              description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.text14.copyWith(color: AppCustomColor.textSecondary, height: 1.75),
            ),
          ],
          if (matchesDesire) ...[
            8.verticalSpace,
            AppText(
              onboardingL10n.onboardingV3ResultReasonDesire,
              key: const Key('onboard_v2_result_reason_desire'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.visible,
              style: AppStyle.text12.copyWith(color: AppCustomColor.brandPrimary, fontWeight: FontWeight.w700, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _FallbackContent extends StatelessWidget {
  const _FallbackContent();

  @override
  Widget build(BuildContext context) {
    final onboardingL10n = context.l10n.onboarding;
    return SizedBox(
      height: 340.w,
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
