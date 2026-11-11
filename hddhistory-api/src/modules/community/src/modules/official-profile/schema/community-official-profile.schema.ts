import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

/**
 * The team's face in the forum, as one editable row.
 *
 * Until now this identity was a constant in the source: `HDDhistory`, no picture. So
 * the only way to change what readers see on an official post — or to give the
 * team an avatar at all — was a deploy. It is brand, not code.
 *
 * A single document, pinned by [OFFICIAL_PROFILE_KEY]: there is one team.
 */
@Schema({ collection: 'community_official_profiles' })
export class CommunityOfficialProfile extends AbstractDocument {
  @Prop({ required: true, unique: true })
  key: string;

  /**
   * Shown instead of the app's own localised "Đội ngũ HDDhistory" when set.
   *
   * One string, not a translation map: this is a brand name, and a brand that
   * spells itself differently per language is not a brand. Empty means "leave
   * it to the app", which keeps the localised wording readers have now.
   */
  @Prop({ default: '' })
  name: string;

  @Prop({ default: '' })
  avatar: string;
}

export const CommunityOfficialProfileSchema = SchemaFactory.createForClass(
  CommunityOfficialProfile,
);
