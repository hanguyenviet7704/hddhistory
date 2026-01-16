part of '../../../roleplay.dart';

/// Lightweight controller that wraps a [just_audio.AudioPlayer] so that
/// conversation bubbles can autoplay once and allow manual replays.
class RoleplayAudioController {
  RoleplayAudioController(this.url, {Duration? fallbackDelay}) : _fallbackDelay = fallbackDelay ?? const Duration(seconds: 2) {
    if (url.isNotEmpty) {
      _player = just_audio.AudioPlayer();
      _initialization = _player!.setUrl(url);
    }
  }

  final String url;
  final Duration _fallbackDelay;
  just_audio.AudioPlayer? _player;
  Future<void>? _initialization;
  bool _disposed = false;
  Completer<void>? _stopSignal;

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
    await _player!.seek(Duration.zero);
    await _player!.play();
  }

  Future<void> stop() async {
    if (!await _ensureReady() || _player == null) return;
    await _player!.pause();
    await _player!.seek(Duration.zero);
    _stopSignal?.complete();
    _stopSignal = null;
  }

  Future<void> togglePlayPause() async {
    if (!await _ensureReady() || _player == null) return;

    final player = _player!;
    if (player.playing) {
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

    await replay();

    try {
      _stopSignal = Completer<void>();
      await Future.any([
        _player!.processingStateStream.firstWhere(
          (state) => state == just_audio.ProcessingState.completed,
        ),
        _stopSignal!.future,
      ]);
    } catch (_) {
      // If the stream completes early (e.g. controller disposed) we gracefully stop waiting.
    }

    if (_player != null) {
      await _player!.pause();
      await _player!.seek(Duration.zero);
    }

    _stopSignal = null;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _player?.dispose();
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
