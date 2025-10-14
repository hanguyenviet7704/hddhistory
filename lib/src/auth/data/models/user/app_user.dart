part of '../models.dart';

@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    @Default('') String id,
    @Default('') String aud,
    @Default('') String confirmationSentAt,
    @Default('') String recoverySentAt,
    @Default('') String emailChangeSentAt,
    @Default('') String newEmail,
    @Default('') String invitedAt,
    @Default('') String actionLink,
    @Default('') String email,
    @Default('') String phone,
    @Default('') String role,
    @Default(false) bool isAnonymous,
    @Default(UserMetaData()) UserMetaData userMetadata,
    @Default([]) List<Identity> identities,
    @Default(null) DateTime? createdAt,
    @Default(null) DateTime? emailConfirmedAt,
    @Default(null) DateTime? phoneConfirmedAt,
    @Default(null) DateTime? lastSignInAt,
    @Default(null) DateTime? updatedAt,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
}

@freezed
abstract class UserMetaData with _$UserMetaData {
  const factory UserMetaData({
    @Default('') String email,
    @Default('') String username,
    @Default(false) bool emailVerified,
    @Default(false) bool phoneVerified,
    @Default('') String sub,
  }) = _UserMetaData;

  factory UserMetaData.fromJson(Map<String, dynamic> json) => _$UserMetaDataFromJson(json);
}

@freezed
abstract class Identity with _$Identity {
  const factory Identity({
    @Default('') String identityId,
    @Default('') String id,
    @Default('') String userId,
    @Default('') String provider,
    @Default(null) DateTime? lastSignInAt,
    @Default(null) DateTime? createdAt,
    @Default(null) DateTime? updatedAt,
    @Default('') String email,
  }) = _Identity;

  factory Identity.fromJson(Map<String, dynamic> json) => _$IdentityFromJson(json);
}

enum UserRole {
  @JsonValue('user')
  user,
  @JsonValue('employee')
  employee,
  @JsonValue('admin')
  admin,
  @JsonValue('streamer')
  streamer,
  @JsonValue('digital')
  digital,
  @JsonValue('store')
  store,
  @JsonValue('censor')
  censor,
}

enum UserType {
  @JsonValue('suggested')
  suggested,
  @JsonValue('follower')
  follower,
  @JsonValue('following')
  following,
  @JsonValue('friend')
  friend;
}

extension AppUserExtension on AppUser {
  String get displayName => userMetadata.username.isEmpty ? email : emailDisplay;

  String get avatarUrl => '';

  String get birthdayDisplay {
    return '';
  }

  String get emailDisplay => email.isEmpty ? 'na' : email;

  bool get isHost => true;

  bool isHostCurrentLive(int hostId) => true;

  bool get isCensor => true;

  Widget avatarWidget({double width = 40, double height = 40, BorderRadius? borderRadius, void Function()? onTap}) {
    return DCachedImage(url: avatarUrl, width: width.w, height: height.w, borderRadius: borderRadius ?? BorderRadius.circular(width / 2), fit: BoxFit.cover, onTap: onTap);
  }

  Widget avatarWidgetAction({double width = 40, double height = 40, BorderRadius? borderRadius, void Function()? onTap}) {
    return DCachedImage(
      url: avatarUrl,
      width: width.w,
      height: height.w,
      borderRadius: borderRadius ?? BorderRadius.circular(width / 2),
      fit: BoxFit.cover,
      onTap:
          onTap ??
          () {
            if (id == AppConfig.instance.context!.read<UserCubit>().state.user.id) return;
            // DNavigator.goNamed(RouteNamed.profilePreview);
          },
    );
  }
}
