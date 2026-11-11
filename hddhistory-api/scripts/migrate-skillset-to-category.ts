/**
 * One-off data migration for the Skillset → Category rename (2026-09-30).
 *
 * The code now reads collection `categories` and fields `categoryId` /
 * `categoryWantToMaster`; data written before the rename still sits under the
 * old names. This moves it across:
 *   - renames collection `skillsets` → `categories`
 *   - `$rename`s the reference fields in courses, habits, onboarding_branches
 *     and onboardings
 *   - drops the indexes built on the old field names and builds the new ones
 *   - renames the analytics screen name "Skillset Courses" in user_events
 *
 * Idempotent: every step checks the old name first, so re-running on an
 * already-migrated database is a no-op. `admin_audit_logs` is left alone — it
 * records requests as they were sent.
 *
 * Run: npm run migrate:category [-- --dry-run]   (reads MONGODB_URI from .env)
 */
import 'dotenv/config';
import mongoose from 'mongoose';

const DRY_RUN = process.argv.includes('--dry-run');

const FIELD_RENAMES: Array<[collection: string, from: string, to: string]> = [
  ['courses', 'skillsetId', 'categoryId'],
  ['habits', 'skillsetId', 'categoryId'],
  ['onboarding_branches', 'skillsetId', 'categoryId'],
  ['onboardings', 'skillsetWantToMaster', 'categoryWantToMaster'],
];

const INDEX_SWAPS: Array<
  [collection: string, oldName: string, keys: Record<string, 1>]
> = [
  ['courses', 'skillsetId_1_status_1', { categoryId: 1, status: 1 }],
  [
    'habits',
    'skillsetId_1_status_1_order_1',
    { categoryId: 1, status: 1, order: 1 },
  ],
];

const EVENT_RENAMES: Array<[from: string, to: string]> = [
  ['Skillset Courses', 'Category Courses'],
];

async function main(): Promise<void> {
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('MONGODB_URI is not set');
  await mongoose.connect(uri);
  const db = mongoose.connection.db;
  const log = (msg: string) =>
    console.log(`[migrate-category]${DRY_RUN ? ' (dry run)' : ''} ${msg}`);

  const names = new Set(
    (await db.listCollections({}, { nameOnly: true }).toArray()).map(
      (c) => c.name,
    ),
  );

  if (names.has('skillsets')) {
    if (names.has('categories')) {
      const existing = await db.collection('categories').countDocuments();
      if (existing > 0) {
        throw new Error(
          `both "skillsets" and a non-empty "categories" (${existing} docs) exist — resolve by hand`,
        );
      }
      log('dropping empty "categories" left by a boot of the new code');
      if (!DRY_RUN) await db.collection('categories').drop();
    }
    const n = await db.collection('skillsets').countDocuments();
    log(`renaming collection skillsets → categories (${n} docs)`);
    if (!DRY_RUN) await db.collection('skillsets').rename('categories');
  } else {
    log('collection "skillsets" not found — already migrated');
  }

  for (const [collection, from, to] of FIELD_RENAMES) {
    if (!names.has(collection)) continue;
    const coll = db.collection(collection);
    const n = await coll.countDocuments({ [from]: { $exists: true } });
    log(`${collection}: ${from} → ${to} on ${n} docs`);
    if (n && !DRY_RUN) {
      await coll.updateMany(
        { [from]: { $exists: true } },
        { $rename: { [from]: to } },
      );
    }
  }

  for (const [collection, oldName, keys] of INDEX_SWAPS) {
    if (!names.has(collection)) continue;
    const coll = db.collection(collection);
    const indexes = await coll.indexes();
    if (indexes.some((i) => i.name === oldName)) {
      log(`${collection}: dropping index ${oldName}`);
      if (!DRY_RUN) await coll.dropIndex(oldName);
    }
    log(`${collection}: ensuring index ${JSON.stringify(keys)}`);
    if (!DRY_RUN) await coll.createIndex(keys);
  }

  if (names.has('user_events')) {
    for (const [from, to] of EVENT_RENAMES) {
      const n = await db
        .collection('user_events')
        .countDocuments({ name: from });
      log(`user_events: name "${from}" → "${to}" on ${n} docs`);
      if (n && !DRY_RUN) {
        await db
          .collection('user_events')
          .updateMany({ name: from }, { $set: { name: to } });
      }
    }
  }

  await mongoose.disconnect();
  log('done');
}

main().catch(async (err) => {
  console.error('[migrate-category] failed:', err);
  await mongoose.disconnect();
  process.exit(1);
});
