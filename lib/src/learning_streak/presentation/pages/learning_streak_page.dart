part of '../../learning_streak.dart';

class LearningStreakPage extends StatefulWidget {
  const LearningStreakPage({super.key});

  @override
  State<LearningStreakPage> createState() => _LearningStreakPageState();
}

class _LearningStreakPageState extends State<LearningStreakPage> {
  bool _hasTrackedPopupView = false;
  bool _hasTrackedPopupClose = false;
  bool _isClosingPopup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPopupData());
  }

  int _readCurrentStreak() {
    if (!AppDI.injector.isRegistered<LearningStreakCubit>()) return 0;
    return AppDI.injector.get<LearningStreakCubit>().state.selectedItem.currentStreak;
  }

  void _trackPopupViewIfNeeded({required int currentStreak}) {
    if (_hasTrackedPopupView) return;
    _hasTrackedPopupView = true;
    AppService.instance.appTrackingService.trackHomeStreakPopupView(
      currentStreak: currentStreak,
    );
  }

  void _trackPopupCloseIfNeeded({required int currentStreak}) {
    if (_hasTrackedPopupClose) return;
    _hasTrackedPopupClose = true;
    AppService.instance.appTrackingService.trackHomeStreakPopupClose(currentStreak: currentStreak);
  }

  Future<void> _loadPopupData() async {
    final userId = context.read<UserCubit>().state.user.id;
    final result = await context.read<LearningStreakCubit>().loadUserLearningStreak(
      triggerSource: LearningStreakTriggerSource.homeChip,
      requestedUserId: userId,
      timeout: const Duration(seconds: 2),
      emitLoading: false,
      allowSafeDefaultOnFailure: true,
    );
    if (!mounted) return;
    _trackPopupViewIfNeeded(currentStreak: result.streak.currentStreak);
  }

  Future<void> _closePopup() async {
    if (_isClosingPopup) return;
    _isClosingPopup = true;
    final currentStreak = _readCurrentStreak();
    _trackPopupViewIfNeeded(currentStreak: currentStreak);
    _trackPopupCloseIfNeeded(currentStreak: currentStreak);

    if (context.canPop()) {
      context.pop();
      return;
    }
    _isClosingPopup = false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) return;
        final currentStreak = _readCurrentStreak();
        _trackPopupViewIfNeeded(currentStreak: currentStreak);
        _trackPopupCloseIfNeeded(currentStreak: currentStreak);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _closePopup(),
                child: Container(color: AppCustomColor.scrimOverlay),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: BlocBuilder<LearningStreakCubit, LearningStreakState>(
                builder: (context, state) => StreakHomePopupContent(
                  streak: state.selectedItem,
                  onClose: () => _closePopup(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
