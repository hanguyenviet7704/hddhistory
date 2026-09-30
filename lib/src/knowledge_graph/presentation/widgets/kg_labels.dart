part of '../../knowledge_graph.dart';

/// Nhãn tiếng Việt cho 35 loại quan hệ trong đồ thị.
///
/// CỐ Ý không đi qua slang, khác phần còn lại của app. Bản thân dữ liệu đồ thị
/// (tên nhân vật, mô tả, tên thời kỳ) chỉ có tiếng Việt và do server trả về,
/// nên dịch riêng mấy cái nhãn nối giữa chúng sang 5 ngôn ngữ sẽ cho ra những
/// câu nửa Anh nửa Việt chứ không giúp ai đọc được. Khi nào dữ liệu đồ thị có
/// bản đa ngữ thì chuyển cả cụm này sang slang một thể.
const Map<String, String> _kKgRelationLabels = {
  'served': 'phụng sự',
  'led': 'lãnh đạo',
  'founded': 'sáng lập',
  'opposed': 'chống lại',
  'participated_in': 'tham gia',
  'succeeded': 'kế vị',
  'contemporary_with': 'cùng thời với',
  'part_of': 'thuộc về',
  'child_of': 'là con của',
  'followed': 'nối tiếp',
  'resulted_in': 'dẫn đến kết quả',
  'initiated': 'khởi xướng',
  'preceded': 'diễn ra trước',
  'considered_ancestor_of': 'được coi là tổ tiên của',
  'built': 'xây dựng',
  'occurred_at': 'diễn ra tại',
  'border_at': 'giáp ranh tại',
  'capital_at': 'đóng đô tại',
  'ended': 'kết thúc',
  'married': 'kết hôn với',
  'conquered': 'chinh phục',
  'ruled_during': 'trị vì trong',
  'enacted': 'ban hành',
  'controlled': 'kiểm soát',
  'defeated': 'đánh bại',
  'authored': 'soạn thảo',
  'ruled': 'trị vì',
  'moved_capital_to': 'dời đô về',
  'led_to': 'dẫn tới',
  'imposed_on': 'áp đặt lên',
  'declared': 'tuyên bố',
  'commissioned_by': 'được lệnh từ',
  'developed': 'phát triển',
  'allied_with': 'liên minh với',
  'renamed_from': 'đổi tên từ',
};

/// Nhãn của một loại quan hệ. Mã lạ (dữ liệu được soạn tiếp ở server) rơi về
/// dạng đọc được — `moved_capital_to` thành `moved capital to` — chứ không
/// hiện mã trần có gạch dưới.
String kgRelationLabel(String relation) =>
    _kKgRelationLabels[relation] ?? relation.replaceAll('_', ' ');

/// Nhãn loại thực thể, lấy từ slang (đây là chữ của app, không phải chữ của
/// dữ liệu, nên vẫn dịch đủ 5 ngôn ngữ).
String kgEntityTypeLabel(BuildContext context, KgEntityType type) {
  final l10n = context.l10n.knowledgeGraph;
  return switch (type) {
    KgEntityType.figure => l10n.typeFigure,
    KgEntityType.event => l10n.typeEvent,
    KgEntityType.organization => l10n.typeOrganization,
    KgEntityType.place => l10n.typePlace,
    KgEntityType.unknown => l10n.typeUnknown,
  };
}

IconData kgEntityTypeIcon(KgEntityType type) => switch (type) {
  KgEntityType.figure => Icons.person_rounded,
  KgEntityType.event => Icons.flag_rounded,
  KgEntityType.organization => Icons.account_balance_rounded,
  KgEntityType.place => Icons.place_rounded,
  KgEntityType.unknown => Icons.help_outline_rounded,
};

/// Màu nền huy hiệu loại thực thể. Lấy từ thang màu thương hiệu chứ không
/// bịa mã hex mới, để tính năng này đổi màu cùng phần còn lại của app.
Color kgEntityTypeColor(KgEntityType type) => switch (type) {
  KgEntityType.figure => AppCustomColor.brandPrimary,
  KgEntityType.event => AppCustomColor.brandPrimary700,
  KgEntityType.organization => AppCustomColor.brandPrimary300,
  KgEntityType.place => AppCustomColor.successGreen,
  KgEntityType.unknown => AppCustomColor.textTertiary,
};

/// "1225 – 1400", hoặc chỉ một đầu nếu đầu kia trống.
String kgPeriodRange(KgPeriod period) {
  if (period.start.isEmpty && period.end.isEmpty) return '';
  if (period.end.isEmpty) return period.start;
  if (period.start.isEmpty) return period.end;
  return '${period.start} – ${period.end}';
}
