part of '../../knowledge_graph.dart';

/// Trạng thái của MỘT lần nạp dữ liệu. Ba nhánh tìm kiếm / hồ sơ / liên quan
/// giữ trạng thái riêng vì chúng chạy độc lập: hồ sơ hỏng không được kéo theo
/// danh sách liên quan biến mất, và ngược lại.
enum KgStatus { initial, loading, success, failure }

@freezed
abstract class KnowledgeGraphState with _$KnowledgeGraphState {
  const factory KnowledgeGraphState({
    @Default('') String query,
    @Default(KgStatus.initial) KgStatus searchStatus,
    @Default(<KgEntitySummary>[]) List<KgEntitySummary> results,
    @Default('') String searchError,
    @Default(KgStatus.initial) KgStatus profileStatus,
    KgEntityProfile? profile,
    @Default('') String profileError,
    @Default(KgStatus.initial) KgStatus relatedStatus,
    @Default(<KgRelatedEntity>[]) List<KgRelatedEntity> related,
  }) = _KnowledgeGraphState;

  factory KnowledgeGraphState.initial() => const KnowledgeGraphState();
}

extension KnowledgeGraphStateX on KnowledgeGraphState {
  bool get isSearching => searchStatus == KgStatus.loading;

  /// Rỗng THẬT: đã hỏi server xong và không có gì. Phân biệt với lúc chưa hỏi
  /// (initial) để màn hình không nháy "không tìm thấy" ngay khi vừa mở.
  bool get hasNoResult =>
      searchStatus == KgStatus.success && results.isEmpty;

  bool get isProfileLoading => profileStatus == KgStatus.loading;

  bool get hasProfile => profileStatus == KgStatus.success && profile != null;
}
