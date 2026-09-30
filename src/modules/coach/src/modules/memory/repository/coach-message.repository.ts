import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { AbstractRepository } from '@base/database/mongodb/abstract.repository';

import { CoachMessage } from '../schema/coach-message.schema';

@Injectable()
export class CoachMessageRepository extends AbstractRepository<CoachMessage> {
  protected readonly logger = new Logger(CoachMessageRepository.name);

  constructor(
    @InjectModel(CoachMessage.name) model: Model<CoachMessage>,
    @InjectConnection() connection: Connection,
  ) {
    super(model, connection);
  }

  /** The whole conversation of one session, in order. */
  async findForSession(sessionId: string) {
    return this.model.find({ sessionId }).sort({ createdAt: 1 }).lean();
  }

  /**
   * Chỉ phần phiên CHƯA được cô đọng, cộng vài dòng trước đó làm ngữ cảnh.
   *
   * Bản cũ luôn đọc cả phiên, mà một phiên Home cô đọng lại mỗi sáu lượt: phiên
   * 24 lượt đọc 6+12+18+24 = 60 dòng cho 24 dòng thật, và trả tiền token cho
   * đúng phần chênh đó. Ở đây `lookback` là mấy dòng trước vạch — không có nó
   * thì đoạn mới mở đầu bằng một câu trả lời không có câu hỏi, và bản cô đọng
   * gán sai chủ thể.
   */
  async findForSessionAfter(
    sessionId: string,
    after: Date | null,
    lookback: number,
  ): Promise<{ lines: unknown[]; alreadyRead: number }> {
    if (!after) {
      return { lines: await this.findForSession(sessionId), alreadyRead: 0 };
    }

    const [fresh, context] = await Promise.all([
      this.model
        .find({ sessionId, createdAt: { $gt: after } })
        .sort({ createdAt: 1 })
        .lean(),
      lookback > 0
        ? this.model
            .find({ sessionId, createdAt: { $lte: after } })
            .sort({ createdAt: -1 })
            .limit(lookback)
            .lean()
        : Promise.resolve([]),
    ]);

    // `alreadyRead` đi kèm chứ không để chỗ gọi tự đoán: mấy dòng đầu là ngữ
    // cảnh ĐÃ được cô đọng một lần rồi. Đếm chúng như dòng mới thì (a) một
    // cửa sổ không có gì mới vẫn tiêu một call Gemini, và (b) model "nghe lại"
    // chuyện cũ nên `evidenceCount` tăng oan — mà cả tầng nhớ dựa trên đúng
    // con số đó để một phỏng đoán được lên thành chuyện chắc.
    return {
      lines: [...context.reverse(), ...fresh],
      alreadyRead: context.length,
    };
  }

  /**
   * Dò chữ NGUYÊN VĂN người ta đã nói, trong một cửa sổ các dòng gần nhất.
   *
   * Quét bằng regex trong cửa sổ chứ không dựng text index: text index bắt
   * Mongo trả giá ghi trên MỖI tin nhắn, còn lợi ích của nó chỉ xuất hiện đúng
   * lúc người ta hỏi về quá khứ. Cửa sổ có chặn trên nên chi phí không lớn theo
   * lịch sử.
   */
  async searchRecentForUser(
    userId: string,
    keywords: string[],
    scanLines: number,
    limit: number,
  ) {
    if (!keywords.length) return [];

    const rows = (await this.model
      .find({ userId })
      .sort({ createdAt: -1 })
      .limit(scanLines)
      .lean()) as Array<{ role: string; content: string; createdAt?: Date }>;

    const needles = keywords.map((word) => word.toLowerCase());

    return rows
      .filter((row) => {
        const content = (row.content ?? '').toLowerCase();

        return needles.some((needle) => content.includes(needle));
      })
      .slice(0, limit);
  }

  async recordMany(rows: Array<Record<string, unknown>>) {
    if (!rows.length) return;
    await this.model.insertMany(rows, { ordered: false });
  }

  /** Newest first, for one reader. */
  async findRecentForUser(userId: string, limit: number) {
    return this.model.find({ userId }).sort({ createdAt: -1 }).limit(limit).lean();
  }

  /**
   * Newest first, for one reader, SKIPPING one session — normally the session
   * being answered right now, whose lines the caller already has in
   * `session.turns`. Without the exclusion the current conversation would
   * appear twice in the prompt, once as history and once as itself.
   */
  async findRecentForUserExcludingSession(
    userId: string,
    sessionId: string,
    limit: number,
  ) {
    return this.model
      .find({ userId, sessionId: { $ne: sessionId } })
      .sort({ createdAt: -1 })
      .limit(limit)
      .lean();
  }
}
