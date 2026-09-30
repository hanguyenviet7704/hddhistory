import { CommunityLocale } from '../../../interface/community.interface';

/** One persona: an ordinary account plus the description that drives its voice. */
export interface ICommunityBotPersona {
  /** `users._id` of an account carrying `isBot: true`. */
  userId: string;
  /** Two to four sentences of character, pasted straight into the prompt. */
  persona: string;
  /** Empty means "any language"; otherwise the locales this persona writes. */
  locales: CommunityLocale[];
  enabled: boolean;
}

/**
 * One moment in a room's local day.
 *
 * `turnsMin`/`turnsMax` bound how many lines the burst holds — a range rather
 * than a number so two mornings in the same room do not have identical shape.
 */
export interface ICommunityBotSlot {
  hour: number;
  minute: number;
  turnsMin: number;
  turnsMax: number;
}

export interface ICommunityBotChatSettings {
  enabled: boolean;
  /** Empty means every visible room. */
  roomIds: string[];
  slots: ICommunityBotSlot[];
}

export interface ICommunityBotPostSettings {
  enabled: boolean;
  /** Empty means any topic; a post with no topic is never written. */
  topicIds: string[];
  slots: ICommunityBotSlot[];
  maxPerDay: number;
}

export interface ICommunityBotCommentSettings {
  enabled: boolean;
  slots: ICommunityBotSlot[];
  /** Only look at posts written inside this window. */
  lookbackHours: number;
  /** Leave posts that already have a human answer alone. */
  onlyWhenNoComment: boolean;
  maxPerDay: number;
}

export interface ICommunityBotSafetySettings {
  maxChars: number;
  /**
   * Lower-cased, accent-kept substrings. A hit anywhere in the CONTEXT or in a
   * generated line drops the whole burst — see the sanitize helper.
   */
  blockedKeywords: string[];
}

export interface ICommunityBotConfig {
  configKey: string;
  enabled: boolean;
  geminiModel?: string | null;
  personas: ICommunityBotPersona[];
  chat: ICommunityBotChatSettings;
  post: ICommunityBotPostSettings;
  comment: ICommunityBotCommentSettings;
  safety: ICommunityBotSafetySettings;
}

/** What the AI hands back for one line of a burst. */
export interface ICommunityBotDraft {
  personaIndex: number;
  body: string;
  subject?: string;
  /** Index into the context window the prompt was given, when it answers one. */
  replyToIndex?: number;
}
