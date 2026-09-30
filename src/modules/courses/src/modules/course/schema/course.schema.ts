import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { SchemaTypes } from 'mongoose';

import { AbstractDocument } from '@base/database/mongodb/abstract.schema';
import { OnboardingSymptom } from '@utils/enum/course.enum';
import { IPrice, ITranslation } from '@utils/interface/common.interface';

import { VoiceoverProvider } from '../../voiceover/enum/voiceover-provider.enum';
import { CourseStatus } from '../enum/course.enum';
import { ICourse, IPublishedCourseFields } from '../interface/course.interface';

@Schema()
export class Course extends AbstractDocument implements ICourse {
  @Prop({ type: SchemaTypes.Mixed })
  title: ITranslation;

  @Prop({ type: SchemaTypes.Mixed })
  description: ITranslation;

  @Prop()
  image: string;

  @Prop()
  skillsetId: string;

  @Prop({ type: [String], enum: Object.values(OnboardingSymptom) })
  onboardingSymptoms?: OnboardingSymptom[] | null;

  // Onboarding v3 (plans/260918-onboarding-v3-taxonomy): nhãn chi tiết (vấn đề)
  // và mã gói (mong muốn) — dữ liệu, không enum. Rỗng = khoá chưa gắn.
  @Prop({ type: [String], default: [] })
  onboardingLabelCodes: string[];

  @Prop({ type: [String], default: [] })
  onboardingDesireCodes: string[];

  @Prop({ enum: CourseStatus, default: CourseStatus.DRAFT })
  status: CourseStatus;

  @Prop({ type: SchemaTypes.Array })
  prices: IPrice[];

  @Prop({ default: 0 })
  numberOfLesson?: number;

  @Prop({ default: false })
  isNew: boolean;

  @Prop({ type: Date, default: null })
  publishAt?: Date | null;

  @Prop({ type: Number, default: null })
  newDurationDays?: number | null;

  // Editorial fields for the app's "New today" card — set per course in admin,
  // never written by the app. Null when the content team left them blank, so
  // the card can hide the row instead of showing "0 views" by an unnamed author.
  @Prop({ type: String, default: null })
  author?: string | null;

  @Prop({ type: Number, default: null })
  viewCount?: number | null;

  // Market allow-list, upper-cased on write (`normalizeCountryCodes`). EMPTY
  // MEANS EVERY MARKET -- which is what lets the field be added without a
  // migration: every course written before it existed reads back as `[]` and
  // keeps showing exactly as it does today.
  //
  // Matched against the markets the VIEWER resolves to, not their IP alone, so
  // picking VN also reaches a Vietnamese abroad reading the app in Vietnamese
  // (see `resolveViewerMarkets`). Distribution only -- it hides the course from
  // discovery, it does not revoke access to one already saved or in progress.
  @Prop({ type: [String], default: [] })
  countries: string[];

  // Which speech engine dubs this course's VIETNAMESE. Default `edge` (free);
  // `vbee` is the paid per-character provider and is opted into one course at a
  // time from the admin Voiceover page, because editorial nominates the courses
  // worth paying to re-voice. Absent on every course written before the field
  // existed, which reads back as `edge` — hence no migration.
  //
  // It has to be PERSISTED rather than passed per run: `sameVoice` compares the
  // stored narrator on every re-dub, so a course whose provider lived only in a
  // query param would be silently re-dubbed back to Edge by the next
  // catalogue-wide run — throwing away audio that cost real credit.
  @Prop({
    type: String,
    enum: VoiceoverProvider,
    default: VoiceoverProvider.EDGE,
  })
  voiceoverViProvider?: VoiceoverProvider;

  // HEAD: which content tag the app serves. Null = never tagged, read the
  // working tree (the pre-versions behaviour). Rolling back a course is a
  // single write to this field -- no content is rewritten.
  // See `plans/260907-course-content-versions/README.md`.
  @Prop({ type: String, default: null })
  currentVersionId?: string | null;

  // Cache of the tag's `course` row. The master copy is in the tag, so a
  // rollback can restore it; this copy exists so the app's list and search
  // stay on this one collection (see IPublishedCourseFields).
  @Prop({ type: SchemaTypes.Mixed, default: null })
  published?: IPublishedCourseFields | null;
}

export const CourseSchema = SchemaFactory.createForClass(Course);

CourseSchema.index({ onboardingSymptoms: 1, status: 1 });
CourseSchema.index({ onboardingLabelCodes: 1, status: 1 });
CourseSchema.index({ onboardingDesireCodes: 1, status: 1 });
CourseSchema.index({ skillsetId: 1, status: 1 });

// Backs `findNewestPublished()` — the daily new-course notification's "newest
// published course" lookup, which would otherwise sort the whole published set
// in memory on every dispatch tick.
CourseSchema.index({ status: 1, createdAt: -1 });

// Backs the suggest-course widgets' `{ status, numberOfLesson: { $gt: 0 } }`
// match (getSuggestCourseWidget / getSuggestCourses) so the $sample pipeline
// doesn't full-scan the collection before sampling.
CourseSchema.index({ status: 1, numberOfLesson: 1 });

// Per-language indexes backing CourseRepository.findOption()'s
// `title.${lang}` / `description.${lang}` regex search and
// checkExitsTitle()'s `title.${lang}` exact-match uniqueness check. `title`/
// `description` are stored as SchemaTypes.Mixed (ITranslation), so Mongoose
// can't infer sub-field indexes automatically — one index per supported
// locale (en/vi/zh/ja/ko, per @utils/interface/common.interface#ITranslation)
// is declared explicitly instead. checkExitsTitle only queries `title`, but
// `description` is included too since findOption's $or searches it with the
// same per-language shape.
CourseSchema.index({ 'title.en': 1 });
CourseSchema.index({ 'title.vi': 1 });
CourseSchema.index({ 'title.zh': 1 });
CourseSchema.index({ 'title.ja': 1 });
CourseSchema.index({ 'title.ko': 1 });
CourseSchema.index({ 'description.en': 1 });
CourseSchema.index({ 'description.vi': 1 });
CourseSchema.index({ 'description.zh': 1 });
CourseSchema.index({ 'description.ja': 1 });
CourseSchema.index({ 'description.ko': 1 });

// The published mirrors of the per-language indexes above. The app searches and
// lists on `published.*` once a course is tagged, so without these the frozen
// title would be unindexed -- and search would silently fall back to matching
// the draft title the editor is still working on.
CourseSchema.index({ 'published.title.en': 1 });
CourseSchema.index({ 'published.title.vi': 1 });
CourseSchema.index({ 'published.title.zh': 1 });
CourseSchema.index({ 'published.title.ja': 1 });
CourseSchema.index({ 'published.title.ko': 1 });
CourseSchema.index({ 'published.description.en': 1 });
CourseSchema.index({ 'published.description.vi': 1 });
CourseSchema.index({ 'published.description.zh': 1 });
CourseSchema.index({ 'published.description.ja': 1 });
CourseSchema.index({ 'published.description.ko': 1 });
