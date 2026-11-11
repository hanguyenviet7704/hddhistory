import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';

import { StudyThemeMode } from '../enum/study-theme.enum';
import { IStudyThemePreset } from '../interface/study-theme-preset.interface';

@Schema({ collection: 'study_theme_presets' })
export class StudyThemePreset
  extends AbstractDocument
  implements IStudyThemePreset
{
  @Prop({ required: true, unique: true, trim: true })
  key: string;

  @Prop({ enum: StudyThemeMode, default: StudyThemeMode.COLOR })
  mode: StudyThemeMode;

  @Prop()
  category: string;

  @Prop()
  name: string;

  @Prop({ type: [String], default: [] })
  gradient: string[];

  @Prop({ default: null })
  imageUrl?: string | null;

  @Prop({ default: null })
  videoUrl?: string | null;

  @Prop({ default: null })
  audioUrl?: string | null;

  @Prop({ default: null })
  thumbUrl?: string | null;

  @Prop({ default: null })
  overlay?: string | null;

  @Prop({ default: false })
  isDark: boolean;

  @Prop({ default: 0 })
  order: number;

  @Prop({ default: true })
  isActive: boolean;

  // Premium-only preset: shown (locked) in the in-app picker behind the paywall,
  // and hidden entirely from the onboarding theme step.
  @Prop({ default: false })
  isPremium: boolean;
}

export const StudyThemePresetSchema =
  SchemaFactory.createForClass(StudyThemePreset);

// Stable slug lookup/uniqueness (create/update/delete all key off it).
StudyThemePresetSchema.index({ key: 1 }, { unique: true });
// Backs the public endpoint's `isActive: true` filter + `order` asc sort.
StudyThemePresetSchema.index({ isActive: 1, order: 1 });
