part of '../../auth.dart';

@freezed
abstract class TokenEntity with _$TokenEntity {
  const factory TokenEntity({
    @Default('') String accessToken,
    @Default('') String refreshToken,
    DateTime? expiresAt,
  }) = _TokenEntity;

  factory TokenEntity.fromJson(Map<String, dynamic> json) => _$TokenEntityFromJson(json);
}