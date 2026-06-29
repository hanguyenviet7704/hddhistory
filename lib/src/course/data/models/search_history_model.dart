part of '../../course.dart';

@freezed
abstract class SearchHistoryModel with _$SearchHistoryModel {
  const factory SearchHistoryModel({
    @Default('') String query,
    DateTime? updatedAt,
  }) = _SearchHistoryModel;

  factory SearchHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$SearchHistoryModelFromJson(json);
}
