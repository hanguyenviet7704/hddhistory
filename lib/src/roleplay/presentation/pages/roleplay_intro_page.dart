part of '../../roleplay.dart';

class RoleplayIntroPage extends StatelessWidget {
  const RoleplayIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: BlocBuilder<RoleplayCubit, RoleplayState>(
          buildWhen: (previous, current) =>
              previous.status != current.status || previous.currentLearningItem != current.currentLearningItem || previous.errorMessage != current.errorMessage,
          builder: (context, state) {
            switch (state.status) {
              case RoleplayStatus.initial:
              case RoleplayStatus.loading:
                return const _RoleplayIntroLoading();
              case RoleplayStatus.failure:
                return _RoleplayIntroError(message: state.errorMessage);
              case RoleplayStatus.success:
                return _RoleplayIntroView();
            }
          },
        ),
      ),
    );
  }
}

class _RoleplayIntroView extends StatefulWidget {
  const _RoleplayIntroView();

  @override
  State<_RoleplayIntroView> createState() => _RoleplayIntroViewState();
}

class _RoleplayIntroViewState extends State<_RoleplayIntroView> {
  late final ValueNotifier<int> _stepNotifier = ValueNotifier<int>(0);
  late final ScrollController _scrollController = ScrollController();
  bool _hasTrackedInfoView = false;
  bool _hasTrackedMissionsView = false;
  bool _hasTrackedInfoScroll = false;
  bool _hasTrackedInfoScrollBottom = false;
  bool _hasTrackedMissionsScroll = false;
  bool _hasTrackedMissionsScrollBottom = false;

  RoleplayEntity get _roleplay => context.read<RoleplayCubit>().state.currentRoleplay;
  bool get _hasMissions => _roleplay.missions.isNotEmpty;
  bool get _isMissionsStep => _hasMissions && _stepNotifier.value == 1;

  void _handleCta() {
    final bool showMissions = _hasMissions && _stepNotifier.value == 1;
    final trackingData = RoleplayTrackingData.fromContext();

    if (showMissions || !_hasMissions) {
      if (_stepNotifier.value == 0 && trackingData != null) {
        AppService.instance.appTrackingService.trackRoleplayInfoContinueClick(trackingData);
      }
      if (trackingData != null) {
        AppService.instance.appTrackingService.trackRoleplayStartClick(trackingData);
      }
      RoleplayRoute().go(context);
      return;
    }
    if (trackingData != null) {
      AppService.instance.appTrackingService.trackRoleplayInfoContinueClick(trackingData);
    }
    _stepNotifier.value = 1;
  }

  void _handleStepChange() {
    if (_stepNotifier.value != 1) return;
    if (_hasTrackedMissionsView) return;
    final trackingData = RoleplayTrackingData.fromContext();
    if (trackingData == null) return;
    AppService.instance.appTrackingService.trackRoleplayMissionsView(trackingData);
    _hasTrackedMissionsView = true;
  }

  void _trackInfoViewIfNeeded() {
    if (_hasTrackedInfoView) return;
    final trackingData = RoleplayTrackingData.fromContext();
    if (trackingData == null) return;
    AppService.instance.appTrackingService.trackRoleplayInfoScrView(trackingData);
    _hasTrackedInfoView = true;
  }

  void _trackScrollIfNeeded() {
    if (!_scrollController.hasClients) return;
    final trackingData = RoleplayTrackingData.fromContext();
    if (trackingData == null) return;
    final position = _scrollController.position;

    if (_isMissionsStep) {
      if (!_hasTrackedMissionsScroll && position.userScrollDirection != ScrollDirection.idle) {
        AppService.instance.appTrackingService.trackRoleplayMissionsScroll(trackingData);
        _hasTrackedMissionsScroll = true;
      }
      if (!_hasTrackedMissionsScrollBottom && position.pixels >= position.maxScrollExtent - 16) {
        AppService.instance.appTrackingService.trackRoleplayMissionsScroll(trackingData);
        _hasTrackedMissionsScrollBottom = true;
      }
      return;
    }

    if (!_hasTrackedInfoScroll && position.userScrollDirection != ScrollDirection.idle) {
      AppService.instance.appTrackingService.trackRoleplayOverviewScroll(trackingData);
      _hasTrackedInfoScroll = true;
    }
    if (!_hasTrackedInfoScrollBottom && position.pixels >= position.maxScrollExtent - 16) {
      AppService.instance.appTrackingService.trackRoleplayOverviewScroll(trackingData);
      _hasTrackedInfoScrollBottom = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_trackScrollIfNeeded);
    _stepNotifier.addListener(_handleStepChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackInfoViewIfNeeded());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_trackScrollIfNeeded)
      ..dispose();
    _stepNotifier.removeListener(_handleStepChange);
    _stepNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        BlocSelector<RoleplayCubit, RoleplayState, String>(
          selector: (state) => state.currentLesson.image,
          builder: (context, imageUrl) {
            return RoleplayIntroBackground(imageUrl: imageUrl);
          },
        ),
        SafeArea(
          child: Column(
            children: [
              _RoleplayIntroHeader(onClose: () => context.pop()),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 20.w).copyWith(bottom: 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      12.verticalSpace,
                      Align(
                        alignment: Alignment.center,
                        child: BlocSelector<RoleplayCubit, RoleplayState, String>(
                          selector: (state) => state.currentLesson.image,
                          builder: (context, imageUrl) {
                            return RoleplayIntroHeroCard(imageUrl: imageUrl);
                          },
                        ),
                      ),
                      24.verticalSpace,
                      ValueListenableBuilder<int>(
                        valueListenable: _stepNotifier,
                        builder: (context, step, _) {
                          final bool showMissions = _hasMissions && step == 1;

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: showMissions
                                ? RoleplayIntroMissions(
                                    key: const ValueKey('missions'),
                                    missions: _roleplay.missions,
                                  )
                                : RoleplayIntroDetails(
                                    key: const ValueKey('details'),
                                  ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: _stepNotifier,
                builder: (context, step, _) {
                  final bool showMissions = _hasMissions && step == 1;
                  return RoleplayIntroActionButton(
                    label: showMissions ? context.l10n.roleplay.rolePlayIntroStartButton : context.l10n.common.kContinue,
                    onPressed: _handleCta,
                  );
                },
              ),
              SizedBox(height: 16.h + MediaQuery.paddingOf(context).bottom),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleplayIntroHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _RoleplayIntroHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            AppHaptic.select();
            final trackingData = RoleplayTrackingData.fromContext();
            if (trackingData != null) {
              AppService.instance.appTrackingService.trackRoleplayOverviewExitClick(trackingData);
            }
            onClose();
          },
          child: SvgPicture.asset(
            AppAsset.svg.app.icClose,
            width: 24.w,
            height: 24.w,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

class _RoleplayIntroLoading extends StatelessWidget {
  const _RoleplayIntroLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _RoleplayIntroError extends StatelessWidget {
  final String? message;

  const _RoleplayIntroError({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              message ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: AppStyle.text18.copyWith(color: AppCustomColor.textWhite),
            ),
            16.verticalSpace,
            DButton(
              onPressed: () => context.pop(),
              text: 'Try again',
              size: Size(180.w, 48.h),
              backgroundColor: AppCustomColor.brandPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ],
        ),
      ),
    );
  }
}
