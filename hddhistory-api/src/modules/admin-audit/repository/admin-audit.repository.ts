import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { AdminAuditLog } from '../schema/admin-audit.schema';

@Injectable()
export class AdminAuditRepository extends AbstractRepository<AdminAuditLog> {
  protected readonly logger = new Logger(AdminAuditRepository.name);

  constructor(
    @InjectModel(AdminAuditLog.name) model: Model<AdminAuditLog>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * Ghi một dòng, và KHÔNG BAO GIỜ ném.
   *
   * Người gọi là một thao tác đã chạy xong và đã trả lời người dùng. Một lần
   * chèn nhật ký hỏng mà làm nổi lỗi lên thì biến một thao tác thành công
   * thành một thao tác báo lỗi — nhật ký không được phép đắt đến thế.
   */
  async record(row: Partial<AdminAuditLog>): Promise<void> {
    try {
      await this.model.create(row);
    } catch (error: any) {
      this.logger.warn(`Không ghi được nhật ký admin: ${error?.message}`);
    }
  }

  /** Một trang nhật ký, mới nhất lên đầu. */
  async page(params: {
    where: FilterQuery<AdminAuditLog>;
    skip: number;
    limit: number;
  }): Promise<{ items: AdminAuditLog[]; total: number }> {
    const [items, total] = await Promise.all([
      this.model
        .find(params.where)
        .sort({ createdAt: -1 })
        .skip(params.skip)
        .limit(params.limit)
        .lean<AdminAuditLog[]>(),
      this.model.countDocuments(params.where),
    ]);

    return { items, total };
  }

  async byId(id: string): Promise<AdminAuditLog | null> {
    return this.model.findById(id).lean<AdminAuditLog>();
  }

  /**
   * Lần ghi ngay TRƯỚC dòng này, trên cùng một đường dẫn.
   *
   * Đây là "trạng thái trước" để so ra thay đổi. Cùng `path` chứ không cùng
   * `route`: hai lần lưu của CÙNG một bản ghi mới so được với nhau, mà `route`
   * gộp mọi id vào một mẫu.
   */
  async previousFor(row: AdminAuditLog): Promise<AdminAuditLog | null> {
    return this.model
      .findOne({
        path: row.path,
        method: row.method,
        ok: true,
        _id: { $ne: row._id },
        createdAt: { $lt: (row as unknown as { createdAt: Date }).createdAt },
      })
      .sort({ createdAt: -1 })
      .lean<AdminAuditLog>();
  }

  /** Danh sách người đã từng thao tác, để giao diện dựng ô lọc. */
  async actors(): Promise<Array<{ id: string; email: string; name: string }>> {
    const rows = await this.model.aggregate<{
      _id: string;
      email: string;
      name: string;
    }>([
      { $sort: { createdAt: -1 } },
      {
        $group: {
          _id: '$actorId',
          email: { $first: '$actorEmail' },
          name: { $first: '$actorName' },
        },
      },
      { $sort: { email: 1 } },
      { $limit: 200 },
    ]);

    return rows.map(row => ({
      id: String(row._id),
      email: row.email ?? '',
      name: row.name ?? '',
    }));
  }
}
