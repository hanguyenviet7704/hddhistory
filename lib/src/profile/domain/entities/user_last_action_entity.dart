part of '../../profile.dart';

@freezed
abstract class UserLastActionEntity with _$UserLastActionEntity {
  const factory UserLastActionEntity({
    DateTime? time,
    @Default('') String action,
  }) = _UserLastActionEntity;

  factory UserLastActionEntity.fromJson(Map<String, dynamic> json) => _$UserLastActionEntityFromJson(json);
}

