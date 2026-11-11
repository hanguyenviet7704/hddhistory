import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

/**
 * One row per (user, campaign) they tapped — the reason a popup stops coming
 * back.
 *
 * Its OWN collection rather than an array on the user document: `users` is read
 * and written by nearly every feature, and a promotional image is no reason to
 * widen that blast radius. The lookup here is a single indexed `exists`.
 *
 * Dismissing is deliberately NOT recorded (product call, 2026-08-11): closing the
 * popup means "later", so it comes back next session, and only tapping retires it.
 */
@Schema({ collection: 'home_popup_clicks' })
export class HomePopupClick extends AbstractDocument {
  @Prop({ type: String, required: true, index: true })
  userId: string;

  /**
   * Which creative was tapped — a short hash of image + link, computed by
   * `campaignKeyFor`, never stored on the config.
   *
   * Keying by CONTENT is what makes the popup reusable: a new image or link is a
   * new key, so everyone sees the new campaign even if they tapped the last one.
   * It also means restoring a previous creative correctly stays retired for the
   * people who already acted on it.
   */
  @Prop({ type: String, required: true })
  campaignKey: string;
}

export const HomePopupClickSchema = SchemaFactory.createForClass(HomePopupClick);

// One row per user per campaign; the write is an idempotent upsert against it.
HomePopupClickSchema.index({ userId: 1, campaignKey: 1 }, { unique: true });
