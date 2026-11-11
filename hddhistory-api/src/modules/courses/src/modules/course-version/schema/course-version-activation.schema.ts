import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

/**
 * Sổ ghi "tag nào đang được phục vụ, từ lúc nào đến lúc nào" của một khoá.
 *
 * TẠI SAO PHẢI CÓ RIÊNG MỘT COLLECTION. Bảng so sánh phiên bản cần gán mỗi
 * event học tập về đúng tag mà người đó đã đọc. Chỉ có hai đường:
 *
 *  - theo nhánh A/B: app đóng dấu `content_variant`, đợt biết `tagA`/`tagB`.
 *    Nhưng thế thì CHỈ so được những tag từng nằm trong một đợt — phần lớn tag
 *    không nằm trong đợt nào, và cột "thấp nhất / cao nhất trong toàn bộ lịch
 *    sử khoá" của bảng so sánh sẽ luôn trống.
 *  - theo cửa sổ thời gian: event của khoá X lúc T thuộc về tag đang live ở
 *    thời điểm T. Áp được cho MỌI tag, và không cần app gửi thêm gì cả.
 *
 * Cái này là đường thứ hai. Không nhét `currentFrom`/`currentTo` vào
 * `course_content_versions` vì bất biến "hàng tag không bao giờ bị sửa sau khi
 * insert" của collection đó là thứ giữ cho một tag đã đóng băng thật sự đóng
 * băng — xem `course-content-version.schema.ts`.
 *
 * MỘT TAG CÓ THỂ CÓ NHIỀU CỬA SỔ. v1.0.0 → v1.0.1 → roll back về v1.0.0 cho
 * v1.0.0 hai đoạn rời nhau. Vì thế đây là log nhiều hàng chứ không phải một
 * hàng một tag, và mọi phép tính phải cộng dồn qua các đoạn.
 */
@Schema({ collection: 'course_version_activations' })
export class CourseVersionActivation extends AbstractDocument {
  @Prop({ required: true })
  courseId: string;

  @Prop({ required: true })
  versionId: string;

  /** Chép lại để bảng so sánh không phải join khi tag đã bị xoá. */
  @Prop({ required: true })
  tag: string;

  @Prop({ type: Date, required: true })
  from: Date;

  /** `null` = đang phục vụ. Đúng một hàng mỗi khoá được phép có `to: null`. */
  @Prop({ type: Date, default: null })
  to?: Date | null;
}

export const CourseVersionActivationSchema = SchemaFactory.createForClass(
  CourseVersionActivation,
);

// Đóng đoạn đang mở khi chuyển tag, và đọc "khoá này đang live tag nào".
CourseVersionActivationSchema.index({ courseId: 1, to: 1 });

// Dựng dải cửa sổ của một khoá theo thứ tự thời gian.
CourseVersionActivationSchema.index({ courseId: 1, from: -1 });
