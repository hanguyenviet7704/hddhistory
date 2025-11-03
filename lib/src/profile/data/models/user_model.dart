part of '../../profile.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    @Default('') String id,
    @Default('') String name,
    @Default('') String email,
    @Default('') String photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}

extension UserModelExtension on UserModel {
  UserEntity toEntity() => UserEntity(
    id: id,
    name: name,
    email: email,
    photoUrl: photoUrl,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
