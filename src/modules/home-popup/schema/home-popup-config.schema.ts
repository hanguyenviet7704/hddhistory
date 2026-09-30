import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

// Singleton lookup key -- there is only ever one HomePopupConfig document.
export const HOME_POPUP_CONFIG_KEY = 'default';

/**
 * One popup campaign.
 *
 * `_id: false` for the same reason the banner's slides have none: items are
 * identified by their CONTENT (the campaign key is a hash of image + link),
 * the whole config is saved as a unit, and ids would invite patching one in
 * isolation.
 */
@Schema({ _id: false })
export class HomePopupItem {
  @Prop({
    type: String,
    default: '',
    comment:
      'Admin-facing campaign label ("Tết 2027 VN"). Never shown in the app',
  })
  name: string;

  @Prop({
    type: String,
    default: '',
    comment:
      'The whole popup is this ONE image (R2 upload) -- copy is baked into it. ' +
      'Empty keeps the row staged but never shown',
  })
  imageUrl: string;

  @Prop({
    type: String,
    default: '',
    comment:
      'Where tapping the image lands. Tapping retires the campaign for that ' +
      'user. Empty = the popup can only be dismissed',
  })
  linkUrl: string;

  @Prop({
    type: [String],
    default: [],
    comment:
      'Market allow-list, upper-cased on write. EMPTY MEANS EVERY MARKET',
  })
  countries: string[];

  @Prop({
    type: [String],
    default: [],
    comment:
      'Language allow-list, lower-cased on write (vi, en, …). EMPTY MEANS ' +
      'EVERY LANGUAGE. Matched against the `lang` header the app already sends',
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
      'Higher wins when several campaigns target the same viewer. The user is ' +
      'shown the best one they have not tapped yet, so a lower-priority ' +
      'campaign gets its turn once the top one is retired for them',
  })
  priority: number;

  @Prop({
    type: Date,
    default: null,
    comment: 'Campaign window start (server clock). Null = already started',
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
      'Per-campaign switch. The document-level `enabled` is still the kill ' +
      'switch for the whole surface',
  })
  enabled: boolean;

  @Prop({
    type: Boolean,
    default: false,
    comment:
      'Show this campaign again even to somebody who already tapped it -- the ' +
      'one filter it skips. The tap is still WRITTEN to home_popup_clicks ' +
      '(the CTR figure counts those rows); it just stops retiring the popup. ' +
      'Everything else still applies: the kill switch, the window, market, ' +
      'language and segment, and the app raises the popup at most once per ' +
      'app session',
  })
  alwaysShow: boolean;
}

export const HomePopupItemSchema = SchemaFactory.createForClass(HomePopupItem);

// No `timestamps: true` on purpose -- same reason as HomeBannerConfig:
// AbstractDocument already declares createdAt/updatedAt and the repository sets
// them, and Mongoose's automatic timestamps then make the upsert die with
// "Updating the path 'updatedAt' would create a conflict at 'updatedAt'".
@Schema({ collection: 'home_popup_configs' })
export class HomePopupConfig extends AbstractDocument {
  @Prop({ type: String, default: HOME_POPUP_CONFIG_KEY, unique: true })
  configKey: string;

  @Prop({
    type: [HomePopupItemSchema],
    default: [],
    comment:
      'Every campaign, staged or live. EMPTY falls back to the flat ' +
      'single-popup fields below, which is what lets the list be added ' +
      'without a migration (see resolveConfiguredPopups)',
  })
  popups: HomePopupItem[];

  @Prop({
    type: Boolean,
    default: false,
    comment:
      'Kill switch -- the app never raises the popup while false, so a campaign ' +
      'can be staged (image + link saved) before going live',
  })
  enabled: boolean;

  @Prop({
    type: String,
    default: '',
    comment:
      'LEGACY single-popup image. Read only as the seed for campaign 1 when ' +
      '`popups` is empty; the app response also mirrors the campaign chosen ' +
      'for that viewer back into this field for builds that predate the list',
  })
  imageUrl: string;

  @Prop({
    type: String,
    default: '',
    comment:
      'LEGACY single-popup link -- see imageUrl. Tapping IS the click that ' +
      'retires a campaign for that user',
  })
  linkUrl: string;

  @Prop({
    type: [String],
    default: [],
    comment:
      'Market allow-list, upper-cased on write. EMPTY MEANS EVERY MARKET. ' +
      'Matched against the viewer resolved markets exactly as the Home banner is',
  })
  countries: string[];
}

export const HomePopupConfigSchema =
  SchemaFactory.createForClass(HomePopupConfig);

// Enforces the singleton invariant at the DB level.
HomePopupConfigSchema.index({ configKey: 1 }, { unique: true });
