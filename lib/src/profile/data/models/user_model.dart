part of '../../profile.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    @Default('') @JsonKey(name: '_id') String id,
    @Default('') String name,
    @Default('') String email,
    @Default('') String phone,
    @Default('') String age,
    @Default('') String gender,
    @Default(UserAccountStatus.active) UserAccountStatus status,
    @Default('') String language,
    @Default('') String country,
    @Default(UserLastActionModel()) UserLastActionModel lastAction,
    @Default('') String avatar,
    @Default(UserRole.user) UserRole role,
    @Default('') String provider,
    @Default('') String enery,
    @Default(false) bool anonymous,
    // @Default(OnboardModel()) OnboardModel onboarding,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}

enum UserAccountStatus {
  @JsonValue('ACTIVE')
  active,
  @JsonValue('IN_ACTIVE')
  inActive,
}

enum UserRole {
  @JsonValue('ADMIN')
  admin,
  @JsonValue('USER')
  user,
}

extension UserStatusExtension on UserAccountStatus {
  String toJsonValue() {
    switch (this) {
      case UserAccountStatus.active:
        return 'ACTIVE';
      case UserAccountStatus.inActive:
        return 'IN_ACTIVE';
    }
  }
}

extension UserRoleExtension on UserRole {
  String toJsonValue() {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.user:
        return 'USER';
    }
  }
}

extension UserModelExtension on UserModel {
  UserEntity toEntity() => UserEntity(
    id: id,
    name: name,
    email: email,
    phone: phone,
    age: age,
    gender: gender,
    status: status,
    language: language,
    country: country,
    lastAction: lastAction.toEntity(),
    avatar: avatar,
    role: role,
    provider: provider,
    enery: enery,
    anonymous: anonymous,
    // onboarding: onboarding.toEntity(),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
