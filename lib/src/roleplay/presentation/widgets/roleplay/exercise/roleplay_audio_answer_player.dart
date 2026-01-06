part of '../../../../roleplay.dart';

class RoleplayAudioAnswerPlayer extends StatefulWidget {
  final String source;

  const RoleplayAudioAnswerPlayer({
    super.key,
    required this.source,
  });

  @override
  State<RoleplayAudioAnswerPlayer> createState() => _RoleplayAudioAnswerPlayerState();
}

class _RoleplayAudioAnswerPlayerState extends State<RoleplayAudioAnswerPlayer> {
  late final just_audio.AudioPlayer _audioPlayer;
  late final ValueNotifier<bool> _isPlayingNotifier;
  late final ValueNotifier<bool> _isLoadingNotifier;
  late final ValueNotifier<Duration> _positionNotifier;
  late final ValueNotifier<Duration> _durationNotifier;

  StreamSubscription<just_audio.PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<just_audio.ProcessingState>? _processingSubscription;

  bool _isSeeking = false;
  double _seekValue = 0.0;

  String get _source => widget.source.trim();

  bool get _isRemote => _source.startsWith('http://') || _source.startsWith('https://');

  String get _normalizedPath => _source.startsWith('file://') ? _source.replaceFirst('file://', '') : _source;

  bool get _isContentUri => _normalizedPath.startsWith('content://');

  @override
  void initState() {
    super.initState();
    _audioPlayer = just_audio.AudioPlayer();
    _isPlayingNotifier = ValueNotifier<bool>(false);
    _isLoadingNotifier = ValueNotifier<bool>(false);
    _positionNotifier = ValueNotifier<Duration>(Duration.zero);
    _durationNotifier = ValueNotifier<Duration>(Duration.zero);
    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant RoleplayAudioAnswerPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    if (_source.isEmpty) {
      _resetPlaybackState();
      return;
    }

    await _cancelSubscriptions();

    _isLoadingNotifier.value = true;
    _positionNotifier.value = Duration.zero;
    _durationNotifier.value = Duration.zero;

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      _isPlayingNotifier.value = state.playing;
    });

    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (_isSeeking) return;
      _positionNotifier.value = position;
    });

    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      _durationNotifier.value = duration ?? Duration.zero;
    });

    _processingSubscription = _audioPlayer.processingStateStream.listen((processingState) async {
      if (processingState == just_audio.ProcessingState.completed) {
        await _audioPlayer.seek(Duration.zero);
        await _audioPlayer.pause();
      }
    });

    try {
      if (_isRemote) {
        await _audioPlayer.setUrl(_source);
      } else if (_isContentUri) {
        await _audioPlayer.setAudioSource(just_audio.AudioSource.uri(Uri.parse(_normalizedPath)));
      } else {
        await _audioPlayer.setFilePath(_normalizedPath);
      }
    } catch (_) {
      // Ignore audio init errors; UI will stay in a neutral state.
    } finally {
      if (!mounted) return;
      _isLoadingNotifier.value = false;
    }
  }

  Future<void> _cancelSubscriptions() async {
    await _playerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _processingSubscription?.cancel();
    _playerStateSubscription = null;
    _positionSubscription = null;
    _durationSubscription = null;
    _processingSubscription = null;
  }

  void _resetPlaybackState() {
    _isPlayingNotifier.value = false;
    _isLoadingNotifier.value = false;
    _positionNotifier.value = Duration.zero;
    _durationNotifier.value = Duration.zero;
  }

  Future<void> _togglePlay() async {
    if (_isLoadingNotifier.value) return;

    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
      return;
    }

    if (_audioPlayer.processingState == just_audio.ProcessingState.completed) {
      await _audioPlayer.seek(Duration.zero);
    }

    await _audioPlayer.play();
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    _audioPlayer.dispose();
    _isPlayingNotifier.dispose();
    _isLoadingNotifier.dispose();
    _positionNotifier.dispose();
    _durationNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_source.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 60.h,
      child: Row(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: _isLoadingNotifier,
            builder: (context, isLoading, child) {
              return ValueListenableBuilder<bool>(
                valueListenable: _isPlayingNotifier,
                builder: (context, isPlaying, child) {
                  return InkWell(
                    onTap: _togglePlay,
                    borderRadius: BorderRadius.circular(999.r),
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: AppCustomColor.backgroundWhite,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppCustomColor.borderSecondary,
                          width: 2.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppCustomColor.borderDefault,
                            blurRadius: 4.r,
                            offset: Offset.zero,
                          ),
                        ],
                      ),
                      child: isLoading
                          ? Center(
                              child: SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.w,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppCustomColor.brandPrimary),
                                ),
                              ),
                            )
                          : Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: AppCustomColor.textTertiary,
                              size: 22.w,
                            ),
                    ),
                  );
                },
              );
            },
          ),
          16.horizontalSpace,
          Expanded(
            child: ValueListenableBuilder<Duration>(
              valueListenable: _durationNotifier,
              builder: (context, duration, child) {
                return ValueListenableBuilder<Duration>(
                  valueListenable: _positionNotifier,
                  builder: (context, position, child) {
                    final maxMillis = duration.inMilliseconds;
                    final progress = maxMillis == 0 ? 0.0 : position.inMilliseconds / maxMillis;
                    final sliderValue = _isSeeking ? _seekValue : progress.clamp(0.0, 1.0).toDouble();
                    final hasDuration = maxMillis > 0;

                    return SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 6.h,
                        activeTrackColor: AppCustomColor.neutral300,
                        inactiveTrackColor: AppCustomColor.neutral300,
                        thumbShape: const RoleplaySliderThumbShape(
                          thumbRadius: 7,
                          borderWidth: 2,
                          thumbColor: AppCustomColor.backgroundWhite,
                          borderColor: AppCustomColor.borderSecondary,
                        ),
                        overlayShape: SliderComponentShape.noOverlay,
                        trackShape: RoundedRectSliderTrackShape(),
                      ),
                      child: Slider(
                        value: sliderValue,
                        min: 0,
                        max: 1,
                        onChangeStart: hasDuration
                            ? (value) {
                                setState(() {
                                  _isSeeking = true;
                                  _seekValue = value;
                                });
                              }
                            : null,
                        onChanged: hasDuration
                            ? (value) {
                                setState(() {
                                  _seekValue = value;
                                });
                              }
                            : null,
                        onChangeEnd: hasDuration
                            ? (value) async {
                                final positionMillis = (value * maxMillis).round();
                                await _audioPlayer.seek(Duration(milliseconds: positionMillis));
                                setState(() {
                                  _isSeeking = false;
                                });
                              }
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          16.horizontalSpace,
          ValueListenableBuilder<Duration>(
            valueListenable: _durationNotifier,
            builder: (context, duration, child) {
              return AppText(
                _formatDuration(duration),
                maxLines: 1,
                style: AppStyle.text12.copyWith(
                  color: AppCustomColor.textTertiary,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class RoleplaySliderThumbShape extends SliderComponentShape {
  final double thumbRadius;
  final double borderWidth;
  final Color thumbColor;
  final Color borderColor;

  const RoleplaySliderThumbShape({
    this.thumbRadius = 7,
    this.borderWidth = 2,
    this.thumbColor = AppCustomColor.backgroundWhite,
    this.borderColor = AppCustomColor.borderSecondary,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, thumbRadius, borderPaint);

    final thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, thumbRadius - borderWidth, thumbPaint);
  }
}
