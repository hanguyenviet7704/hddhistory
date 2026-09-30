/**
 * Kiểu dữ liệu và nhãn hiển thị của đồ thị tri thức lịch sử.
 *
 * Chép cùng hình dạng với `hddhistory-flutter/lib/src/knowledge_graph` để web
 * và app đọc cùng một API mà không lệch nhau. Sửa một bên thì sửa cả hai.
 */

export type KgEntityType =
  | 'figure'
  | 'event'
  | 'organization'
  | 'place'
  | 'unknown';

export interface KgEntitySummary {
  id: string;
  type: KgEntityType;
  name: string;
  description?: string;
}

export interface KgPeriod {
  id: string;
  name: string;
  start: string;
  end: string;
}

export interface KgSource {
  id: string;
  title: string;
  note?: string;
}

export interface KgRelation {
  relation: string;
  entity: KgEntitySummary;
}

export interface KgEntityProfile extends KgEntitySummary {
  note?: string;
  period?: KgPeriod;
  /** Quan hệ mà thực thể này là chủ thể — phần "đã làm gì". */
  outgoing: KgRelation[];
  /** Quan hệ mà thực thể này là đối tượng — phần "được ai nhắc tới". */
  incoming: KgRelation[];
  samePeriod: KgEntitySummary[];
  sources: KgSource[];
}

export interface KgRelatedEntity extends KgEntitySummary {
  hops: number;
  via: string[];
}

/**
 * Nhãn tiếng Việt cho 35 loại quan hệ. Giữ khớp với
 * `kg_labels.dart` bên Flutter.
 */
const RELATION_LABELS: Record<string, string> = {
  served: 'phụng sự',
  led: 'lãnh đạo',
  founded: 'sáng lập',
  opposed: 'chống lại',
  participated_in: 'tham gia',
  succeeded: 'kế vị',
  contemporary_with: 'cùng thời với',
  part_of: 'thuộc về',
  child_of: 'là con của',
  followed: 'nối tiếp',
  resulted_in: 'dẫn đến kết quả',
  initiated: 'khởi xướng',
  preceded: 'diễn ra trước',
  considered_ancestor_of: 'được coi là tổ tiên của',
  built: 'xây dựng',
  occurred_at: 'diễn ra tại',
  border_at: 'giáp ranh tại',
  capital_at: 'đóng đô tại',
  ended: 'kết thúc',
  married: 'kết hôn với',
  conquered: 'chinh phục',
  ruled_during: 'trị vì trong',
  enacted: 'ban hành',
  controlled: 'kiểm soát',
  defeated: 'đánh bại',
  authored: 'soạn thảo',
  ruled: 'trị vì',
  moved_capital_to: 'dời đô về',
  led_to: 'dẫn tới',
  imposed_on: 'áp đặt lên',
  declared: 'tuyên bố',
  commissioned_by: 'được lệnh từ',
  developed: 'phát triển',
  allied_with: 'liên minh với',
  renamed_from: 'đổi tên từ',
};

/** Mã lạ rơi về dạng đọc được thay vì hiện gạch dưới. */
export function relationLabel(relation: string): string {
  return RELATION_LABELS[relation] ?? relation.replaceAll('_', ' ');
}

export const TYPE_LABELS: Record<KgEntityType, string> = {
  figure: 'Nhân vật',
  event: 'Sự kiện',
  organization: 'Triều đại / tổ chức',
  place: 'Địa danh',
  unknown: 'Khác',
};

/** Màu huy hiệu theo loại — lấy từ thang màu thương hiệu của app. */
export const TYPE_COLORS: Record<KgEntityType, string> = {
  figure: '#B8860B',
  event: '#7A5807',
  organization: '#DCB84A',
  place: '#41AE8C',
  unknown: '#7F8EA4',
};

/** "1225 – 1400", hoặc chỉ một đầu nếu đầu kia trống. */
export function periodRange(period: KgPeriod): string {
  if (!period.start && !period.end) return '';
  if (!period.end) return period.start;
  if (!period.start) return period.end;
  return `${period.start} – ${period.end}`;
}
