import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

/**
 * Một dòng cho mỗi thao tác GHI mà một tài khoản ADMIN thực hiện.
 *
 * Ghi tự động bởi một interceptor toàn cục, không phải bởi từng controller.
 * Đó là điều kiện để nó nói thật: một nhật ký phải được gọi ở hai trăm chỗ là
 * một nhật ký sẽ thiếu đúng chỗ người ta cần tra, và mọi endpoint viết sau này
 * đều bắt đầu bằng việc quên gọi nó.
 *
 * Lọc theo VAI TRÒ chứ không theo đường dẫn: chỉ `role === ADMIN` mới vào sổ.
 * Đó cũng là thứ giữ bảng này khỏi phình — cùng một API phục vụ cả app, và mỗi
 * lượt Coach, mỗi bước tiến độ đều là một lệnh ghi.
 */
@Schema({ collection: 'admin_audit_logs', timestamps: true })
export class AdminAuditLog extends AbstractDocument {
  /** Ai. Ghi cả email lẫn tên, vì một tài khoản có thể bị xoá sau này. */
  @Prop({ type: String, required: true, index: true })
  actorId: string;

  @Prop({ type: String, default: '' })
  actorEmail: string;

  @Prop({ type: String, default: '' })
  actorName: string;

  /** Làm gì: `PUT /api/v1/paywall-config`. */
  @Prop({ type: String, required: true })
  method: string;

  @Prop({ type: String, required: true, index: true })
  path: string;

  /**
   * Đường dẫn CÓ tham số, ví dụ `/coach-situations/:id`.
   *
   * Lưu riêng khỏi `path` để lọc được theo loại thao tác mà không bị mỗi id
   * tách thành một nhóm. Rỗng khi Nest không dựng được — không phải mọi route
   * đều có mẫu.
   */
  @Prop({ type: String, default: '', index: true })
  route: string;

  /** Kết quả. Thất bại cũng vào sổ: "ai đã THỬ làm gì" là một câu hỏi thật. */
  @Prop({ type: Number, default: 0 })
  statusCode: number;

  @Prop({ type: Boolean, default: true, index: true })
  ok: boolean;

  /** Thông báo lỗi khi thao tác hỏng, cắt ngắn. Rỗng khi thành công. */
  @Prop({ type: String, default: '' })
  errorMessage: string;

  /**
   * Nội dung đã gửi lên, ĐÃ che secret và cắt ngắn.
   *
   * Lưu chuỗi chứ không lưu object: thân của một lần đăng cấu hình paywall là
   * một cây sâu và không đồng nhất, mà nhật ký thì chỉ cần đọc lại chứ không
   * bao giờ truy vấn vào bên trong nó. Lưu như chuỗi thì không có schema nào
   * để lệch, và không có field nào vô tình trở thành chỉ mục.
   */
  @Prop({ type: String, default: '' })
  body: string;

  /** True khi `body` đã bị cắt vì quá dài — để giao diện nói rõ là chưa đủ. */
  @Prop({ type: Boolean, default: false })
  bodyTruncated: boolean;

  @Prop({ type: Number, default: 0 })
  durationMs: number;

  /** Ngày theo giờ máy chủ, `YYYY-MM-DD` — để lọc theo ngày khỏi phải quét. */
  @Prop({ type: String, required: true, index: true })
  serverDate: string;
}

export const AdminAuditLogSchema = SchemaFactory.createForClass(AdminAuditLog);

// Truy vấn duy nhất của trang: một khoảng ngày, mới nhất lên đầu.
AdminAuditLogSchema.index({ createdAt: -1 });
AdminAuditLogSchema.index({ serverDate: 1, actorId: 1 });
