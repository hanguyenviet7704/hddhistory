import { Injectable, NotFoundException } from '@nestjs/common';
import { FilterQuery } from 'mongoose';

import { AuditChange, diffBodies } from './admin-audit.diff';
import { GetAdminAuditDto } from './dto/admin-audit.dto';
import { AdminAuditRepository } from './repository/admin-audit.repository';
import { AdminAuditLog } from './schema/admin-audit.schema';

/** Cửa sổ mặc định khi không ai nói — đủ để truy "tuần trước ai sửa gì". */
const DEFAULT_WINDOW_DAYS = 14;
const DEFAULT_LIMIT = 50;

export function serverDateOf(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');

  return `${year}-${month}-${day}`;
}

@Injectable()
export class AdminAuditService {
  constructor(private readonly repository: AdminAuditRepository) {}

  /** Ghi một dòng. Không await được từ đường chính — xem repository. */
  record(row: Partial<AdminAuditLog>): void {
    void this.repository.record(row);
  }

  /**
   * Một dòng, kèm "đã đổi cái gì" so với lần lưu trước của cùng khu vực.
   *
   * Tính khi ĐỌC chứ không lưu sẵn: bản trước có thể bị xoá, và một thay đổi
   * tính sai lưu vào bảng thì sai vĩnh viễn, còn tính lúc đọc thì sửa được.
   */
  async detail(id: string) {
    const row = await this.repository.byId(id);
    if (!row) throw new NotFoundException('Không có dòng nhật ký này');

    const previous = await this.repository.previousFor(row);
    const changes: AuditChange[] | null = diffBodies(previous?.body, row.body, {
      beforeTruncated: previous?.bodyTruncated,
      afterTruncated: row.bodyTruncated,
    });

    return {
      row,
      /** Null = không so được; mảng rỗng = có bấm lưu nhưng không đổi gì. */
      changes,
      previousAt: previous
        ? (previous as unknown as { createdAt: Date }).createdAt
        : null,
      previousBy: previous?.actorName || previous?.actorEmail || null,
    };
  }

  async list(dto: GetAdminAuditDto) {
    const today = new Date();
    const to = dto.to ?? serverDateOf(today);
    const defaultFrom = new Date(today);
    defaultFrom.setDate(defaultFrom.getDate() - (DEFAULT_WINDOW_DAYS - 1));
    const from = dto.from ?? serverDateOf(defaultFrom);

    const where: FilterQuery<AdminAuditLog> = {
      serverDate: { $gte: from, $lte: to },
    };
    if (dto.actorId) where.actorId = dto.actorId;
    // Khớp một phần, để "paywall" tìm ra mọi endpoint của paywall. Escape
    // trước khi dựng regex: một dấu `(` người dùng gõ vào không được phép làm
    // hỏng truy vấn.
    if (dto.path) {
      where.path = { $regex: dto.path.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), $options: 'i' };
    }
    if (dto.result === 'failed') where.ok = false;
    if (dto.result === 'ok') where.ok = true;

    const limit = dto.limit ?? DEFAULT_LIMIT;
    const page = dto.page ?? 1;

    const [{ items, total }, actors] = await Promise.all([
      this.repository.page({ where, skip: (page - 1) * limit, limit }),
      this.repository.actors(),
    ]);

    return {
      range: { from, to },
      page,
      limit,
      total,
      items,
      /** Danh sách người để giao diện dựng ô lọc — không phải mọi admin, chỉ những ai đã từng thao tác. */
      actors,
    };
  }
}
