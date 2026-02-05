part of '../../profile.dart';

@freezed
abstract class UserLastActionModel with _$UserLastActionModel {
  const factory UserLastActionModel({
    DateTime? time,
    @Default('') String action,
  }) = _UserLastActionModel;

  factory UserLastActionModel.fromJson(Map<String, dynamic> json) => _$UserLastActionModelFromJson(json);
}

extension UserLastActionModelExtension on UserLastActionModel {
  UserLastActionEntity toEntity() => UserLastActionEntity(
    time: time,
    action: action,
  );
}
