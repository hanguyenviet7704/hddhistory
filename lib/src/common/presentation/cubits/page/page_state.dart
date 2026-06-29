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

  List<String> get primaryRouteNames {
    return [
      RouteNamed.shellRoute,
      RouteNamed.home,
      RouteNamed.course,
      RouteNamed.courseRoadmap,
      RouteNamed.profile,
    ];
  }
}