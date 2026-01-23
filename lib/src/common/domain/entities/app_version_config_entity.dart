part of '../../common.dart';

@freezed
abstract class AppVersionConfigEntity with _$AppVersionConfigEntity {
  const factory AppVersionConfigEntity({
    @Default(false) bool forceUserUpdate,
    @Default('') String latestAndroidVersion,
    @Default('') String latestIosVersion,
  }) = _AppVersionConfigEntity;

  factory AppVersionConfigEntity.fromJson(Map<String, dynamic> json) => _$AppVersionConfigEntityFromJson(json);
}