import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { COMMUNITY_LOCALES, CommunityLocale } from '../../../interface/community.interface';
import { ICommunityChatGuide } from '../interface/community-chat-guide.interface';

@Schema({ collection: 'community_chat_guides' })
export class CommunityChatGuide
  extends AbstractDocument
  implements ICommunityChatGuide
{
  @Prop({ required: true, enum: COMMUNITY_LOCALES })
  locale: CommunityLocale;

  @Prop({ default: '' })
  title: string;

  @Prop({ default: '' })
  intro: string;

  // Three plain string arrays. The panel rewrites each list whole on every
  // save, so there is nothing per-item ids would buy.
  @Prop({ type: [String], default: [] })
  dos: string[];

  @Prop({ type: [String], default: [] })
  donts: string[];

  @Prop({ type: [String], default: [] })
  starters: string[];
}

export const CommunityChatGuideSchema =
  SchemaFactory.createForClass(CommunityChatGuide);

// One row per language — the write is an upsert against this key.
CommunityChatGuideSchema.index({ locale: 1 }, { unique: true });
