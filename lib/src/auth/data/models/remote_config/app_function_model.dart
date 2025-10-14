part of '../models.dart';

@freezed
abstract class AppFunctionModel with _$AppFunctionModel {
  const factory AppFunctionModel({
    @Default(false) bool iap,
    @Default(false) bool roadmap,
    @Default(false) bool showFeedback,
  }) = _AppFunctionModel;

  factory AppFunctionModel.fromJson(Map<String, dynamic> json) => _$AppFunctionModelFromJson(json);
}