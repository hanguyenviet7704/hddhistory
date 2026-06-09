part of '../../home_widget.dart';

@freezed
abstract class HomeWidgetEntity with _$HomeWidgetEntity {
  const factory HomeWidgetEntity({
    @Default('') String id,
    @Default('') String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _HomeWidgetEntity;

  factory HomeWidgetEntity.fromJson(Map<String, dynamic> json) => _$HomeWidgetEntityFromJson(json);
}

