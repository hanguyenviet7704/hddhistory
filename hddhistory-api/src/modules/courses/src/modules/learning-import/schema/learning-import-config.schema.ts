import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

// Singleton lookup key -- there is only ever one LearningImportConfig document.
export const LEARNING_IMPORT_CONFIG_KEY = 'default';

/**
 * The one switch that can turn lesson generation off without a deploy.
 *
 * It exists because this is the only feature in the app that spends money per
 * tap. When the provider starts failing, or a prompt change turns out to write
 * nonsense, or the bill runs ahead of the plan, the choice today is to redeploy
 * or to let it keep running. This is the third option, and it belongs in config
 * rather than in an env var for the same reason the paywall config does: turning
 * it off is an operational decision someone makes at 9pm from the admin panel,
 * not a code change.
 *
 * Deliberately NOT the same thing as `AI_NOT_CONFIGURED` (a missing key, which is
 * a fault) — this is a deliberate closure, and the app says so differently.
 *
 * No `timestamps: true`: AbstractDocument already declares createdAt/updatedAt
 * and the repository sets them explicitly. Adding Mongoose's automatic
 * timestamps makes the upsert write `updatedAt` twice and die with "Updating the
 * path 'updatedAt' would create a conflict" -- a 500 on every read. That exact
 * bug shipped once on `streak_configs`.
 */
@Schema({ collection: 'learning_import_configs' })
export class LearningImportConfig extends AbstractDocument {
  @Prop({ type: String, default: LEARNING_IMPORT_CONFIG_KEY, unique: true })
  configKey: string;

  /**
   * Whether a user may start a new import.
   *
   * Defaults to true so an empty collection behaves exactly as the feature did
   * before this document existed. Only the CREATE path is gated: lessons already
   * generated stay readable and already-running jobs finish, because taking
   * someone's lesson away is not what "pause the feature" should mean.
   */
  @Prop({ type: Boolean, default: true })
  enabled: boolean;

  /**
   * Shown to the user when the feature is off, in whatever language the admin
   * types. Optional: empty falls back to the app's own localized sentence, which
   * is the better default — a note in Vietnamese reaches a reader in Korea as
   * noise.
   */
  @Prop({ type: String, default: '' })
  disabledNote: string;

  /**
   * The admin-curated pool of LESSON cover images (R2 urls, uploaded from the
   * admin's User-imports page). A lesson is dealt one of these at creation and
   * keeps it — see `pickCoverUrl` — so editing this pool changes only lessons
   * born after the edit.
   *
   * Deliberately a SEPARATE pool from [keypointImageUrls]: a course cover and a
   * keypoint thumbnail are different kinds of picture (product call,
   * 2026-08-13), not one pool read at two sizes.
   *
   * Empty = the app falls back to its bundled placeholder art, which is also
   * what every lesson created before this field existed shows.
   */
  @Prop({ type: [String], default: [] })
  courseCoverUrls: string[];

  /**
   * The pool for KEYPOINT node thumbnails on a generated lesson's roadmap.
   * Keypoints of one lesson rotate through it so neighbouring nodes differ.
   * Same lifecycle rules as [courseCoverUrls].
   */
  @Prop({ type: [String], default: [] })
  keypointImageUrls: string[];
}

export const LearningImportConfigSchema =
  SchemaFactory.createForClass(LearningImportConfig);
