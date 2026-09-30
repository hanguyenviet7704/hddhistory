/**
 * Đổ cây nội dung lịch sử Việt Nam vào Mongo: Skillset → Course → Lesson →
 * Keypoint.
 *
 * Idempotent theo kiểu *chèn-nếu-thiếu*, cố ý KHÔNG ghi đè bản ghi đã có —
 * giống các seeder Mongo khác trong thư mục này, để chỉnh sửa của admin không
 * bị một lần chạy seed xoá mất. Muốn nội dung mới thắng thì xoá bản ghi cũ rồi
 * chạy lại.
 *
 * Chạy:
 *   npm run seed:vn-history
 *   npm run seed:vn-history -- --dry-run    (chỉ validate và in thống kê)
 *
 * Đọc MONGODB_URI từ env/.env
 */
import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

import mongoose from 'mongoose';

import {
  buildSeedPlan,
  DEFAULT_STATIC_BASE_URL,
  PeriodRef,
} from '../src/base/seed/curriculum/curriculum.builder';
import { validateCurriculum, SeedRef } from '../src/base/seed/curriculum/curriculum.validator';
import { CourseSchema } from '../src/modules/courses/src/modules/course/schema/course.schema';
import { KeypointSchema } from '../src/modules/courses/src/modules/keypoint/schema/keypoint.schema';
import { RoadmapSchema } from '../src/modules/courses/src/modules/course/schema/roadmap.schema';
import { LearningItemSchema } from '../src/modules/courses/src/modules/learning-item/schema/learning-item.schema';
import { LessonSchema } from '../src/modules/courses/src/modules/lesson/schema/lesson.schema';
import { SkillsetSchema } from '../src/modules/courses/src/modules/skillset/schema/skillset.schema';

const CURRICULUM_FILE = path.join(process.cwd(), 'scripts/data/vn-history-curriculum.json');
const SEED_FILE = path.join(
  process.cwd(),
  'src/modules/knowledge-graph/data/vn_history_seed.json',
);

