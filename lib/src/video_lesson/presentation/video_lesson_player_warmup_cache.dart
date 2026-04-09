part of '../video_lesson.dart';

const _videoLessonPlayerWarmupTimeout = Duration(seconds: 12);

final _videoLessonPlayerWarmupCache = _VideoLessonPlayerWarmupCache();

enum _VideoLessonWarmupState { miss, hitReady, hitPending, failed }

final class _VideoLessonWarmupResolution {
  const _VideoLessonWarmupResolution({
    required this.state,
    this.controller,
  });

  final _VideoLessonWarmupState state;
  final VideoPlayerController? controller;

  bool get hasController => controller != null;
}

final class _VideoLessonWarmupEntry {
  _VideoLessonWarmupEntry({
    required this.url,
    required this.controller,
  });

  final String url;
  final VideoPlayerController controller;
  late final Future<void> initializeFuture;
  bool isReady = false;
}

final class _VideoLessonPlayerWarmupCache {
  _VideoLessonWarmupEntry? _entry;

  void prepare(String rawUrl) {
    final url = rawUrl.trim();
    if (url.isEmpty) return;

    final current = _entry;
    if (current != null && current.url == url) return;
    if (current != null) {
      unawaited(_disposeControllerSafely(current.controller));
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    final entry = _VideoLessonWarmupEntry(
      url: url,
      controller: controller,
    );
    entry.initializeFuture = _initializeEntry(entry);
    _entry = entry;
  }

  Future<_VideoLessonWarmupResolution> take(String rawUrl) async {
    final url = rawUrl.trim();
    final entry = _entry;
    if (entry == null || entry.url != url) {
      return const _VideoLessonWarmupResolution(
        state: _VideoLessonWarmupState.miss,
      );
    }

    _entry = null;
    final warmupState = entry.isReady
        ? _VideoLessonWarmupState.hitReady
        : _VideoLessonWarmupState.hitPending;

    try {
      await entry.initializeFuture;
      return _VideoLessonWarmupResolution(
        state: warmupState,
        controller: entry.controller,
      );
    } catch (_) {
      await _disposeControllerSafely(entry.controller);
      return const _VideoLessonWarmupResolution(
        state: _VideoLessonWarmupState.failed,
      );
    }
  }

  Future<void> clear(String rawUrl) async {
    final url = rawUrl.trim();
    final entry = _entry;
    if (entry == null || entry.url != url) return;
    _entry = null;
    await _disposeControllerSafely(entry.controller);
  }

  Future<void> _initializeEntry(_VideoLessonWarmupEntry entry) async {
    await entry.controller
        .initialize()
        .timeout(_videoLessonPlayerWarmupTimeout);
    await entry.controller.setLooping(false);
    entry.isReady = true;
  }

  Future<void> _disposeControllerSafely(
    VideoPlayerController controller,
  ) async {
    try {
      await controller.dispose();
    } catch (_) {}
  }
}
