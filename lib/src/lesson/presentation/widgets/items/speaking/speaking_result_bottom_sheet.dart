part of '../../../../lesson.dart';

class SpeakingResultBottomSheet extends StatelessWidget {
  final ResultType type;
  final VoidCallback onContinue;
  final VoidCallback? onExplain;
  final bool showExplanation;
  final String? analysisText;
  final String? audioFilePath;
  final List<String>? goodPoints;
  final List<String>? improvementPoints;

  const SpeakingResultBottomSheet({
    super.key,
    required this.type,
    required this.onContinue,
    this.onExplain,
    this.showExplanation = false,
    this.analysisText,
    this.audioFilePath,
    this.goodPoints,
    this.improvementPoints,
  });

  @override
  Widget build(BuildContext context) {
    final hasExplanation = (analysisText ?? '').isNotEmpty;
    final explanationVisible = hasExplanation && showExplanation;
    final titleOverride = type == ResultType.correct && explanationVisible ? 'Completed!' : null;

    return LessonResultOverlay(
      showExplanation: explanationVisible,
      // onBackdropTap: explanationVisible ? onExplain : null,
      explanation: hasExplanation
          ? SpeakingExplanationContent(
              analysisText: analysisText!,
              audioFilePath: audioFilePath,
              goodPoints: goodPoints ?? const [],
              improvementPoints: improvementPoints ?? const [],
            )
          : null,
      summary: ExerciseResultSummary(
        type: type,
        onContinue: onContinue,
        onExplain: hasExplanation ? onExplain : null,
        showExplanation: explanationVisible,
        continueLabel: context.text.onboardingSkipGreetingButton,
        explainLabel: context.text.exerciseExplainButton,
        closeExplainLabel: context.text.exerciseCloseExplainButton,
        title: titleOverride,
      ),
    );
  }
}

class SpeakingExplanationContent extends StatelessWidget {
  final String analysisText;
  final String? audioFilePath;
  final List<String> goodPoints;
  final List<String> improvementPoints;

  const SpeakingExplanationContent({
    super.key,
    required this.analysisText,
    this.audioFilePath,
    required this.goodPoints,
    required this.improvementPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            'Answer analysis',
            style: AppStyle.text20.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D121C),
            ),
          ),
          16.verticalSpace,
          AppText(
            analysisText,
            maxLines: 100,
            style: AppStyle.text14.copyWith(
              color: const Color(0xFF364152),
              height: 1.5,
            ),
          ),
          if (audioFilePath?.isNotEmpty == true) ...[
            16.verticalSpace,
            SpeakingAnswerPlayback(audioPath: audioFilePath!),
          ],
          if (goodPoints.isNotEmpty) ...[
            16.verticalSpace,
            SpeakingGoodPointsSection(points: goodPoints),
          ],
          if (improvementPoints.isNotEmpty) ...[
            16.verticalSpace,
            SpeakingImprovementSection(points: improvementPoints),
          ],
        ],
      ),
    );
  }
}

class SpeakingGoodPointsSection extends StatelessWidget {
  final List<String> points;

