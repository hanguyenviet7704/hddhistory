part of '../models.dart';

@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    @Default('') String id,
    @Default('') String userId,
    @Default('') String nickname,
    @Default('') String avatarUrl,
    @Default('') String skillLevel,
    @Default('') String preferredLanguage,
    @Default([]) List<ActiveProduct> activeSubscriptions,
    @Default(<String, dynamic>{}) Map<String, dynamic> preferences,
    @Default(0) int boosterUsesRemaining,
    @Default(0) int numberLessonCompleted,
    @Default(ProfileGeolocation()) ProfileGeolocation geolocation,
    @Default(ProfileTimestamps()) ProfileTimestamps timestamps,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
}

extension ProfileExtension on List<Query$GetMyProfile$myProfiles> {
  List<Profile> toProfiles() => map((e) => Profile.fromJson(e.toJson())).toList();
}
