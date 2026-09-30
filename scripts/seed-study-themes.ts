/**
 * Seeds the "Study Theme / Change Background" catalogue so
 * GET /api/v1/study-themes returns something for the mobile app instead of
 * an empty list on a fresh environment.
 *
 * Idempotent: upserts by the unique `key` slug, safe to re-run — existing
 * presets are left untouched (fields are NOT overwritten) so admin edits
 * made afterwards in hddhistory-admin are never clobbered by a re-run of this
 * script.
 *
 * Colour/gradient presets only for now — image/video presets get added
 * later via the admin panel once their assets are uploaded to R2.
 *
 * Run: npx ts-node scripts/seed-study-themes.ts   (reads MONGODB_URI from env/.env)
 */
import 'dotenv/config';
import mongoose from 'mongoose';

export enum StudyThemeMode {
  DEFAULT = 'default',
  COLOR = 'color',
  IMAGE = 'image',
  VIDEO = 'video',
}

const LocalStudyThemePresetSchema = new mongoose.Schema({
  key: { type: String, required: true, unique: true },
  mode: { type: String, required: true },
  category: String,
  name: String,
  gradient: [String],
  imageUrl: String,
  videoUrl: String,
  audioUrl: String,
  thumbUrl: String,
  overlay: String,
  isDark: Boolean,
  order: Number,
  isActive: Boolean,
  isPremium: Boolean,
});

const SEED_PRESETS: Array<{
  key: string;
  mode: StudyThemeMode;
  category: string;
  name: string;
  gradient?: string[];
  imageUrl?: string;
  thumbUrl?: string;
  isDark?: boolean;
  order: number;
}> = [
  {
    key: 'default',
    mode: StudyThemeMode.DEFAULT,
    category: 'Default',
    name: 'Default',
    gradient: ['#EFEEF9', '#E6EBDE'],
    order: 0,
  },
  {
    key: 'lavender',
    mode: StudyThemeMode.COLOR,
    category: 'Solid & Gradient',
    name: 'Lavender',
    gradient: ['#EDE9FF', '#D5D2F7'],
    order: 10,
  },
  {
    key: 'peach',
    mode: StudyThemeMode.COLOR,
    category: 'Solid & Gradient',
    name: 'Peach',
    gradient: ['#FFE7D6', '#FCD1C0'],
    order: 20,
  },
  {
    key: 'mint',
    mode: StudyThemeMode.COLOR,
    category: 'Solid & Gradient',
    name: 'Mint',
    gradient: ['#DCF6EC', '#C3EBDD'],
    order: 30,
  },
  {
    key: 'midnight',
    mode: StudyThemeMode.COLOR,
    category: 'Solid & Gradient',
    name: 'Midnight',
    gradient: ['#20244A', '#141733'],
    isDark: true,
    order: 40,
  },
  {
    key: 'rose',
    mode: StudyThemeMode.COLOR,
    category: 'Solid & Gradient',
    name: 'Rose',
    gradient: ['#FDE6F0', '#F6C9DE'],
    order: 50,
  },
  {
    key: 'sky',
    mode: StudyThemeMode.COLOR,
    category: 'Solid & Gradient',
    name: 'Sky',
    gradient: ['#E3F0FF', '#C7DDFB'],
    order: 60,
  },
  {
    key: 'sand',
    mode: StudyThemeMode.COLOR,
    category: 'Solid & Gradient',
    name: 'Sand',
    gradient: ['#FBF3E2', '#EFE0C4'],
    order: 70,
  },
  {
    key: 'plum',
    mode: StudyThemeMode.COLOR,
    category: 'Solid & Gradient',
    name: 'Plum',
    gradient: ['#3A2C57', '#241735'],
    isDark: true,
    order: 80,
  },
  {
    key: 'cozy_study',
    mode: StudyThemeMode.IMAGE,
    category: 'Cozy',
    name: 'Cozy Study',
    imageUrl: 'http://localhost:4000/static/cozy_study_theme.png',
    thumbUrl: 'http://localhost:4000/static/cozy_study_theme.png',
    isDark: true,
    order: 90,
  },
];

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('MONGODB_URI is not set');

  await mongoose.connect(uri);
  const StudyThemePresetModel = mongoose.model(
    'StudyThemePreset',
    LocalStudyThemePresetSchema,
    'study_theme_presets',
  );

  let created = 0;
  let skipped = 0;

  for (const preset of SEED_PRESETS) {
    const exists = await StudyThemePresetModel.exists({ key: preset.key });

    if (exists) {
      skipped += 1;
      continue;
    }

    await StudyThemePresetModel.create({
      key: preset.key,
      mode: preset.mode,
      category: preset.category,
      name: preset.name,
      gradient: preset.gradient ?? [],
      imageUrl: preset.imageUrl ?? null,
      thumbUrl: preset.thumbUrl ?? null,
      isDark: preset.isDark ?? false,
      order: preset.order,
      isActive: true,
    });
    created += 1;
  }

  console.log(
    `[seed-study-themes] Done. Created ${created}, skipped ${skipped} (already existed).`,
  );
  await mongoose.disconnect();
}

main().catch(err => {
  console.error('[seed-study-themes] Failed:', err);
  process.exit(1);
});
