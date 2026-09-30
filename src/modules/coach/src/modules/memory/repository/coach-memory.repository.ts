import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CoachMemory } from '../schema/coach-memory.schema';

@Injectable()
export class CoachMemoryRepository extends AbstractRepository<CoachMemory> {
  protected readonly logger = new Logger(CoachMemoryRepository.name);

  constructor(
    @InjectModel(CoachMemory.name) model: Model<CoachMemory>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /**
   * What is worth handing the prompt: everything not retired, most confident
   * and most recently heard first. `possible` rows ride along — a possibility
   * is context too, just not something to announce.
   *
   * Còn dùng ở chỗ cô đọng (danh sách để model khớp id). Việc CHỌN dòng vào
   * thẻ thì đi qua `findRecentLiveForUser` + `rankByFreshness`: sort thuần
   * `confidence: -1` ở đây khiến một dòng đã leo tới 0.95 từ tháng trước chiếm
   * chỗ vĩnh viễn.
   */
  async findLiveForUser(userId: string, limit: number) {
    return this.model
      .find({ userId, status: { $ne: 'inactive' } })
      .sort({ confidence: -1, lastSeen: -1 })
      .limit(limit)
      .lean();
  }

  /**
   * Cửa sổ các dòng còn sống, MỚI NGHE TRƯỚC, để xếp lại theo điểm hiệu dụng
   * trong code (`rankByFreshness`).
   *
   * Xếp 30 dòng trong code rẻ hơn dựng một aggregate có luỹ thừa, và giữ được
   * luật xếp ở một hàm thuần pin được bằng spec.
   */
  async findRecentLiveForUser(userId: string, limit: number) {
    return this.model
      .find({ userId, status: { $ne: 'inactive' } })
      .sort({ lastSeen: -1 })
      .limit(limit)
      .lean();
  }

  async countLiveForUser(userId: string) {
    return this.model.countDocuments({ userId, status: { $ne: 'inactive' } });
  }

  /** Cho một dòng nghỉ. KHÔNG xoá: log thô vẫn là nguồn sự thật. */
  async retire(ids: unknown[]) {
    if (!ids.length) return;
    await this.model.updateMany(
      { _id: { $in: ids } },
      { $set: { status: 'inactive' } },
    );
  }

  async findByIdsForUser(userId: string, ids: string[]) {
    if (!ids.length) return [];

    return this.model.find({ userId, _id: { $in: ids } }).lean();
  }

  /** Newest first, for one reader. */
  async findRecentForUser(userId: string, limit: number) {
    return this.model.find({ userId }).sort({ createdAt: -1 }).limit(limit).lean();
  }
}
