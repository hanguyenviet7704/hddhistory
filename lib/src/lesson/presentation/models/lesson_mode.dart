part of '../../lesson.dart';

enum LessonEntryMode {
  read,
  audio
  ;

  bool get isAudio => this == LessonEntryMode.audio;

  bool get isRead => this == LessonEntryMode.read;

  String get routeValue => name;

  static LessonEntryMode fromRouteValue(String? value) {
    if (value == LessonEntryMode.audio.routeValue) {
      return LessonEntryMode.audio;
    }
    return LessonEntryMode.read;
  }
}

enum LessonCompletionOrigin {
  none,
  read,
  audio
  ;

  bool get isAudio => this == LessonCompletionOrigin.audio;
}
