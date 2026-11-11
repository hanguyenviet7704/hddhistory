part of '../services.dart';

/// Nhánh A/B nội dung mà server đã chia cho người này, giữ trong bộ nhớ để mọi
/// event học tập đóng dấu được nó.
///
/// Vì sao là holder tĩnh chứ không phải trạng thái truyền qua tham số: nhánh
/// phải xuất hiện trên ~30 event của khoá/bài/keypoint, và luồn thêm hai tham
/// số qua tất cả call site đó là churn lớn cho một dữ kiện chỉ đọc. Đây đúng
/// kiểu `AppEventService.instance` đang dùng trong `config/services`.
///
/// Nhớ theo `courseId` chứ không nhớ trần: người dùng đổi khoá liên tục, và
/// dán nhánh của khoá A lên event của khoá B là làm bẩn số liệu theo cách rất
/// khó truy. `paramsFor` trả rỗng khi id không khớp.
class ContentExperimentTracker {
  ContentExperimentTracker._();

  static final ContentExperimentTracker _instance = ContentExperimentTracker._();
  static ContentExperimentTracker get instance => _instance;

  /// Param app đóng dấu nhánh lên. Phải khớp `CONTENT_EXPERIMENT_PARAM` bên
  /// `hddhistory-api/src/modules/courses/src/modules/course-version/`.
  static const String variantParam = 'content_variant';

  /// Param đóng dấu đợt, để phễu không trộn hai đợt trùng khoảng thời gian.
  static const String keyParam = 'content_experiment_key';

  String? _courseId;
  String? _key;
  String? _arm;

  /// Gọi khi roadmap của một khoá vừa tải xong. `key`/`arm` rỗng hoặc null
  /// nghĩa là khoá này không trong đợt nào (hoặc người này bị loại khỏi đợt),
  /// và khi đó không đóng dấu gì cả.
  void remember({required String courseId, String? key, String? arm}) {
    if (courseId.isEmpty) return;
    _courseId = courseId;
    _key = (key?.isEmpty ?? true) ? null : key;
    _arm = (arm?.isEmpty ?? true) ? null : arm;
  }

  /// Params để trộn vào event của khoá này. Rỗng khi khoá không khớp hoặc
  /// không có đợt — đóng dấu sai còn tệ hơn không đóng dấu.
  Map<String, dynamic> paramsFor(String? courseId) {
    if (courseId == null || courseId.isEmpty) return const {};
    if (courseId != _courseId) return const {};
    if (_key == null || _arm == null) return const {};

    return {keyParam: _key!, variantParam: _arm!};
  }

  /// Chỉ dùng trong test.
  void reset() {
    _courseId = null;
    _key = null;
    _arm = null;
  }
}
