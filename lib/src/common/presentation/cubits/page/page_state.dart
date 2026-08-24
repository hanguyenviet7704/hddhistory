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
  /// A place you STAND belongs here; a thing you are in the middle of does not —
  /// so both roadmaps and the shelf that lists your own lessons keep the pill,
  /// while the reading surfaces (lesson, roleplay, warm-up, the import form) take
  /// the screen.
  ///
  /// [RouteNamed.lessonReader] is the GENERATED lesson's roadmap, the counterpart
  /// of [RouteNamed.courseRoadmap], and [RouteNamed.myLessons] is its shelf. Both
  /// were already laid out for a visible pill — their scroll padding (and the
  /// roadmap's floating CTA) measure `floatingNavBarHeight` — and were simply
  /// never named here, so the nav vanished the moment a reader stepped into their
  /// own lessons and there was no way back to another tab except the back arrow.
  List<String> get primaryRouteNames {
    return [
      RouteNamed.shellRoute,
      RouteNamed.home,
      RouteNamed.course,
      RouteNamed.courseRoadmap,
      RouteNamed.myLessons,
      RouteNamed.lessonReader,
      RouteNamed.profile,
      RouteNamed.habit,
      RouteNamed.library,
      // My history is a shelf you browse, not a step in a flow — same call as
      // [RouteNamed.myLessons] beside it. It also has no tab of its own, so
      // hiding the pill here would leave the back arrow as the only way out of
      // the Library branch.
      RouteNamed.libraryHistory,
      // The community hub is a tab; without its name here the pill vanished the
      // moment the fifth tab was opened, leaving no way to any other tab.
      RouteNamed.community,
      // A topic keeps the pill too — design `S-03` draws the nav bar on it. The
      // post, weekly and compose screens deliberately do NOT appear here: those
      // take the whole screen in the design, and their own back arrow is the way
      // out.
      RouteNamed.communityTopic,
    ];
  }
}