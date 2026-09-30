import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

// Singleton lookup key -- there is only ever one HomeBannerConfig document.
export const HOME_BANNER_CONFIG_KEY = 'default';

// No `timestamps: true` on purpose. AbstractDocument already declares
// createdAt/updatedAt as props and the repository sets them explicitly; adding
// Mongoose's automatic timestamps makes it write `updatedAt` too, and the
// upsert then dies with "Updating the path 'updatedAt' would create a conflict
// at 'updatedAt'" — a 500 on every read of this config.
/**
 * One slide of the Home carousel.
 *
 * `_id: false` -- slides are identified by their position in the array, which is
 * also the order they are shown in. Giving them ids would invite the admin to
 * PATCH one in isolation, and the whole config is saved as a unit.
 */
@Schema({ _id: false })
export class HomeBannerSlide {
  @Prop({
    type: String,
    default: '',
    comment:
      'Admin-facing campaign label ("Tết 2027 VN"). Never shown in the app',
  })
  name: string;

  @Prop({ type: String, default: '', comment: 'Slide image URL (R2 upload)' })
  imageUrl: string;

  @Prop({
    type: String,
    default: '',
    comment:
      'Where a tap lands: https:// URL or app deeplink. Empty = not tappable',
  })
  linkUrl: string;

  @Prop({
    type: [String],
    default: [],
    comment:
      'Per-slide market allow-list, upper-cased on write. EMPTY MEANS ' +
      'EVERY MARKET. Matched against the viewer resolved markets, so one ' +
      'config can carry a VN slide and a JP slide and each viewer only ever ' +
      'sees their own',
  })
  countries: string[];

  @Prop({
    type: [String],
    default: [],
    comment:
      'Per-slide language allow-list, lower-cased on write (vi, en, …). ' +
      'EMPTY MEANS EVERY LANGUAGE. Matched against the `lang` header the app ' +
      'already sends, so a VI creative and an EN creative can share one config',
  })
  locales: string[];

  @Prop({
    type: [String],
    default: [],
    comment:
      'Segment allow-list (segment document ids). EMPTY MEANS EVERYONE. ' +
      'Matching ANY listed segment is enough; a deleted segment id simply ' +
      'never matches',
  })
  segmentIds: string[];

  @Prop({
    type: Number,
    default: 0,
    comment:
      'Higher shows first; ties keep the array order, which remains the ' +
      '"thứ tự treo". Zero (the default) leaves the array order in charge',
  })
  priority: number;

  @Prop({
    type: Date,
    default: null,
    comment:
      'Campaign window start (server clock). Null = already started. Lets ' +
      'next week campaign be staged today and go live on its own',
  })
  startAt: Date | null;

  @Prop({
    type: Date,
    default: null,
    comment: 'Campaign window end (server clock). Null = never expires',
  })
  endAt: Date | null;

  @Prop({
    type: Boolean,
    default: true,
    comment:
      'Per-slide switch, so next week campaign can be staged with its image ' +
      'and link already saved. The document-level `enabled` is still the kill ' +
      'switch for the whole slot',
  })
  enabled: boolean;
}

export const HomeBannerSlideSchema =
  SchemaFactory.createForClass(HomeBannerSlide);

@Schema({ collection: 'home_banner_configs' })
export class HomeBannerConfig extends AbstractDocument {
  @Prop({ type: String, default: HOME_BANNER_CONFIG_KEY, unique: true })
  configKey: string;

  @Prop({
    type: Boolean,
    default: false,
    comment:
      'Kill switch -- the app hides the banner slot entirely while false, ' +
      'so a banner can be staged (image + link saved) before going live',
  })
  enabled: boolean;

  @Prop({
    type: [HomeBannerSlideSchema],
    default: [],
    comment:
      'The carousel, in display order. EMPTY falls back to the single-banner ' +
      'fields below, which is what lets this be added without a migration: ' +
      'documents written before slides existed keep showing their one banner ' +
      '(see resolveConfiguredSlides)',
  })
  slides: HomeBannerSlide[];

  @Prop({
    type: String,
    default: '',
    comment:
      'LEGACY single-banner image. Read only as the seed for slide 1 when ' +
      '`slides` is empty; the response also mirrors the first VISIBLE slide ' +
      'back into this field for app builds that predate the carousel',
  })
  imageUrl: string;

  @Prop({
    type: String,
    default: '',
    comment:
      'Where a tap lands: https:// URL or app deeplink. Empty = not tappable',
  })
  linkUrl: string;

  @Prop({
    type: [String],
    default: [],
    comment:
      'ISO-3166 alpha-2 allow-list, upper-cased on write. EMPTY MEANS ' +
      'EVERYWHERE -- which is what lets this field be added without a ' +
      'migration: existing documents have no `countries`, read back as [], ' +
      'and keep showing exactly as before',
  })
  countries: string[];
}

export const HomeBannerConfigSchema =
  SchemaFactory.createForClass(HomeBannerConfig);

// Enforces the singleton invariant at the DB level.
HomeBannerConfigSchema.index({ configKey: 1 }, { unique: true });
