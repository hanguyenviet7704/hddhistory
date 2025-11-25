part of '../../../profile.dart';

enum UploadStatus { initial, loading, success, failure }

@freezed
abstract class UploadState with _$UploadState {
  const factory UploadState({
    @Default(UploadStatus.initial) UploadStatus status,
    UploadEntity? uploadResult,
    String? errorMessage,
  }) = _UploadState;

  factory UploadState.initial() => UploadState();

  factory UploadState.fromJson(Map<String, dynamic> json) => _$UploadStateFromJson(json);
}
