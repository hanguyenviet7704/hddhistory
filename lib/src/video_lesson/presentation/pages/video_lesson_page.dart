part of '../../video_lesson.dart';

class VideoLessonPage extends StatefulWidget {
  const VideoLessonPage({
    super.key,
    required this.courseId,
    required this.nodeId,
    required this.lessonId,
  });

  final String courseId;
  final String nodeId;
  final String lessonId;

  @override
  State<VideoLessonPage> createState() => _VideoLessonPageState();
}

class _VideoLessonPageState extends State<VideoLessonPage> {
  static const _shareText =
      'Found a gem on MeUp! 💎 I had so much fun watching this and learned a lot. '
      'Sharing the love in case you need some inspiration today! 🙌\n'
      'Android: https://play.google.com/store/apps/details?id=com.eup.meup\n'
      'IOS: https://apps.apple.com/us/app/meup-up-your-skills/id6755175330';

  late final ValueNotifier<_VideoLessonPagePlayerViewState> _playerViewStateNotifier;
  bool _hasTrackedExit = false;
  bool _hasTriggeredInitialAutoplay = false;
  bool _isHandlingCompletionSuccess = false;
  bool _isSeeking = false;
  bool _resumePlaybackAfterSeek = false;
  Timer? _controlsAutoHideTimer;

  VideoLessonCubit get _cubit => context.read<VideoLessonCubit>();

  _VideoLessonPagePlayerViewState get _playerViewState => _playerViewStateNotifier.value;

  VideoPlayerController? get _controller => _playerViewState.controller;

  String get _controllerUrl => _playerViewState.controllerUrl;

  void _updatePlayerViewState({
    VideoPlayerController? controller,
    String? controllerUrl,
    bool? isInitializingController,
    bool clearController = false,
  }) {
    final nextState = _playerViewState.copyWith(
      controller: controller,
      controllerUrl: controllerUrl,
      isInitializingController: isInitializingController,
      clearController: clearController,
    );
    if (_playerViewState == nextState) return;
    _playerViewStateNotifier.value = nextState;
  }

  @override
  void initState() {
    super.initState();
    _playerViewStateNotifier = ValueNotifier(const _VideoLessonPagePlayerViewState());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLesson();
    });
  }

  @override
  void dispose() {
    _controlsAutoHideTimer?.cancel();
    _disposeController();
    _playerViewStateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop || _hasTrackedExit) return;
          final state = _cubit.state;
          final trackingData = _trackingData(state);
          if (trackingData != null) {
            AppService.instance.appTrackingService.trackVideoLessonExitClick(
              trackingData,
              nodeId: state.nodeId,
            );
          }
          _hasTrackedExit = true;
          _cubit.clearSessionStateForExit();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF0D121C),
          body: MultiBlocListener(
            listeners: [
              ..._buildBlocListeners(),
            ],
            child: _buildPageBody(),
          ),
        ),
      ),
    );
  }
}
