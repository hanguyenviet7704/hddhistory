part of '../../output_practice.dart';

class OutputPracticeIntroSheet extends StatefulWidget {
  const OutputPracticeIntroSheet({
    super.key,
    required this.lesson,
    required this.sectionId,
    required this.isPremium,
    required this.trackingData,
    required this.onStart,
  });

  final LessonEntity lesson;
  final String sectionId;
  final bool isPremium;
  final CourseLessonTrackingData? trackingData;
  final VoidCallback onStart;

  static Future<void> show(
    BuildContext context, {
    required LessonEntity lesson,
    required String sectionId,
    required bool isPremium,
    required CourseLessonTrackingData? trackingData,
    required VoidCallback onStart,
  }) async {
    var didStart = false;
    await showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierLabel: 'output-practice-intro-sheet',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, _) => OutputPracticeIntroSheet(
        lesson: lesson,
        sectionId: sectionId,
        isPremium: isPremium,
        trackingData: trackingData,
        onStart: () {
          didStart = true;
          if (trackingData != null && AppDI.injector.isRegistered<ITrackingService>()) {
            AppService.instance.appTrackingService.trackOutputPracticeStartClick(
              trackingData,
              sectionId: sectionId,
            );
          }
          dialogContext.pop();
          onStart();
        },
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
    if (!didStart && trackingData != null && AppDI.injector.isRegistered<ITrackingService>()) {
      AppService.instance.appTrackingService.trackOutputPracticePopupClose(
        trackingData,
        sectionId: sectionId,
      );
    }
  }

  @override
  State<OutputPracticeIntroSheet> createState() => _OutputPracticeIntroSheetState();
}

class _OutputPracticeIntroSheetState extends State<OutputPracticeIntroSheet> {
  static const _usageTransitionDuration = Duration(milliseconds: 180);
  OutputPracticeConversationUsageEntity? _usage;
  bool _isLoadingUsage = true;
  bool _hasUsageError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackPopupView();
      _loadUsage();
    });
  }

  bool get _isUnlimitedAccess {
    if (!widget.isPremium) return false;
    if (!AppDI.injector.isRegistered<IRemoteConfigService>()) return false;
    return AppService.instance.remoteConfigService.courseConfig.enablePremiumUnlimitedPractice;
  }

  Future<void> _loadUsage() async {
    if (!AppDI.injector.isRegistered<GetOutputPracticeConversationUsageUseCase>()) {
      if (!mounted) return;
      setState(() {
        _isLoadingUsage = false;
        _hasUsageError = true;
      });
      return;
    }

    final result = await AppDI.injector.get<GetOutputPracticeConversationUsageUseCase>()(widget.sectionId).run();
    if (!mounted) return;

    result.fold(
      (_) {
        setState(() {
          _isLoadingUsage = false;
          _hasUsageError = true;
        });
      },
      (usage) {
        setState(() {
          _usage = usage;
          _isLoadingUsage = false;
          _hasUsageError = false;
        });
      },
    );
  }

  void _trackPopupView() {
    if (widget.trackingData == null || !AppDI.injector.isRegistered<ITrackingService>()) {
      return;
    }
    AppService.instance.appTrackingService.trackOutputPracticePopupView(
      widget.trackingData!,
      sectionId: widget.sectionId,
    );
  }

  InlineSpan? _usageSpan(BuildContext context) {
    final copy = context.l10n.outputPractice;
    final usageTextStyle = AppStyle.text14.copyWith(
      color: const Color(0xFF94762A),
      height: 1.75,
    );

    if (_isLoadingUsage) return null;
    if (_hasUsageError) return null;
    if (_isUnlimitedAccess) {
      return TextSpan(
        text: copy.introUsageUnlimited,
        style: usageTextStyle.copyWith(fontWeight: FontWeight.w700),
      );
    }

    final usage = _usage;
    if (usage == null) return null;
    if (usage.hasReachedLimit) {
      return TextSpan(
        text: copy.introUsageReachedLimit,
        style: usageTextStyle.copyWith(fontWeight: FontWeight.w700),
      );
    }

    return TextSpan(
      children: [
        TextSpan(
          text: copy.introUsageRemaining(remaining: usage.remainingInThisMonth),
          style: usageTextStyle.copyWith(fontWeight: FontWeight.w700),
        ),
        if (copy.introUsageRemainingSuffix.isNotEmpty)
          TextSpan(
            text: ' ${copy.introUsageRemainingSuffix}',
            style: usageTextStyle,
          ),
      ],
    );
  }

  Widget _buildUsageSlot(BuildContext context, InlineSpan? usageSpan) {
    final usageSlotHeight = 24.h;

    return AnimatedSwitcher(
      duration: _usageTransitionDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return SizedBox(
          height: usageSlotHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ...previousChildren,
              ?currentChild,
            ],
          ),
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _isLoadingUsage
          ? Center(
              key: const ValueKey('output_practice_intro_usage_loading'),
              child: Container(
                width: 156.w,
                height: 10.h,
                decoration: BoxDecoration(
                  color: const Color(0x1F94762A),
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
            )
          : usageSpan == null
          ? const SizedBox(
              key: ValueKey('output_practice_intro_usage_empty'),
            )
          : Center(
              child: Text.rich(
                key: const ValueKey('output_practice_intro_usage_ready'),
                usageSpan,
                textAlign: TextAlign.center,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n.outputPractice;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final usageSpan = _usageSpan(context);
    final shouldShowUsageSlot = _isLoadingUsage || usageSpan != null;
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.pop(),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: const ColoredBox(
                    color: Color(0x99364152),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                  ),
                  6.verticalSpace,
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      20.w,
                      20.h,
                      20.w,
                      (bottomInset > 0 ? bottomInset : 0) + 20.h,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppText(
                          widget.lesson.title.text,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: AppStyle.textBold24.copyWith(
                            color: AppCustomColor.textPrimary,
                            height: 1.5,
                          ),
                        ),
                        4.verticalSpace,
                        AppText(
                          copy.practiceLabel.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: AppStyle.text12.copyWith(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppCustomColor.textTertiary,
                            height: 1.75,
                          ),
                        ),
                        12.verticalSpace,
                        AppText(
                          widget.lesson.description.text,
                          maxLines: 100,
                          style: AppStyle.text14.copyWith(
                            color: AppCustomColor.textSecondary,
                            height: 1.75,
                          ),
                        ),
                        if (shouldShowUsageSlot) ...[
                          16.verticalSpace,
                          _buildUsageSlot(context, usageSpan),
                        ],
                        24.verticalSpace,
                        AppButton.primary(
                          onPressed: _isLoadingUsage ? null : widget.onStart,
                          fullWidthBtn: true,
                          height: 54.h,
                          borderRadius: BorderRadius.circular(1000.r),
                          child: Text(
                            copy.startPracticeButton,
                            textAlign: TextAlign.center,
                            style: AppStyle.textBold16.copyWith(
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
