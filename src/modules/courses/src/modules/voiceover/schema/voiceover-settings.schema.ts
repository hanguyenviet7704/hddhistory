import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

// Singleton lookup key — there is only ever one VoiceoverSettings document.
export const VOICEOVER_SETTINGS_KEY = 'default';

/**
 * The narrator settings an admin can change without a deploy.
 *
 * Only Vbee has anything here. Edge's narrator is deliberately closed (one
 * verified female voice per locale, resolved against the live catalogue — see
 * `TtsService`), and that stays true: this document exists because Vbee's voice
 * is a PRICING decision as much as a casting one (`credit_factor` 1, 2 or 3),
 * and pricing decisions should not need a release.
 *
 * No `timestamps: true` on purpose — `AbstractDocument` already declares
 * createdAt/updatedAt and the upsert below sets them, so Mongoose's automatic
 * timestamps would collide on the same path and 500 every read. (The same trap
 * `streak-config` documents.)
 */
@Schema({ collection: 'voiceover_settings' })
export class VoiceoverSettings extends AbstractDocument {
  @Prop({ type: String, default: VOICEOVER_SETTINGS_KEY, unique: true })
  configKey: string;

  @Prop({
    type: String,
    default: '',
    comment:
      'Vbee voiceCode used for Vietnamese on courses switched to Vbee. Empty ' +
      'means "whatever VBEE_VOICE_CODE says" — so the picker can be left ' +
      'untouched and the deploy default still applies.',
  })
  vbeeVoiceCode: string;
}

export const VoiceoverSettingsSchema =
  SchemaFactory.createForClass(VoiceoverSettings);

// Enforces the singleton invariant at the DB level.
VoiceoverSettingsSchema.index({ configKey: 1 }, { unique: true });
