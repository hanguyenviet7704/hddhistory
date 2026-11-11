import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

/** Một khoá tham gia đợt, và hai tag làm hai nhánh của nó. */
export interface IExperimentArm {
  courseId: string;
  tagA: string;
  tagB: string;
}

/**
 * Một đợt A/B nội dung khoá học.
 *
 * KHÔNG có bảng gán nhánh: nhánh tính lại bằng `experimentBucket(key, userId)`
 * mỗi lần resolve, nên ổn định cho một người mà không sinh row nào, và tra lại
 * được về sau chỉ từ `key` + `userId`. Cũng vì thế `key` PHẢI đổi mỗi đợt —
 * dùng lại là trả mọi người về đúng nhánh cũ, biến đợt mới thành phần tiếp của
 * đợt cũ.
 *
 * Một đợt phủ NHIỀU khoá và một người ở cùng một nhánh xuyên mọi khoá trong
 * đợt (vì hash chỉ ăn `key` + `userId`), nên đo được một *lối viết* thay vì
 * chỉ đo một khoá — và cỡ mẫu được gộp.
 *
 * Có chủ ý không phải framework thí nghiệm tổng quát: đợt sau sẽ muốn chỉ số
 * và bảng đọc riêng của nó. Xem ghi chú trên `PaywallBodyExperimentDto`.
 */
@Schema({ collection: 'course_content_experiments' })
export class CourseContentExperiment extends AbstractDocument {
  @Prop({ required: true })
  key: string;

  @Prop({ default: false })
  enabled: boolean;

  /**
   * Mốc so với `UserProgress.createdAt` để quyết ai vào đợt. Người đã học khoá
   * đó từ trước mốc này giữ nguyên tag đang phát hành.
   */
  @Prop({ type: Date, required: true })
  startedAt: Date;

  @Prop({ type: Date, default: null })
  endedAt?: Date | null;

  /** Tỉ lệ vào nhánh B. 0 và 100 hợp lệ để thu hẹp đợt mà không xoá `key`. */
  @Prop({ type: Number, required: true, min: 0, max: 100 })
  percentB: number;

  @Prop({ type: SchemaTypes.Array, default: [] })
  arms: IExperimentArm[];

  @Prop({ type: String, default: null })
  note?: string | null;
}

export const CourseContentExperimentSchema = SchemaFactory.createForClass(
  CourseContentExperiment,
);

// `key` là thứ số liệu đã đóng dấu; trùng key là trộn hai đợt vào một phễu.
CourseContentExperimentSchema.index({ key: 1 }, { unique: true });

// Đường serve: "khoá này có đợt nào đang chạy không".
CourseContentExperimentSchema.index({ enabled: 1, 'arms.courseId': 1 });