async function main() {
  const dryRun = process.argv.includes('--dry-run');

  const seedRaw = JSON.parse(fs.readFileSync(SEED_FILE, 'utf-8'));
  const periods: PeriodRef[] = seedRaw.periods;
  const ref: SeedRef = {
    periodIds: new Set(periods.map((p) => p.id)),
    entityIds: new Set(seedRaw.entities.map((e: { id: string }) => e.id)),
  };

  const curriculum = JSON.parse(fs.readFileSync(CURRICULUM_FILE, 'utf-8'));

  const errors = validateCurriculum(curriculum, ref);
  if (errors.length) {
    console.error(`Curriculum có ${errors.length} lỗi:`);
    errors.forEach((e) => console.error(`  - ${e}`));
    process.exit(1);
  }

  const plan = buildSeedPlan(
    curriculum,
    periods,
    process.env.STATIC_BASE_URL || DEFAULT_STATIC_BASE_URL,
  );
  console.log(
    `Dự kiến: ${plan.skillsets.length} skillset, ${plan.courses.length} khoá, ` +
      `${plan.lessons.length} bài, ${plan.keypoints.length} keypoint, ${plan.learningItems.length} learning item, ${plan.roadmaps.length} roadmap.`,
  );

  if (dryRun) {
    console.log('--dry-run: không ghi gì vào Mongo.');
    return;
  }

  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('Thiếu MONGODB_URI trong .env');

  // Chờ tối đa 5 giây rồi báo lỗi, thay vì treo vô hạn khi quên bật Docker.
  await mongoose.connect(uri, { serverSelectionTimeoutMS: 5000 });

  const Skillset = mongoose.model('Skillset', SkillsetSchema);
  const Course = mongoose.model('Course', CourseSchema);
  const Lesson = mongoose.model('Lesson', LessonSchema);
  const Keypoint = mongoose.model('Keypoint', KeypointSchema);
  const LearningItem = mongoose.model('LearningItem', LearningItemSchema);
  const Roadmap = mongoose.model('Roadmap', RoadmapSchema);

  const skillsetIds = new Map<string, string>();
  let created = 0;
  let skipped = 0;

  for (const s of plan.skillsets) {
    const found = await Skillset.findOne({ 'title.vi': s.title.vi });
    if (found) {
      skillsetIds.set(s._localKey, String(found._id));
      skipped++;
      continue;
    }
    const doc = await Skillset.create({
      index: s.index,
      title: s.title,
      description: s.description,
      status: s.status,
      image: s.image,
    });
    skillsetIds.set(s._localKey, String(doc._id));
    created++;
  }

  const courseIds = new Map<string, string>();
  for (const c of plan.courses) {
    const skillsetId = skillsetIds.get(c.skillsetLocalKey);
    const found = await Course.findOne({ 'title.vi': c.title.vi, skillsetId });
    if (found) {
      courseIds.set(c._localKey, String(found._id));
      skipped++;
      continue;
    }
    const doc = await Course.create({
      title: c.title,
      description: c.description,
      status: c.status,
      image: c.image,
      skillsetId,
      numberOfLesson: c.numberOfLesson,
    });
    courseIds.set(c._localKey, String(doc._id));
    created++;
  }

  // Keypoint được tạo trước lesson: Lesson.keypoints là mảng id (lesson.schema.ts),
  // nên phải có id keypoint rồi mới ghi được lesson.
  const keypointIdsByLesson = new Map<string, string[]>();
  const keypointIdByKey = new Map<string, string>();
  for (const k of plan.keypoints) {
    // Khớp theo tag chứ không theo (title, index): collection keypoint phẳng,
    // không có lessonId, nên hai bài cùng có keypoint tên "Hệ quả" ở vị trí 0
    // sẽ bị gộp làm một nếu khớp bằng tiêu đề.
    const found = await Keypoint.findOne({ tag: k._localKey });
    let id: string;
    if (found) {
      id = String(found._id);
      skipped++;
    } else {
      const doc = await Keypoint.create({
        title: k.title,
        description: k.description,
        image: k.image,
        index: k.index,
        tag: k.tag,
      });
      id = String(doc._id);
      created++;
    }
    keypointIdByKey.set(k._localKey, id);
    const list = keypointIdsByLesson.get(k.lessonLocalKey) ?? [];
    list.push(id);
    keypointIdsByLesson.set(k.lessonLocalKey, list);
  }

  const lessonIdByKey = new Map<string, string>();
  for (const l of plan.lessons) {
    const courseId = courseIds.get(l.courseLocalKey);
    const found = await Lesson.findOne({ 'title.vi': l.title.vi, courseId });
    if (found) {
      lessonIdByKey.set(l._localKey, String(found._id));
      skipped++;
      continue;
    }
    const lessonDoc = await Lesson.create({
      courseId,
      title: l.title,
      description: l.description,
      status: l.status,
      image: l.image,
      index: l.index,
      keypoints: keypointIdsByLesson.get(l._localKey) ?? [],
    });
    lessonIdByKey.set(l._localKey, String(lessonDoc._id));
    created++;
  }

  const need = (m: Map<string, string>, key: string, what: string) => {
    const v = m.get(key);
    if (!v) throw new Error(`Thiếu id ${what} cho "${key}"`);
    return v;
  };
  // Learning item (theory): mặt đọc của keypoint. keypointId là chuỗi. Khớp theo
  // tag mang khoá cục bộ của keypoint (cùng cách keypoint tự khớp), không ghi đè.
  for (const li of plan.learningItems) {
    const keypointId = need(keypointIdByKey, li.keypointLocalKey, 'keypoint');
    if (await LearningItem.exists({ tag: li._localKey, type: li.type })) {
      skipped++;
      continue;
    }
    await LearningItem.create({
      keypointId,
      type: li.type,
      title: li.title,
      description: li.description,
      image: li.image,
      tag: li.tag,
      index: li.index,
      questions: li.questions,
      subQuestions: li.subQuestions,
      isSub: li.isSub,
      documents: li.documents,
    });
    created++;
  }

  // Roadmap: courseId là chuỗi (khớp cách các schema khác lưu id ở seeder này).
  // Chèn-nếu-thiếu theo courseId, không ghi đè để chỉnh tay của admin còn nguyên.
  for (const r of plan.roadmaps) {
    const courseId = need(courseIds, r.courseLocalKey, 'khoá');
    if (await Roadmap.exists({ courseId })) {
      skipped++;
      continue;
    }
    await Roadmap.create({
      courseId,
      levels: [
        {
          id: r.level.id,
          level: r.level.level,
          titleBadge: r.level.titleBadge,
          lightBadge: r.level.badge,
          darkBadge: r.level.badge,
          keypointIds: r.keypointLocalKeys.map((k) =>
            need(keypointIdByKey, k, 'keypoint'),
          ),
          nodes: r.nodes.map((n) => ({
            id: n.id,
            title: n.title,
            description: n.description,
            lessonIds: n.lessonLocalKeys.map((k) =>
              need(lessonIdByKey, k, 'bài'),
            ),
            outputId: n.outputId,
          })),
        },
      ],
    });
    created++;
  }

  console.log(`Xong. Tạo mới ${created}, bỏ qua vì đã có ${skipped}.`);
  await mongoose.disconnect();
}

main().catch((e) => {
  console.error('Seed nội dung lịch sử thất bại:', e.message);
  process.exit(1);
});
