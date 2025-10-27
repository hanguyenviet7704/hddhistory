part of '../../../../exercise.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String? audioUrl;

  const AudioPlayerWidget({super.key, this.audioUrl});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late final just_audio.AudioPlayer _audioPlayer;

  late final ValueNotifier<bool> _isPlayingNotifier;
  late final ValueNotifier<double> _progressNotifier;
  late final ValueNotifier<String> _currentTimeNotifier;
  late final ValueNotifier<String> _remainingTimeNotifier;
  late final ValueNotifier<bool> _isLoadingNotifier;
  late final ValueNotifier<String> _errorNotifier;
  late final ValueNotifier<int> _retryCountNotifier;

  bool _isInitialized = false;
  Duration? _duration;
  static const int _maxRetries = 3;

  // Stream subscriptions for proper disposal
  StreamSubscription? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;

  @override
  void initState() {
    super.initState();
    _audioPlayer = just_audio.AudioPlayer();
    _isPlayingNotifier = ValueNotifier<bool>(false);
    _progressNotifier = ValueNotifier<double>(0.0);
    _currentTimeNotifier = ValueNotifier<String>('00:00');
    _remainingTimeNotifier = ValueNotifier<String>('-00:00');
    _isLoadingNotifier = ValueNotifier<bool>(false);
    _errorNotifier = ValueNotifier<String>('');
    _retryCountNotifier = ValueNotifier<int>(0);

    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (widget.audioUrl == null || widget.audioUrl!.isEmpty) return;

    // Cancel existing subscriptions before creating new ones
    await _cancelSubscriptions();

    _isLoadingNotifier.value = true;
    _errorNotifier.value = '';
    _isInitialized = false;

    try {
      // Set up player state listener
      _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
        if (mounted && state.playing != _isPlayingNotifier.value) {
          _isPlayingNotifier.value = state.playing;
        }
      });

      // Set up position listener for progress updates
      _positionSubscription = _audioPlayer.positionStream.listen((position) {
        if (mounted && _duration != null && _duration!.inMilliseconds > 0) {
          _progressNotifier.value = position.inMilliseconds / _duration!.inMilliseconds;
          _currentTimeNotifier.value = _formatDuration(position);

          final remaining = _duration! - position;
          _remainingTimeNotifier.value = '-${_formatDuration(remaining)}';
        }
      });

      // Set up duration listener
      _durationSubscription = _audioPlayer.durationStream.listen((duration) {
        if (mounted) {
          _duration = duration;
          if (duration != null) {
            _remainingTimeNotifier.value = '-${_formatDuration(duration)}';
          }
        }
      });

      // Load audio URL (just_audio supports both local paths and network URLs)
      await _audioPlayer.setUrl(widget.audioUrl!);

      if (mounted) {
        _isInitialized = true;
        _retryCountNotifier.value = 0; // Reset retry count on success
        _isLoadingNotifier.value = false;
      }
    } catch (e) {
      if (!mounted) return;

      _isLoadingNotifier.value = false;

      // Handle errors with retry logic
      if (_retryCountNotifier.value < _maxRetries) {
        _errorNotifier.value = 'Failed to load audio. Retrying... (${_retryCountNotifier.value + 1}/$_maxRetries)';
        _retryCountNotifier.value++;

        // Retry after a short delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          await _initializePlayer();
        }
      } else {
        _errorNotifier.value = 'Failed to load audio. Please check the URL and your internet connection.';
      }
    }
  }

  Future<void> _cancelSubscriptions() async {
    await _playerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    _playerStateSubscription = null;
    _positionSubscription = null;
    _durationSubscription = null;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _togglePlay() async {
    if (!_isInitialized) return;

    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      // Handle error silently for now
    }
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    _audioPlayer.dispose();
    _isPlayingNotifier.dispose();
    _progressNotifier.dispose();
    _currentTimeNotifier.dispose();
    _remainingTimeNotifier.dispose();
    _isLoadingNotifier.dispose();
    _errorNotifier.dispose();
    _retryCountNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder<String>(
          valueListenable: _errorNotifier,
          builder: (context, error, child) {
            if (error.isNotEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFFF5252),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error,
                            style: const TextStyle(
                              color: Color(0xFFFF5252),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<int>(
                      valueListenable: _retryCountNotifier,
                      builder: (context, retryCount, child) {
                        if (retryCount > 0) {
                          return Row(
                            children: [
                              const Text(
                                'Tap to retry: ',
                                style: TextStyle(
                                  color: Color(0xFF7F8EA4),
                                  fontSize: 12,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _retryCountNotifier.value = 0;
                                  _errorNotifier.value = '';
                                  _initializePlayer();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF554FF0),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Retry',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _isLoadingNotifier,
          builder: (context, isLoading, child) {
            return ValueListenableBuilder<String>(
              valueListenable: _errorNotifier,
              builder: (context, error, child) {
                return Row(
                  children: [
                    GestureDetector(
                      onTap: isLoading ? null : _togglePlay,
                      child: Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE3E8EF), width: 1.82.w),
                          shape: BoxShape.circle,
                        ),
                        child: isLoading
                            ? Center(
                                child: SizedBox(
                                  width: 20.w,
                                  height: 20.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.w,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF554FF0)),
                                  ),
                                ),
                              )
                            : ValueListenableBuilder<bool>(
                                valueListenable: _isPlayingNotifier,
                                builder: (context, isPlaying, child) {
                                  return Icon(
                                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: const Color(0xFF7F8EA4),
                                    size: 20.w,
                                  );
                                },
                              ),
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 5.h,
                            width: double.infinity,
                            decoration: BoxDecoration(color: const Color(0xFFCDD5DF), borderRadius: BorderRadius.circular(20)),
                            child: ValueListenableBuilder<double>(
                              valueListenable: _progressNotifier,
                              builder: (context, progress, child) {
                                return FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: progress,
                                  child: Container(
                                    decoration: BoxDecoration(color: const Color(0xFF554FF0), borderRadius: BorderRadius.circular(20)),
                                  ),
                                );
                              },
                            ),
                          ),
                          8.verticalSpace,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ValueListenableBuilder<String>(
                                valueListenable: _currentTimeNotifier,
                                builder: (context, currentTime, child) {
                                  return AppText(
                                    currentTime,
                                    style: AppStyle.text10.copyWith(color: const Color(0xFF7F8EA4), fontWeight: FontWeight.w500),
                                  );
                                },
                              ),
                              ValueListenableBuilder<String>(
                                valueListenable: _remainingTimeNotifier,
                                builder: (context, remainingTime, child) {
                                  return AppText(
                                    remainingTime,
                                    style: AppStyle.text10.copyWith(color: const Color(0xFF7F8EA4), fontWeight: FontWeight.w500),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}
