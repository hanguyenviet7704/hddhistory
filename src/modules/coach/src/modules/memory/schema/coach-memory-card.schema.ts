import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { ICoachMemoryCard } from '../interface/memory.interface';

/**
 * THẺ NHỚ — một dòng chữ dựng sẵn cho mỗi người, cộng câu chào cho lần mở sau.
 *
 * KHÔNG nằm trong `coach_profiles` dù cũng là một doc mỗi user: profile là điều
 * người ta TỰ KHAI (nghề, mục tiêu, rào cản) và được đọc mỗi lượt; thẻ là thứ
 * DẪN XUẤT, dựng lại được từ bốn collection kia bất cứ lúc nào, và bị ghi lại
 * sau mỗi lần cô đọng. Trộn hai vòng đời vào một doc nghĩa là mỗi phiên kết
 * thúc lại ghi đè lên doc đang bị đọc ở đường nóng.
 */
@Schema({ collection: 'coach_memory_cards', timestamps: true })
export class CoachMemoryCard extends AbstractDocument implements ICoachMemoryCard {
  @Prop({ type: String, required: true })
  userId: string;

  /** Cap cứng `MEMORY_CARD_MAX_CHARS` — xem `buildMemoryCard`. */
  @Prop({ type: String, default: null })
  card?: string | null;

  /**
   * Mảnh chủ đề của câu chào mở phiên sau, ≤`MEMORY_GREETING_TOPIC_MAX_CHARS`.
   *
   * Chỉ mảnh này là chữ sinh ra; khung câu là `coach.prompt.hubBack` bên client.
   */
  @Prop({ type: String, default: null })
  greetingTopic?: string | null;

  /**
   * Ngôn ngữ lúc viết mảnh đó. Người ta đổi ngôn ngữ app giữa hai phiên thì câu
   * chào phải im lặng chứ không được chào bằng tiếng cũ.
   */
  @Prop({ type: String, default: null })
  greetingLocale?: string | null;

  /** Đã chào bằng mảnh này rồi. Chào một lần, không nhắc lại cùng một chuyện. */
  @Prop({ type: Date, default: null })
  greetingUsedAt?: Date | null;

  @Prop({ type: Date, default: null })
  builtAt?: Date | null;

  @Prop({ type: String, default: null })
  builtFromSessionId?: string | null;
}

export const CoachMemoryCardSchema = SchemaFactory.createForClass(CoachMemoryCard);
CoachMemoryCardSchema.index({ userId: 1 }, { unique: true });
