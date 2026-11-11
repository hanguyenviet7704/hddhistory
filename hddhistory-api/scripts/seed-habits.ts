/**
 * Seeds a dev habit library so GET /api/v1/habits (and the adopt / check-in /
 * weekly-review flows) are testable end to end.
 *
 * Idempotent: matches on (title.en, categoryId) before inserting, safe to
 * re-run. Categories are resolved by title match against the ALREADY-SEEDED
 * category catalog rather than hardcoded ids, since those differ per
 * environment — only the categories that exist on this env get seeded.
 *
 * Titles carry all 5 supported locales (en/vi/zh/ja/ko), matching the app's
 * ITranslation contract, so the mobile client renders the right language.
 *
 * Run: npx ts-node scripts/seed-habits.ts   (reads MONGODB_URI from env/.env)
 */
import 'dotenv/config';
import mongoose from 'mongoose';

import { HabitLibraryStatus } from '../src/modules/habit/src/modules/habit-library/enum/habit-library.enum';
import { HabitLibrarySchema } from '../src/modules/habit/src/modules/habit-library/schema/habit-library.schema';

type MultiLang = {
  en: string;
  vi: string;
  zh: string;
  ja: string;
  ko: string;
};

const SEED_HABITS: Array<{
  categoryTitleMatch: RegExp;
  habits: Array<{
    title: MultiLang;
    icon: string;
    defaultReminderTime: string;
  }>;
}> = [
  {
    categoryTitleMatch: /feel/i,
    habits: [
      {
        title: {
          en: 'Take a 2-minute breathing break to reset',
          vi: 'Dành 2 phút hít thở để tái tạo năng lượng',
          zh: '花 2 分钟做呼吸练习来重置状态',
          ja: '2分間の呼吸休憩でリセットする',
          ko: '2분간 호흡 휴식으로 재충전하기',
        },
        icon: '🫁',
        defaultReminderTime: '08:00',
      },
      {
        title: {
          en: 'Name one emotion before reacting',
          vi: 'Gọi tên một cảm xúc trước khi phản ứng',
          zh: '在反应之前先说出一种情绪',
          ja: '反応する前に感情を一つ名づける',
          ko: '반응하기 전에 감정 하나 이름 붙이기',
        },
        icon: '💭',
        defaultReminderTime: '20:00',
      },
    ],
  },
  {
    categoryTitleMatch: /think/i,
    habits: [
      {
        title: {
          en: 'Write down one decision you made today',
          vi: 'Ghi lại một quyết định bạn đã đưa ra hôm nay',
          zh: '写下你今天做的一个决定',
          ja: '今日下した決断を一つ書き留める',
          ko: '오늘 내린 결정 하나 적기',
        },
        icon: '📝',
        defaultReminderTime: '21:00',
      },
      {
        title: {
          en: 'Plan tomorrow in 3 bullet points',
          vi: 'Lên kế hoạch ngày mai trong 3 gạch đầu dòng',
          zh: '用三个要点计划明天',
          ja: '明日を3つの箇条書きで計画する',
          ko: '내일을 3가지 항목으로 계획하기',
        },
        icon: '📋',
        defaultReminderTime: '22:00',
      },
    ],
  },
  {
    categoryTitleMatch: /connect|relation|social/i,
    habits: [
      {
        title: {
          en: 'Ask someone one genuine question today',
          vi: 'Hỏi ai đó một câu hỏi chân thành hôm nay',
          zh: '今天真诚地问某人一个问题',
          ja: '今日、誰かに心からの質問を一つする',
          ko: '오늘 누군가에게 진심 어린 질문 하나 하기',
        },
        icon: '💬',
        defaultReminderTime: '12:00',
      },
      {
        title: {
          en: 'Listen fully without interrupting once',
          vi: 'Lắng nghe trọn vẹn mà không ngắt lời',
          zh: '完整倾听，一次也不打断',
          ja: '一度も遮らずに最後まで聞く',
          ko: '한 번도 끊지 않고 끝까지 듣기',
        },
        icon: '👂',
        defaultReminderTime: '19:00',
      },
    ],
  },
  {
    categoryTitleMatch: /work|product|focus/i,
    habits: [
      {
        title: {
          en: 'Start the day with your most important task',
          vi: 'Bắt đầu ngày mới với việc quan trọng nhất',
          zh: '从最重要的任务开始新的一天',
          ja: '一日を最も重要なタスクから始める',
          ko: '가장 중요한 일로 하루를 시작하기',
        },
        icon: '✅',
        defaultReminderTime: '09:00',
      },
      {
        title: {
          en: 'Take a screen break every hour',
          vi: 'Nghỉ mắt khỏi màn hình mỗi giờ',
          zh: '每小时离开屏幕休息一次',
          ja: '1時間ごとに画面から離れて休憩する',
          ko: '매시간 화면에서 벗어나 휴식하기',
        },
        icon: '⏰',
        defaultReminderTime: '15:00',
      },
    ],
  },
  {
    categoryTitleMatch: /learn|memory|study/i,
    habits: [
      {
        title: {
          en: 'Review one thing you learned yesterday',
          vi: 'Ôn lại một điều bạn đã học hôm qua',
          zh: '复习你昨天学到的一件事',
          ja: '昨日学んだことを一つ復習する',
          ko: '어제 배운 것 하나 복습하기',
        },
        icon: '📚',
        defaultReminderTime: '18:00',
      },
      {
        title: {
          en: 'Teach one idea to someone else',
          vi: 'Dạy lại một ý tưởng cho người khác',
          zh: '把一个想法教给别人',
          ja: '学んだ考えを誰かに教える',
          ko: '배운 아이디어 하나를 다른 사람에게 가르치기',
        },
        icon: '🧑‍🏫',
        defaultReminderTime: '20:30',
      },
    ],
  },
];

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('MONGODB_URI is not set');

  await mongoose.connect(uri);
  const HabitLibraryModel = mongoose.model('HabitLibrary', HabitLibrarySchema, 'habits');
  const categoriesCollection = mongoose.connection.collection('categories');

  let created = 0;
  let skipped = 0;
  let missingCategories = 0;

  for (const group of SEED_HABITS) {
    const category = await categoriesCollection.findOne({
      status: 'published',
      'title.en': { $regex: group.categoryTitleMatch },
    });

    if (!category) {
      missingCategories += 1;
      console.warn(
        `[seed-habits] No published category matching ${group.categoryTitleMatch} — skipping ${group.habits.length} habit(s).`,
      );
      continue;
    }

    for (const [index, habit] of group.habits.entries()) {
      const exists = await HabitLibraryModel.exists({
        'title.en': habit.title.en,
        categoryId: category._id,
      });

      if (exists) {
        skipped += 1;
        continue;
      }

      await HabitLibraryModel.create({
        title: habit.title,
        icon: habit.icon,
        categoryId: category._id,
        status: HabitLibraryStatus.PUBLISHED,
        defaultReminderTime: habit.defaultReminderTime,
        order: index,
      });
      created += 1;
    }
  }

  console.log(
    `[seed-habits] Done. Created ${created}, skipped ${skipped} (already existed), ${missingCategories} category group(s) not found on this env.`,
  );
  await mongoose.disconnect();
}

main().catch((err) => {
  console.error('[seed-habits] Failed:', err);
  process.exit(1);
});
