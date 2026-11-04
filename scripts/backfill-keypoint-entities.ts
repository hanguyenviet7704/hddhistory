/**
 * Ghi `Keypoint.entityIds` cho các keypoint lịch sử Việt Nam đã seed từ trước
 * khi trường này tồn tại.
 *
 * `entityIds` của một keypoint = hợp `entityIds` của các thẻ trong bài (giữ
 * thứ tự, bỏ trùng) — tính bằng chính `buildSeedPlan` của seed, nên khoá bài
 * (`<thời kỳ>::<khoá>::<bài>`, nằm trong `Keypoint.tag`) và danh sách thực thể
 * luôn khớp từng ký tự với những gì seed mới sẽ ghi.
 *
 * CHỈ `$set: { entityIds }` trên keypoint có `tag` chứa khoá bài; không tạo,
 * không xoá, không đụng trường nào khác. Chạy lại bao nhiêu lần cũng được:
 * keypoint đã đúng được đếm là "không đổi" và không bị ghi.
 *
 * Chạy:
 *   npm run backfill:keypoint-entities -- --dry-run   (chỉ đọc, in số sẽ cập nhật)
 *   npm run backfill:keypoint-entities
 *
 * Đọc MONGODB_URI từ env/.env. `--dry-run` mà thiếu MONGODB_URI thì chỉ in kế
 * hoạch tính từ file, không kết nối gì.
 */
import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

import mongoose from 'mongoose';

import {
  buildSeedPlan,
  PeriodRef,
} from '../src/base/seed/curriculum/curriculum.builder';
import {
  SeedRef,
  validateCurriculum,
} from '../src/base/seed/curriculum/curriculum.validator';
import { KeypointSchema } from '../src/modules/courses/src/modules/keypoint/schema/keypoint.schema';

const CURRICULUM_FILE = path.join(
  process.cwd(),
  'scripts/data/vn-history-curriculum.json',
);
const SEED_FILE = path.join(
  process.cwd(),
  'src/modules/knowledge-graph/data/vn_history_seed.json',
);

/** In tối đa bấy nhiêu khoá không tìm thấy, để log còn đọc được. */
const MAX_LISTED = 20;

interface Target {
  lessonKey: string;
  entityIds: string[];
}

function sameList(a: readonly string[], b: readonly string[]): boolean {
  return a.length === b.length && a.every((value, index) => value === b[index]);
}

function loadTargets(): Target[] {
  const seedRaw = JSON.parse(fs.readFileSync(SEED_FILE, 'utf-8'));
  const periods: PeriodRef[] = seedRaw.periods;
  const ref: SeedRef = {
    periodIds: new Set(periods.map((p) => p.id)),
    entityIds: new Set(seedRaw.entities.map((e: { id: string }) => e.id)),
  };

  const curriculum = JSON.parse(fs.readFileSync(CURRICULUM_FILE, 'utf-8'));
  // Cùng cổng với seed: một entityId không có trong đồ thị là lỗi soạn thảo,
  // ghi nó vào keypoint chỉ khiến coach mở một ngữ cảnh rỗng.
  const errors = validateCurriculum(curriculum, ref);
  if (errors.length) {
    console.error(`Curriculum có ${errors.length} lỗi:`);
    errors.forEach((e) => console.error(`  - ${e}`));
    process.exit(1);
  }

  return buildSeedPlan(curriculum, periods).keypoints.map((k) => ({
    lessonKey: k._localKey,
    entityIds: k.entityIds,
  }));
}

async function main() {
  const dryRun = process.argv.includes('--dry-run');
  const targets = loadTargets();
  const withEntities = targets.filter((t) => t.entityIds.length > 0).length;

  console.log(
    `Curriculum: ${targets.length} keypoint (bài), ` +
      `${withEntities} có ít nhất một thực thể, ` +
      `${targets.length - withEntities} không có.`,
  );

  const uri = process.env.MONGODB_URI;
  if (!uri) {
    if (dryRun) {
      console.log('--dry-run, không có MONGODB_URI: chỉ in kế hoạch từ file.');
      return;
    }
    throw new Error('Thiếu MONGODB_URI trong .env');
  }

  // autoIndex/autoCreate tắt: script này chỉ được đọc (và, khi không phải
  // dry-run, `$set` đúng một trường). Dựng index là việc của API lúc khởi động.
  await mongoose.connect(uri, {
    serverSelectionTimeoutMS: 5000,
    autoIndex: false,
    autoCreate: false,
  });

  try {
    const Keypoint = mongoose.model('Keypoint', KeypointSchema);

    const docs = await Keypoint.find(
      { tag: { $in: targets.map((t) => t.lessonKey) } },
      { _id: 1, tag: 1, entityIds: 1 },
    ).lean<Array<{ _id: unknown; tag?: string[]; entityIds?: string[] }>>();

    const byKey = new Map<string, typeof docs>();
    const wanted = new Set(targets.map((t) => t.lessonKey));
    for (const doc of docs) {
      for (const tag of doc.tag ?? []) {
        if (!wanted.has(tag)) continue;
        const list = byKey.get(tag) ?? [];
        list.push(doc);
        byKey.set(tag, list);
      }
    }

    let updated = 0;
    let unchanged = 0;
    const notFound: string[] = [];
    const duplicated: string[] = [];
    const writes: Array<{
      updateOne: {
        filter: { _id: unknown };
        update: { $set: { entityIds: string[] } };
      };
    }> = [];

    for (const target of targets) {
      const matches = byKey.get(target.lessonKey) ?? [];
      if (!matches.length) {
        notFound.push(target.lessonKey);
        continue;
      }
      if (matches.length > 1) duplicated.push(target.lessonKey);

      for (const doc of matches) {
        if (sameList(doc.entityIds ?? [], target.entityIds)) {
          unchanged++;
          continue;
        }
        updated++;
        writes.push({
          updateOne: {
            filter: { _id: doc._id },
            update: { $set: { entityIds: target.entityIds } },
          },
        });
      }
    }

    if (!dryRun && writes.length) {
      await Keypoint.bulkWrite(writes as any, { ordered: false });
    }

    console.log(
      `${dryRun ? '[dry-run] Sẽ cập nhật' : 'Đã cập nhật'}: ${updated}, ` +
        `không đổi: ${unchanged}, không tìm thấy: ${notFound.length}.`,
    );
    if (duplicated.length) {
      console.log(
        `  ${duplicated.length} khoá bài khớp nhiều hơn một keypoint ` +
          `(đều được ghi): ${duplicated.slice(0, MAX_LISTED).join(', ')}`,
      );
    }
    if (notFound.length) {
      console.log('  Không tìm thấy keypoint có tag:');
      notFound.slice(0, MAX_LISTED).forEach((key) => console.log(`    - ${key}`));
      if (notFound.length > MAX_LISTED) {
        console.log(`    … và ${notFound.length - MAX_LISTED} khoá nữa`);
      }
    }
  } finally {
    await mongoose.disconnect();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
