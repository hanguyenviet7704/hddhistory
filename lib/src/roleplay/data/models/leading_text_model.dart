part of '../../roleplay.dart';

@freezed
abstract class LeadingTextModel with _$LeadingTextModel {
  const factory LeadingTextModel({
    @Default('') String frameColor,
    @Default('') String textColor,
    @Default('') String content,
  }) = _LeadingTextModel;

  factory LeadingTextModel.fromJson(Map<String, dynamic> json) => _$LeadingTextModelFromJson(json);
}

extension LeadingTextModelExtension on LeadingTextModel {
  LeadingTextEntity toEntity() => LeadingTextEntity(
    frameColor: frameColor,
    textColor: textColor,
    content: content,
  );
}
