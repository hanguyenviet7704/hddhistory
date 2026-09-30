import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { ITranslation } from '@utils/interface/common.interface';

export type SavedCardDocument = SavedCard & Document;

@Schema({ timestamps: true, collection: 'saved_cards' })
export class SavedCard extends AbstractDocument {
  @Prop({ required: true, index: true })
  userId: string;

  /** The keypoint whose recap card was saved — one card per keypoint. */
  @Prop({ required: true })
  keypointId: string;

  @Prop()
  lessonId: string;

  @Prop()
  courseId: string;

  /**
   * The recap text as the reader saw it, captured at save time.
   *
   * The card's back face is NOT a stored field on the keypoint: the app derives
   * it from the trailing single-page theory item of the lesson
   * (`resolveTakeawaySummary`), a positional heuristic that also strips the
   * authored heading line and inline HTML. Re-deriving that server-side would
   * mean a second implementation of the same rule, free to drift from the one
   * the reader actually saw. So the client sends the resolved text and this is
   * a snapshot — single-language by nature, since that is all the client had.
   *
   * Empty when the lesson had no takeaway item; the client then falls back to
   * the keypoint description, which IS multi-language and is returned alongside.
   */
  @Prop({ default: '' })
  recapText: string;

  /**
   * The same recap in every language the client had at save time.
   *
   * Added 2026-09-10 alongside — not instead of — `recapText`. Rows written
   * before this exist in production with a single string and no way to
   * recover the other languages; they keep reading from `recapText` and keep
   * behaving exactly as they did. Everything saved from here on carries all
   * five, so the card follows the app's language the way its title always has.
   */
  @Prop({ type: Object, default: {} })
  recap: ITranslation;
}

export const SavedCardSchema = SchemaFactory.createForClass(SavedCard);

// One card per (user, keypoint) — save is idempotent.
SavedCardSchema.index({ userId: 1, keypointId: 1 }, { unique: true });
// Most-recently-saved first, the order the grid and the deck read in.
SavedCardSchema.index({ userId: 1, createdAt: -1 });
