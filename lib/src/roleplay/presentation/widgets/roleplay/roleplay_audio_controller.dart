part of '../../../roleplay.dart';

/// Lightweight controller that wraps a [just_audio.AudioPlayer] so that
/// conversation bubbles can autoplay once and allow manual replays.
class RoleplayAudioController {
  RoleplayAudioController(this.url, {Duration? fallbackDelay}) : _fallbackDelay = fallbackDelay ?? const Duration(seconds: 2) {
    if (url.isNotEmpty) {
      _player = just_audio.AudioPlayer();
      _initialization = _player!.setUrl(url);
      _instances.add(this);
    }
  }

  static final Set<RoleplayAudioController> _instances = <RoleplayAudioController>{};

  final String url;
  final Duration _fallbackDelay;
  just_audio.AudioPlayer? _player;
  Future<void>? _initialization;
  bool _disposed = false;
  Completer<bool>? _stopSignal;

  bool get hasAudio => url.isNotEmpty && _player != null;
  bool get isPlaying => _player?.playing ?? false;

  Stream<just_audio.PlayerState>? get _playerStateStream => _player?.playerStateStream;

  Stream<just_audio.PlayerState>? get playerStateStream => _playerStateStream;

  Future<bool> _ensureReady() async {
    if (!hasAudio) return false;
    try {
      await _initialization;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> replay() async {
    if (!await _ensureReady() || _player == null) return;
    _stopOtherControllers();
    await _player!.seek(Duration.zero);
    await _player!.play();
  }

  Future<void> stop() async {
    if (!await _ensureReady() || _player == null) return;
    stopAutoWait();
    await _player!.pause();
    await _player!.seek(Duration.zero);
    _stopSignal = null;
  }

  Future<void> togglePlayPause() async {
    if (!await _ensureReady() || _player == null) return;

    final player = _player!;
    if (player.playing) {
      stopAutoWait(delayAfter: true);
      await player.pause();
      return;
    }

    if (player.processingState == just_audio.ProcessingState.completed) {
      await player.seek(Duration.zero);
    } else {
      final Duration? duration = player.duration;
      final Duration position = player.position;
      if (duration != null && position >= duration) {
        await player.seek(Duration.zero);
      }
    }

    _stopOtherControllers();
    await player.play();
  }

  Future<void> playAutoAndWait() async {
    if (!hasAudio) {
      await Future.delayed(_fallbackDelay);
      return;
    }

    if (!await _ensureReady() || _player == null) {
      await Future.delayed(_fallbackDelay);
      return;
    }

    stopAutoWait();
    _stopSignal = Completer<bool>();
    await replay();

    final bool shouldDelay = await _waitForAutoStopOrCompletion();

    if (_player != null) {
      await _player!.pause();
      await _player!.seek(Duration.zero);
    }

    _stopSignal = null;

    if (shouldDelay) {
      await Future.delayed(_fallbackDelay);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _player?.dispose();
    _instances.remove(this);
  }

  void stopAutoWait({bool delayAfter = false}) {
    final stopSignal = _stopSignal;
    if (stopSignal == null || stopSignal.isCompleted) return;
    stopSignal.complete(delayAfter);
  }

  Future<bool> _waitForAutoStopOrCompletion() async {
    try {
      return await Future.any<bool>([
        _player!.processingStateStream
            .firstWhere((state) => state == just_audio.ProcessingState.completed)
            .then((_) => false),
        _stopSignal!.future,
      ]);
    } catch (_) {
      // If the stream completes early (e.g. controller disposed) we gracefully stop waiting.
      return false;
    }
  }

  void _stopOtherControllers() {
    for (final controller in _instances.toList()) {
      if (controller == this) continue;
      if (controller._disposed) {
        _instances.remove(controller);
        continue;
      }
      if (controller.isPlaying) {
        unawaited(controller.stop());
      }
    }
  }
}

class RoleplayAudioButton extends StatelessWidget {
  final RoleplayAudioController? controller;
  final Color iconColor;
  final bool dense;
  final bool disabledUI;

  const RoleplayAudioButton({
    super.key,
    required this.controller,
    required this.iconColor,
    this.dense = false,
    this.disabledUI = false,
  });

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.hasAudio) return const SizedBox.shrink();

    final double padding = dense ? 6.w : 8.w;
    final double iconSize = dense ? 16.w : 20.w;

    return InkWell(
      onTap: () {
        final trackingData = RoleplayTrackingData.fromContext();
        if (trackingData != null) {
          final action = controller?.isPlaying == true ? 'stop' : 'play';
          AppService.instance.appTrackingService.trackRoleplayVoiceInteraction(
            trackingData,
            voiceAction: action,
          );
        }
        controller?.togglePlayPause();
      },
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: StreamBuilder<just_audio.PlayerState>(
          stream: controller!.playerStateStream,
          builder: (context, snapshot) {
            final isPlaying = snapshot.data?.playing ?? false;
            if (disabledUI) {
              return SizedBox.shrink();
            }
            
            return Icon(
              isPlaying ? Icons.pause_rounded : Icons.volume_up_rounded,
              color: iconColor,
              size: iconSize,
            );
          },
        ),
      ),
    );
  }
}
