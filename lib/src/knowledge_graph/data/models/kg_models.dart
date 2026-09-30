part of '../../knowledge_graph.dart';

/// Hình dạng đường truyền của một thực thể rút gọn.
///
/// `unknownEnumValue` là bắt buộc chứ không phải phòng xa: dữ liệu lịch sử
/// đang được soạn tiếp, một loại thực thể mới ở server mà thiếu dòng này sẽ
/// làm cả danh sách ném lỗi giải mã thay vì bỏ qua một thẻ.
@freezed
abstract class KgEntitySummaryModel with _$KgEntitySummaryModel {
  const factory KgEntitySummaryModel({
    @Default('') String id,
    @JsonKey(unknownEnumValue: KgEntityType.unknown)
    @Default(KgEntityType.unknown)
    KgEntityType type,
    @Default('') String name,
    String? description,
  }) = _KgEntitySummaryModel;

  factory KgEntitySummaryModel.fromJson(Map<String, dynamic> json) =>
      _$KgEntitySummaryModelFromJson(json);
}

@freezed
abstract class KgPeriodModel with _$KgPeriodModel {
  const factory KgPeriodModel({
    @Default('') String id,
    @Default('') String name,
    @Default('') String start,
    @Default('') String end,
  }) = _KgPeriodModel;

  factory KgPeriodModel.fromJson(Map<String, dynamic> json) =>
      _$KgPeriodModelFromJson(json);
}

@freezed
abstract class KgSourceModel with _$KgSourceModel {
  const factory KgSourceModel({
    @Default('') String id,
    @Default('') String title,
    String? note,
  }) = _KgSourceModel;

  factory KgSourceModel.fromJson(Map<String, dynamic> json) =>
      _$KgSourceModelFromJson(json);
}

@freezed
abstract class KgRelationModel with _$KgRelationModel {
  const factory KgRelationModel({
    @Default('') String relation,
    KgEntitySummaryModel? entity,
  }) = _KgRelationModel;

  factory KgRelationModel.fromJson(Map<String, dynamic> json) =>
      _$KgRelationModelFromJson(json);
}

@freezed
abstract class KgEntityProfileModel with _$KgEntityProfileModel {
  const factory KgEntityProfileModel({
    @Default('') String id,
    @JsonKey(unknownEnumValue: KgEntityType.unknown)
    @Default(KgEntityType.unknown)
    KgEntityType type,
    @Default('') String name,
    String? description,
    String? note,
    KgPeriodModel? period,
    @Default(<KgRelationModel>[]) List<KgRelationModel> outgoing,
    @Default(<KgRelationModel>[]) List<KgRelationModel> incoming,
    @Default(<KgEntitySummaryModel>[]) List<KgEntitySummaryModel> samePeriod,
    @Default(<KgSourceModel>[]) List<KgSourceModel> sources,
  }) = _KgEntityProfileModel;

  factory KgEntityProfileModel.fromJson(Map<String, dynamic> json) =>
      _$KgEntityProfileModelFromJson(json);
}

@freezed
abstract class KgRelatedEntityModel with _$KgRelatedEntityModel {
  const factory KgRelatedEntityModel({
    @Default('') String id,
    @JsonKey(unknownEnumValue: KgEntityType.unknown)
    @Default(KgEntityType.unknown)
    KgEntityType type,
    @Default('') String name,
    String? description,
    @Default(1) int hops,
    @Default(<String>[]) List<String> via,
  }) = _KgRelatedEntityModel;

  factory KgRelatedEntityModel.fromJson(Map<String, dynamic> json) =>
      _$KgRelatedEntityModelFromJson(json);
}

extension KgEntitySummaryModelX on KgEntitySummaryModel {
  KgEntitySummary toEntity() => KgEntitySummary(
    id: id,
    type: type,
    name: name,
    description: description,
  );
}

extension KgPeriodModelX on KgPeriodModel {
  KgPeriod toEntity() => KgPeriod(id: id, name: name, start: start, end: end);
}

extension KgSourceModelX on KgSourceModel {
  KgSource toEntity() => KgSource(id: id, title: title, note: note);
}

extension KgEntityProfileModelX on KgEntityProfileModel {
  KgEntityProfile toEntity() => KgEntityProfile(
    id: id,
    type: type,
    name: name,
    description: description,
    note: note,
    period: period?.toEntity(),
    // Một quan hệ không có đầu kia là dữ liệu hỏng, không phải quan hệ rỗng —
    // bỏ hẳn thay vì dựng một thẻ không bấm được.
    outgoing: _relations(outgoing),
    incoming: _relations(incoming),
    samePeriod: samePeriod.map((m) => m.toEntity()).toList(),
    sources: sources.map((m) => m.toEntity()).toList(),
  );

  List<KgRelation> _relations(List<KgRelationModel> models) => models
      .where((m) => m.entity != null && m.entity!.id.isNotEmpty)
      .map((m) => KgRelation(relation: m.relation, entity: m.entity!.toEntity()))
      .toList();
}

extension KgRelatedEntityModelX on KgRelatedEntityModel {
  KgRelatedEntity toEntity() => KgRelatedEntity(
    id: id,
    type: type,
    name: name,
    description: description,
    hops: hops,
    via: via,
  );
}