  const SpeakingGoodPointsSection({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEAFD),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                AppAsset.svg.app.icTennisRacket,
                width: 20.w,
                height: 20.w,
              ),
              6.horizontalSpace,
              AppText(
                'Good points',
                style: AppStyle.textBold14.copyWith(
                  color: const Color(0xFF554FF0),
                  height: 1.75,
                ),
              ),
            ],
          ),
          8.verticalSpace,
          ...points.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: entry.key < points.length - 1 ? 4.h : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    '${entry.key + 1}. ',
                    style: AppStyle.text14.copyWith(
                      color: const Color(0xFF364152),
                      height: 1.5,
                    ),
                  ),
                  Expanded(
                    child: AppText(
                      entry.value,
                      maxLines: 100,
                      style: AppStyle.text14.copyWith(
                        color: const Color(0xFF364152),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class SpeakingImprovementSection extends StatelessWidget {
  final List<String> points;

  const SpeakingImprovementSection({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EE),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_fix_high_rounded,
                color: const Color(0xFF41AE8C),
                size: 20.w,
              ),
              6.horizontalSpace,
              AppText(
                'Can be improved',
                style: AppStyle.textBold14.copyWith(
                  color: const Color(0xFF41AE8C),
                  height: 1.75,
                ),
              ),
            ],
          ),
          8.verticalSpace,
          ...points.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: entry.key < points.length - 1 ? 4.h : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    '${entry.key + 1}. ',
                    style: AppStyle.text14.copyWith(
                      color: const Color(0xFF364152),
                      height: 1.5,
                    ),
                  ),
                  Expanded(
                    child: AppText(
                      entry.value,
                      maxLines: 100,
                      style: AppStyle.text14.copyWith(
                        color: const Color(0xFF364152),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class SpeakingAnswerPlayback extends StatefulWidget {
  final String audioPath;

  const SpeakingAnswerPlayback({super.key, required this.audioPath});

  @override
  State<SpeakingAnswerPlayback> createState() => _SpeakingAnswerPlaybackState();
}

class _SpeakingAnswerPlaybackState extends State<SpeakingAnswerPlayback> {
  late final just_audio.AudioPlayer _player;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<just_audio.PlayerState>? _playerStateSubscription;
  Duration _totalDuration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = true;
  bool _hasError = false;
  just_audio.PlayerState _playerState = just_audio.PlayerState(false, just_audio.ProcessingState.idle);

  @override
  void initState() {
    super.initState();
    _player = just_audio.AudioPlayer();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final file = File(widget.audioPath);
      if (!await file.exists()) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
        return;
      }

      await _player.setFilePath(widget.audioPath);
      _totalDuration = _player.duration ?? Duration.zero;

      _positionSubscription = _player.positionStream.listen((position) {
        if (!mounted) return;
        setState(() {
          _position = position;
        });
      });

      _playerStateSubscription = _player.playerStateStream.listen((state) async {
        if (!mounted) return;
        if (state.processingState == just_audio.ProcessingState.completed) {
          await _player.seek(Duration.zero);
          await _player.pause();
          _position = Duration.zero;
        }
        setState(() {
          _playerState = state;
        });
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _togglePlayback() async {
    try {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } catch (_) {}
  }

  Future<void> _seek(double value) async {
    if (_totalDuration.inMilliseconds == 0) return;
    final target = Duration(milliseconds: (value * _totalDuration.inMilliseconds).round());
    await _player.seek(target);
  }

  String _format(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _SpeakingAudioStatus(text: 'Preparing your recording...');
    }

    if (_hasError) {
      return const _SpeakingAudioStatus(text: 'Unable to play your recorded answer.');
    }

    final progress = _totalDuration.inMilliseconds == 0 ? 0.0 : (_position.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0).toDouble();
    final remaining = (_totalDuration - _position).isNegative ? Duration.zero : _totalDuration - _position;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Your recording',
            style: AppStyle.textBold14.copyWith(
              color: const Color(0xFF0D121C),
            ),
          ),
          12.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _togglePlayback,
                child: Container(
                  width: 48.w,
                  height: 48.w,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFF554FF0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _playerState.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28.w,
                  ),
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4.h,
                        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                      ),
                      child: Slider(
                        value: progress,
                        onChanged: _totalDuration.inMilliseconds == 0 ? null : (value) => _seek(value),
                        activeColor: const Color(0xFF554FF0),
                        inactiveColor: const Color(0xFFAAB7CC),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          _format(_position),
                          style: AppStyle.text12.copyWith(color: const Color(0xFF7F8EA4)),
                        ),
                        AppText(
                          '-${_format(remaining)}',
                          style: AppStyle.text12.copyWith(color: const Color(0xFF7F8EA4)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeakingAudioStatus extends StatelessWidget {
  final String text;

  const _SpeakingAudioStatus({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: AppText(
        text,
        style: AppStyle.text12.copyWith(color: const Color(0xFF7F8EA4)),
      ),
    );
  }
}
