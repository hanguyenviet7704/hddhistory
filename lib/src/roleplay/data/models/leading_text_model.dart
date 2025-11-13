part of '../../roleplay.dart';

@freezed
abstract class LeadingTextModel with _$LeadingTextModel {
  const factory LeadingTextModel({
    @Default('') String backgroundColor,
    @Default('') String textColor,
    @Default('') String content,
    @Default('') String audio,
  }) = _LeadingTextModel;

  factory LeadingTextModel.fromJson(Map<String, dynamic> json) => _$LeadingTextModelFromJson(json);
}

extension LeadingTextModelExtension on LeadingTextModel {
  LeadingTextEntity toEntity() => LeadingTextEntity(
    backgroundColor: backgroundColor,
    textColor: textColor,
    content: content,
    audio: audio,
  );
}
