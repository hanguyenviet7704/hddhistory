part of '../../../../exercise.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String? audioUrl;

  const AudioPlayerWidget({super.key, this.audioUrl});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late final AudioPlayer _audioPlayer;

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

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
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

    _isLoadingNotifier.value = true;
    _errorNotifier.value = '';

    try {
      // Set up player state listener
      _audioPlayer.playerStateStream.listen((state) {
        if (state.playing != _isPlayingNotifier.value) {
          _isPlayingNotifier.value = state.playing;
        }
      });

      // Set up position listener for progress updates
      _audioPlayer.positionStream.listen((position) {
        if (_duration != null) {
          _progressNotifier.value = position.inMilliseconds / _duration!.inMilliseconds;
          _currentTimeNotifier.value = _formatDuration(position);

          final remaining = _duration! - position;
          _remainingTimeNotifier.value = '-${_formatDuration(remaining)}';
        }
      });

      // Set up duration listener
      _audioPlayer.durationStream.listen((duration) {
        _duration = duration;
        if (duration != null) {
          _remainingTimeNotifier.value = '-${_formatDuration(duration)}';
        }
      });

      // Set up error listener
      _audioPlayer.playerStateStream.where((state) => state.processingState == ProcessingState.idle && state.playing == false).listen((_) {
        if (_retryCountNotifier.value < _maxRetries) {
          _errorNotifier.value = 'Failed to load audio. Retrying... (${_retryCountNotifier.value + 1}/$_maxRetries)';
          _retryCountNotifier.value++;

          // Retry after a short delay
          Future.delayed(const Duration(seconds: 2), () {
            _initializePlayer();
          });
        } else {
          _errorNotifier.value = 'Failed to load audio after $_maxRetries attempts. Please check your connection.';
        }
      });

      // Load audio URL (just_audio supports both local paths and network URLs)
      await _audioPlayer.setUrl(widget.audioUrl!);
      _isInitialized = true;
      _retryCountNotifier.value = 0; // Reset retry count on success
    } catch (e) {
      _errorNotifier.value = 'Error loading audio: ${e.toString()}';
    } finally {
      _isLoadingNotifier.value = false;
    }
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
        Row(
          children: [
            GestureDetector(
              onTap: _isLoadingNotifier.value || _errorNotifier.value.isNotEmpty ? null : _togglePlay,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FB),
                  border: Border.all(color: const Color(0xFFE3E8EF), width: 1.8),
                  shape: BoxShape.circle,
                ),
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isLoadingNotifier,
                  builder: (context, isLoading, child) {
                    if (isLoading) {
                      return const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF554FF0)),
                        ),
                      );
                    }

                    return ValueListenableBuilder<bool>(
                      valueListenable: _isPlayingNotifier,
                      builder: (context, isPlaying, child) {
                        return Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: const Color(0xFF0D121C), size: 20);
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 5,
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
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ValueListenableBuilder<String>(
                        valueListenable: _currentTimeNotifier,
                        builder: (context, currentTime, child) {
                          return Text(
                            currentTime,
                            style: const TextStyle(color: Color(0xFF7F8EA4), fontSize: 10, fontWeight: FontWeight.w500, height: 1.5),
                          );
                        },
                      ),
                      ValueListenableBuilder<String>(
                        valueListenable: _remainingTimeNotifier,
                        builder: (context, remainingTime, child) {
                          return Text(
                            remainingTime,
                            style: const TextStyle(color: Color(0xFF7F8EA4), fontSize: 10, fontWeight: FontWeight.w500, height: 1.5),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
