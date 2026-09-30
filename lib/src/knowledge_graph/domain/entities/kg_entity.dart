part of '../../knowledge_graph.dart';

/// Loại thực thể trong đồ thị tri thức lịch sử.
///
/// Giá trị `@JsonValue` khớp trường `type` mà API trả về
/// (`/api/v1/knowledge-graph/entities`). [unknown] là bậc thang an toàn: dữ
/// liệu lịch sử còn được bổ sung dần, một loại mới ở server không được phép
/// làm hỏng màn hình của bản app đang chạy.
enum KgEntityType {
  @JsonValue('figure')
  figure,
  @JsonValue('event')
  event,
  @JsonValue('organization')
  organization,
  @JsonValue('place')
  place,
  @JsonValue('unknown')
  unknown,
}

/// Một thời kỳ lịch sử. [start] và [end] là chuỗi năm chứ không phải
/// [DateTime]: dữ liệu có cả mốc trước Công nguyên và cả mốc chỉ biết tới năm,
/// hai thứ mà [DateTime] diễn đạt sai.
@freezed
abstract class KgPeriod with _$KgPeriod {
  const factory KgPeriod({
    required String id,
    required String name,
    @Default('') String start,
    @Default('') String end,
  }) = _KgPeriod;
}

/// Một nguồn sử liệu được trích dẫn cho thực thể.
@freezed
abstract class KgSource with _$KgSource {
  const factory KgSource({
    required String id,
    required String title,
    String? note,
  }) = _KgSource;
}

/// Thực thể ở dạng rút gọn — dùng cho danh sách kết quả tìm kiếm và cho đầu
/// kia của một quan hệ.
@freezed
abstract class KgEntitySummary with _$KgEntitySummary {
  const factory KgEntitySummary({
    required String id,
    required KgEntityType type,
    required String name,
    String? description,
  }) = _KgEntitySummary;
}

/// Một quan hệ đã gắn sẵn thực thể ở đầu kia.
///
/// [relation] là mã quan hệ thô của đồ thị (`led`, `founded`, `child_of`…);
/// việc dịch sang tiếng người là của tầng hiển thị, xem `kgRelationLabel`.
@freezed
abstract class KgRelation with _$KgRelation {
  const factory KgRelation({
    required String relation,
    required KgEntitySummary entity,
  }) = _KgRelation;
}

/// Hồ sơ đầy đủ của một thực thể: là ai, đã làm gì, ai nhắc tới, nguồn ở đâu.
@freezed
abstract class KgEntityProfile with _$KgEntityProfile {
  const factory KgEntityProfile({
    required String id,
    required KgEntityType type,
    required String name,
    String? description,
    String? note,
    KgPeriod? period,

    /// Quan hệ mà thực thể này là chủ thể — phần "đã làm gì".
    @Default(<KgRelation>[]) List<KgRelation> outgoing,

    /// Quan hệ mà thực thể này là đối tượng — phần "được ai nhắc tới".
    @Default(<KgRelation>[]) List<KgRelation> incoming,
    @Default(<KgEntitySummary>[]) List<KgEntitySummary> samePeriod,
    @Default(<KgSource>[]) List<KgSource> sources,
  }) = _KgEntityProfile;
}

/// Một thực thể liên quan, kèm khoảng cách trên đồ thị.
@freezed
abstract class KgRelatedEntity with _$KgRelatedEntity {
  const factory KgRelatedEntity({
    required String id,
    required KgEntityType type,
    required String name,
    String? description,

    /// Số bước ngắn nhất từ thực thể gốc tới thực thể này.
    @Default(1) int hops,

    /// Các loại quan hệ nối hai thực thể trên đường đi ngắn nhất.
    @Default(<String>[]) List<String> via,
  }) = _KgRelatedEntity;
}
