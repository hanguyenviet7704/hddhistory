part of '../../profile.dart';

@freezed
abstract class UserEntity with _$UserEntity {
  const factory UserEntity({
    @Default('') String id,
    @Default('') String name,
    @Default('') String email,
    @Default('') String phone,
    @Default('') String age,
    @Default('') String gender,
    @Default(UserAccountStatus.active) UserAccountStatus status,
    @Default('') String language,
    @Default('') String country,
    @Default(UserLastActionEntity()) UserLastActionEntity lastAction,
    @Default('') String avatar,
    @Default(UserRole.user) UserRole role,
    @Default('') String provider,
    @Default('') String enery,
    @Default(OnboardEntity()) OnboardEntity onboarding,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserEntity;

  factory UserEntity.fromJson(Map<String, dynamic> json) => _$UserEntityFromJson(json);
}
