/**
 * Seeds `keypoint_audio_clips` from the audio already stored on every keypoint.
 *
 * Why this needs no file copying: from the release that introduced the store,
 * every dub writes to an R2 key carrying the text's own token
 * (`…/3-<hash12>.mp3`). Nothing writes to the old un-hashed keys any more, so
 * the bytes sitting at them are frozen for good — a row pointing at the old url
 * is as immutable as one pointing at a new one. See
 * `plans/260916-audio-theo-tag/README.md` §1 decision 3.
 *
 * What it reads, per keypoint and language:
 *   audio.segments[lang][i] + audio.segmentHash[lang][i]  → kind 'card'
 *   audio.url[lang]         + audio.hash[lang]            → kind 'whole'
 *   audio.nextUp[lang]      + audio.nextUpHash[lang]      → kind 'nextup'
 *   audio.merged[lang].url  + .hash (+ durationMs, cues)  → kind 'merged'
 *
 * A pair with a url but no hash is SKIPPED, not guessed: a clip whose text is
 * unknown can never be matched to a tag, and inventing a hash for it would make
 * the store answer confidently with the wrong recording.
 *
 * Idempotent — the unique index absorbs re-runs, so it is safe to run again
 * after a dub, and safe to run in every environment.
 *
 * Run: npx ts-node scripts/backfill-audio-clips.ts        (reads MONGODB_URI)
 *      npx ts-node scripts/backfill-audio-clips.ts --dry  (count only)
 */
import 'dotenv/config';
import mongoose from 'mongoose';

import { clipRowsFromKeypointAudio } from '../src/modules/courses/src/modules/voiceover/audio-clip.util';

const DRY_RUN = process.argv.includes('--dry');
const BATCH = 500;

/**
 * The mapping itself lives with the schema (`clipRowsFromKeypointAudio`) and is
 * shared with the API's own backfill endpoint — two copies of "which field
 * pairs with which hash" is exactly the kind of drift that would seed the store
 * with rows nothing can ever match.
 */
const rowsOfKeypoint = (doc: any, now: Date) =>
  clipRowsFromKeypointAudio(String(doc._id), doc.audio).map(row => ({
    ...row,
    createdAt: now,
    updatedAt: now,
  }));

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('MONGODB_URI is not set');

  await mongoose.connect(uri);
  const db = mongoose.connection.db;
  const keypoints = db.collection('keypoints');
  const clips = db.collection('keypoint_audio_clips');

  // The script creates the index itself: it may run before the app that
  // declares the schema has ever booted against this database, and without the
  // unique index "idempotent" is a wish rather than a guarantee.
  await clips.createIndex(
    { keypointId: 1, lang: 1, kind: 1, textHash: 1, voice: 1 },
    { unique: true },
  );
  await clips.createIndex({ keypointId: 1, lang: 1 });

  const cursor = keypoints.find(
    { audio: { $exists: true } },
    { projection: { audio: 1 } },
  );

  const now = new Date();
  let scanned = 0;
  let prepared = 0;
  let inserted = 0;
  let buffer: any[] = [];

  const flush = async () => {
    if (!buffer.length) return;
    if (!DRY_RUN) {
      // Upserts, not `insertMany`: one keypoint really can hold the same
      // sentence on two cards, and a batch carrying two identical identities
      // makes insertMany throw a duplicate-key error whose shape is easy to
      // misread as "nothing to do" — which is exactly how the first run of this
      // reported 34,428 clips found and 0 written.
      const res = await clips.bulkWrite(
        buffer.map(row => ({
          updateOne: {
            filter: {
              keypointId: row.keypointId,
              lang: row.lang,
              kind: row.kind,
              textHash: row.textHash,
              voice: row.voice ?? '',
            },
            update: { $setOnInsert: row },
            upsert: true,
          },
        })),
        { ordered: false },
      );
      inserted += res.upsertedCount ?? 0;
    }
    buffer = [];
  };

  for await (const doc of cursor) {
    scanned += 1;
    const rows = rowsOfKeypoint(doc, now);
    prepared += rows.length;
    buffer.push(...rows);
    if (buffer.length >= BATCH) await flush();
  }
  await flush();

  console.log(
    `${DRY_RUN ? '[dry] ' : ''}keypoints scanned: ${scanned} · clips found: ` +
      `${prepared} · inserted: ${DRY_RUN ? 0 : inserted} · already present: ` +
      `${DRY_RUN ? '-' : prepared - inserted}`,
  );

  await mongoose.disconnect();
}

main().catch(async error => {
  console.error(error);
  await mongoose.disconnect().catch(() => undefined);
  process.exit(1);
});
