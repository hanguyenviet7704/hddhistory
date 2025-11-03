part of '../../lesson.dart';

@freezed
abstract class DocumentDataModel with _$DocumentDataModel {
  const factory DocumentDataModel({
    @Default('') String title,
    @Default('') String content,
    @Default('') String caption,
    @Default('') String url,
    @Default('') String thumbnail,
  }) = _DocumentDataModel;

  factory DocumentDataModel.fromJson(Map<String, dynamic> json) => _$DocumentDataModelFromJson(json);
}

extension DocumentDataModelExtension on DocumentDataModel {
  DocumentDataEntity toEntity() => DocumentDataEntity(
    title: title,
    content: content,
    caption: caption,
    url: url,
    thumbnail: thumbnail,
  );
}
