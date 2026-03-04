part of '../../learning_streak.dart';

@freezed
abstract class UserLearningStreakModel with _$UserLearningStreakModel {
  const factory UserLearningStreakModel({
    @Default('') String id,
    @Default('') String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserLearningStreakModel;


  factory UserLearningStreakModel.fromJson(Map<String, dynamic> json) => _$UserLearningStreakModelFromJson(json);
}

extension UserLearningStreakModelExtension on UserLearningStreakModel {
  UserLearningStreakEntity toEntity() => UserLearningStreakEntity(
        id: id,
        name: name,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

