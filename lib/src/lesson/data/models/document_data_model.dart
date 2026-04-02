part of '../../lesson.dart';

@freezed
abstract class DocumentDataModel with _$DocumentDataModel {
  const factory DocumentDataModel({
    @Default(BaseMultiLanguage()) BaseMultiLanguage content,
    @Default(BaseMultiLanguage()) BaseMultiLanguage url,
    @Default('') String thumbnail,
    @Default([]) List<ExplanationOptionModel> options,
  }) = _DocumentDataModel;

  factory DocumentDataModel.fromJson(Map<String, dynamic> json) => _$DocumentDataModelFromJson(json);
}

extension DocumentDataModelExtension on DocumentDataModel {
  DocumentDataEntity toEntity() => DocumentDataEntity(
    content: content,
    url: url,
    thumbnail: thumbnail,
    options: options.map((o) => o.toEntity()).toList(),
  );
}
