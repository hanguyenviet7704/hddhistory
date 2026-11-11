part of '../../onboard_v2.dart';

/// Thanh tiến độ 7 nấc, chạy từ p2Name (1) tới p8Reminder (7) — design.md §6.1.
/// Intro / loading / kết quả / theme không có header.
const int _onboardV2TotalProgressSegments = 7;

class OnboardV2Page extends StatefulWidget {
  const OnboardV2Page({super.key});

  @override
  State<OnboardV2Page> createState() => _OnboardV2PageState();
}

class _OnboardV2PageState extends State<OnboardV2Page> {
  OnboardV2PageStep? _lastTrackedPage;
  late final PageController _pageController;

  /// Guards [_requestTrackingPermissionOnce] so the OS ATT prompt fires at
  /// most once per flow — see its doc for why it lives here instead of
  /// `OnboardV2ResultPage.initState`.
  bool _hasRequestedTrackingPermission = false;

  @override
  void initState() {
    super.initState();
    final initialPage = context.read<OnboardV2Cubit>().state.currentPage;
    _pageController = PageController(initialPage: _pageIndex(initialPage));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _trackPage(context.read<OnboardV2Cubit>().state.currentPage);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardV2Cubit, OnboardV2State>(
      listenWhen: (previous, current) => previous.currentPage != current.currentPage,
      listener: (_, state) {
        _trackPage(state.currentPage);
        _animateToStep(state.currentPage);
        _requestTrackingPermissionOnce(state.currentPage);
      },
      builder: (context, state) {
        return _OnboardV2PageTransitionScope(
          controller: _pageController,
          child: PageView(
            key: const Key('onboard_v2_step_page_view'),
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              OnboardV2IntroPage(),
              OnboardV2NamePage(),
              OnboardV2AgePage(),
              OnboardV2BranchPage(),
              OnboardV2ProblemPage(),
              OnboardV2DesirePage(),
              OnboardV2HowPage(),
              OnboardV2ReminderPage(),
              OnboardV2LoadingPage(),
              OnboardV2ResultPage(),
              OnboardV2PickThemePage(),
            ],
          ),
        );
      },
    );
  }

  void _animateToStep(OnboardV2PageStep page) {
    final targetIndex = _pageIndex(page);
    if (!_pageController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        _pageController.jumpToPage(targetIndex);
      });
      return;
    }

    final currentIndex = (_pageController.page ?? _pageController.initialPage.toDouble()).round();
    if (currentIndex == targetIndex) return;

    unawaited(
      _pageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  int _pageIndex(OnboardV2PageStep page) => OnboardV2PageStep.values.indexOf(page);

  void _trackPage(OnboardV2PageStep page) {
    if (_lastTrackedPage == page) return;
    _lastTrackedPage = page;
    OnboardV2Tracking.trackPageView(page);
  }

  /// Moved here from `OnboardV2ResultPage.initState` — `PageView` pre-builds
  /// the neighbouring page, so calling it from p10's `initState` fired it
  /// while the app was still animating p8→p9, seconds after the user answered
  /// the OS notification prompt on S8. iOS commonly drops an ATT request made
  /// while another system alert is dismissing. Firing on the REAL transition
  /// to p10 (this listener only runs once `currentPage` actually changes)
  /// gives it a clean gap.
  void _requestTrackingPermissionOnce(OnboardV2PageStep page) {
    if (page != OnboardV2PageStep.p10Result || _hasRequestedTrackingPermission) return;
    _hasRequestedTrackingPermission = true;
    AppService.instance.appEventService.requestTrackingPermission();
  }
}

class _OnboardV2PageTransitionScope extends InheritedWidget {
  const _OnboardV2PageTransitionScope({
    required this.controller,
    required super.child,
  });

  final PageController controller;

  static _OnboardV2PageTransitionScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_OnboardV2PageTransitionScope>();
  }

  @override
  bool updateShouldNotify(_OnboardV2PageTransitionScope oldWidget) {
    return controller != oldWidget.controller;
  }
}
