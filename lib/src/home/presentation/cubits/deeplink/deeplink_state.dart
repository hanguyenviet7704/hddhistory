part of '../../../home.dart';

@freezed
abstract class DeeplinkState with _$DeeplinkState {
  const factory DeeplinkState({
    @Default(0) int currentIndex,
    @Default('') String currentRouteName,
    @Default(false) bool isPassSplashScreen,
  }) = _DeeplinkState;

  factory DeeplinkState.initial() => const DeeplinkState();
}

extension DeeplinkStateX on DeeplinkState {
  bool get isAuthenticated => AppGlobalValue.accessToken.isNotEmpty;

  bool get isPrimaryRoute => primaryRouteNames.contains(currentRouteName);

  List<String> get primaryRouteNames {
    return [
      // RouteNamed.createPost,
      RouteNamed.shellRoute,
      RouteNamed.home,
      // RouteNamed.vnsShop,
      // RouteNamed.notification,
      // RouteNamed.profile,
    ];
  }
}
