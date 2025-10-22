part of '../../auth.dart';

@freezed
abstract class AuthEntity with _$AuthEntity {
  const factory AuthEntity({
    @Default('') String id,
    @Default(TokenEntity()) TokenEntity token,
    @Default(UserEntity()) UserEntity user,
  }) = _AuthEntity;

  factory AuthEntity.fromJson(Map<String, dynamic> json) => _$AuthEntityFromJson(json);
}
