part of '../../auth.dart';

@freezed
abstract class TokenModel with _$TokenModel {
  const factory TokenModel({
    @Default('') String accessToken,
    @Default('') String refreshToken,
    DateTime? expiresAt,
  }) = _TokenModel;

  factory TokenModel.fromJson(Map<String, dynamic> json) => _$TokenModelFromJson(json);
}

extension TokenModelExtension on TokenModel {
  TokenEntity toEntity() => TokenEntity(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
      );
}