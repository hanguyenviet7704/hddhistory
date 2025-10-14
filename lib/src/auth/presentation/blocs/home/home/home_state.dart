part of '../../blocs.dart';

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState({
    @Default(HomeModule.draw) HomeModule homeModule,
  }) = _HomeState;

  factory HomeState.initial() => const HomeState();
}

enum HomeModule {
  draw,
  handfeeling,
  pictureStudy;

  static HomeModule fromString(String name) {
    return switch (name) {
      'draw' => HomeModule.draw,
      'handfeeling' => HomeModule.handfeeling,
      'pictureStudy' => HomeModule.pictureStudy,
      _ => HomeModule.draw,
    };
  }
}