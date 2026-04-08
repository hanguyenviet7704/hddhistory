part of '../../video_lesson.dart';

class _VideoLessonPagePlayerViewState {
  const _VideoLessonPagePlayerViewState({
    this.controller,
    this.controllerUrl = '',
    this.isInitializingController = false,
  });

  final VideoPlayerController? controller;
  final String controllerUrl;
  final bool isInitializingController;

  _VideoLessonPagePlayerViewState copyWith({
    VideoPlayerController? controller,
    String? controllerUrl,
    bool? isInitializingController,
    bool clearController = false,
  }) {
    return _VideoLessonPagePlayerViewState(
      controller: clearController ? null : controller ?? this.controller,
      controllerUrl: controllerUrl ?? this.controllerUrl,
      isInitializingController: isInitializingController ?? this.isInitializingController,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _VideoLessonPagePlayerViewState &&
        other.controller == controller &&
        other.controllerUrl == controllerUrl &&
        other.isInitializingController == isInitializingController;
  }

  @override
  int get hashCode => Object.hash(controller, controllerUrl, isInitializingController);
}
