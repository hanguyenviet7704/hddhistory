part of '../../auth.dart';

@freezed
abstract class AuthModel with _$AuthModel {
  const factory AuthModel({
    @Default('') String id,
    @Default(TokenModel()) TokenModel token,
    @Default(UserModel()) UserModel user,
  }) = _AuthModel;


  factory AuthModel.fromJson(Map<String, dynamic> json) => _$AuthModelFromJson(json);
}

extension AuthModelExtension on AuthModel {
  AuthEntity toEntity() => AuthEntity(
        id: id,
        token: token.toEntity(),
        user: user.toEntity(),
      );
}