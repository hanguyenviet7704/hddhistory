import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import {
  ICommunityBotChatSettings,
  ICommunityBotCommentSettings,
  ICommunityBotConfig,
  ICommunityBotPersona,
  ICommunityBotPostSettings,
  ICommunityBotSafetySettings,
} from '../interface/community-bot.interface';

/** One deployment, one configuration row. */
export const COMMUNITY_BOT_CONFIG_KEY = 'default';

export const DEFAULT_BOT_CHAT: ICommunityBotChatSettings = {
  enabled: false,
  roomIds: [],
  slots: [],
};

export const DEFAULT_BOT_POST: ICommunityBotPostSettings = {
  enabled: false,
  topicIds: [],
  slots: [],
  maxPerDay: 2,
};

export const DEFAULT_BOT_COMMENT: ICommunityBotCommentSettings = {
  enabled: false,
  slots: [],
  lookbackHours: 24,
  onlyWhenNoComment: true,
  maxPerDay: 10,
};

/**
 * The floor the guard rails start at.
 *
 * The keyword list is seeded rather than left empty because an empty list reads
 * as "nothing is off limits", and the first burst would go out before anybody
 * thought to fill it in. Vietnamese and English only: the app ships five
 * locales, and the rooms that are not in these two get their own words added in
 * admin before they are switched on.
 */
export const DEFAULT_BOT_SAFETY: ICommunityBotSafetySettings = {
  maxChars: 300,
  blockedKeywords: [
    'tự tử',
    'tự sát',
    'tự hại',
    'muốn chết',
    'trầm cảm',
    'thuốc',
    'bệnh viện',
    'vay tiền',
    'chuyển khoản',
    'suicide',
    'kill myself',
    'self-harm',
    'depression',
    'medication',
    'loan',
  ],
};

@Schema({ collection: 'community_bot_configs' })
export class CommunityBotConfig
  extends AbstractDocument
  implements ICommunityBotConfig
{
  @Prop({ required: true, default: COMMUNITY_BOT_CONFIG_KEY })
  configKey: string;

  /**
   * The kill switch, off until a person turns it on.
   *
   * Everything below can be configured, saved and reviewed with this false —
   * the scheduler reads it first and does nothing at all.
   */
  @Prop({ type: Boolean, required: true, default: false })
  enabled: boolean;

  /** Null falls through to GEMINI_MODEL, then to the lite alias in the AI service. */
  @Prop({ type: String, default: null })
  geminiModel?: string | null;

  @Prop({ type: SchemaTypes.Mixed, default: [] })
  personas: ICommunityBotPersona[];

  @Prop({ type: SchemaTypes.Mixed, default: DEFAULT_BOT_CHAT })
  chat: ICommunityBotChatSettings;

  @Prop({ type: SchemaTypes.Mixed, default: DEFAULT_BOT_POST })
  post: ICommunityBotPostSettings;

  @Prop({ type: SchemaTypes.Mixed, default: DEFAULT_BOT_COMMENT })
  comment: ICommunityBotCommentSettings;

  @Prop({ type: SchemaTypes.Mixed, default: DEFAULT_BOT_SAFETY })
  safety: ICommunityBotSafetySettings;
}

export const CommunityBotConfigSchema =
  SchemaFactory.createForClass(CommunityBotConfig);

CommunityBotConfigSchema.index({ configKey: 1 }, { unique: true });
