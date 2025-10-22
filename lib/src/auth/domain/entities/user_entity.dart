part of '../../auth.dart';

@freezed
abstract class UserEntity with _$UserEntity {
  const factory UserEntity({
    @Default('') String id,
    @Default('') String name,
    @Default('') String email,
    @Default('') String photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserEntity;

  factory UserEntity.fromJson(Map<String, dynamic> json) => _$UserEntityFromJson(json);
}