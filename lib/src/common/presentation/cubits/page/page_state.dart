part of '../../../common.dart';

@freezed
abstract class PageState with _$PageState {
  const factory PageState({
    @Default(0) int currentIndex,
    @Default('') String currentRouteName,
    @Default(false) bool isPassSplashScreen,
  }) = _PageState;

  factory PageState.initial() => const PageState();
}

extension PageStateX on PageState {
  bool get isAuthenticated => AppGlobalValue.accessToken.isNotEmpty;

  bool get isPrimaryRoute => primaryRouteNames.contains(currentRouteName);

  /// Routes that keep the floating nav pill on screen.
  ///
  /// A roadmap is a place you stand, not a thing you are in the middle of — so
  /// both roadmaps belong here and the reading surfaces (lesson, roleplay, warm-up)
  /// do not. [RouteNamed.lessonReader] is the GENERATED lesson's roadmap, the
  /// counterpart of [RouteNamed.courseRoadmap]; it was already laid out for a
  /// visible pill (its scroll padding and floating CTA both measure
  /// `floatingNavBarHeight`), it was just never named here, so the nav vanished
  /// the moment a reader opened one of their own lessons.
  List<String> get primaryRouteNames {
    return [
      RouteNamed.shellRoute,
      RouteNamed.home,
      RouteNamed.course,
      RouteNamed.courseRoadmap,
      RouteNamed.lessonReader,
      RouteNamed.profile,
      RouteNamed.habit,
    ];
  }
}