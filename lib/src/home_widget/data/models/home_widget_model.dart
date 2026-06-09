part of '../../home_widget.dart';

@freezed
abstract class HomeWidgetModel with _$HomeWidgetModel {
  const factory HomeWidgetModel({
    @Default('') String id,
    @Default('') String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _HomeWidgetModel;


  factory HomeWidgetModel.fromJson(Map<String, dynamic> json) => _$HomeWidgetModelFromJson(json);
}

extension HomeWidgetModelExtension on HomeWidgetModel {
  HomeWidgetEntity toEntity() => HomeWidgetEntity(
        id: id,
        name: name,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

