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

  bool get hasAudio => url.isNotEmpty && _player != null;

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
      await _player!.processingStateStream.firstWhere(
        (state) => state == just_audio.ProcessingState.completed,
      );
    } catch (_) {
      // If the stream completes early (e.g. controller disposed) we gracefully stop waiting.
    }

    if (_player != null) {
      await _player!.pause();
      await _player!.seek(Duration.zero);
    }
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

  const RoleplayAudioButton({
    super.key,
    required this.controller,
    required this.iconColor,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.hasAudio) return const SizedBox.shrink();

    final double padding = dense ? 6.w : 8.w;
    final double iconSize = dense ? 16.w : 20.w;

    return InkWell(
      onTap: () => controller?.replay(),
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
            return Icon(
              isPlaying ? Icons.graphic_eq : Icons.volume_up_rounded,
              color: iconColor,
              size: iconSize,
            );
          },
        ),
      ),
    );
  }
}
