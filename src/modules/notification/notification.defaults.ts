import {
  NotificationDeeplink,
  NotificationType,
} from './notification.enum';
import {
  INotificationCopy,
  INotificationVariant,
} from './schema/notification-template.schema';

export interface INotificationTemplateSeed {
  type: NotificationType;
  enabled: boolean;
  localHour: number;
  /** Optional: absent means on the hour. */
  localMinute?: number;
  /** Optional ISO weekday (1 = Monday … 7 = Sunday): absent means daily. */
  localWeekday?: number;
  deeplink: NotificationDeeplink;
  /**
   * Every wording the type ships with. The seeder mirrors the first one into the
   * legacy `copies` field, so a document is readable both ways.
   */
  variants: INotificationVariant[];
}

/** Shorthand for the seeds below: one variant, spelled locale by locale. */
const variant = (
  key: string,
  copies: Record<string, INotificationCopy>,
): INotificationVariant => ({ key, copies });

/**
 * The unfinished-lesson nudge, transcribed from the "Noti" sheet (Version 3).
 *
 * Seven wordings, rotated per user per day. The sheet writes `{lesson_name}`;
 * these use `{course_name}` because that is what the value has always been — the
 * tap lands on the course roadmap — and the sentences say "khoá học" for the same
 * reason. `{lesson_name}` still renders for copy saved before the rename.
 *
 * Variants 5 and 6 need `{topic_name}` (the course's category). The picker drops
 * them for a course with no category rather than pushing the raw placeholder.
 */
const PROGRESS_FINISH_VARIANTS: INotificationVariant[] = [
  variant('v1', {
    vi: {
      title: 'Chỉ 5 phút trước bữa trưa 🍔',
      body: 'Để {user_name} hoàn thành khoá học "{course_name}" đang chờ...',
    },
    en: {
      title: 'Just 5 minutes before lunch 🍔',
      body: 'Time for {user_name} to finish "{course_name}" — it is still waiting.',
    },
    ko: {
      title: '점심 전 딱 5분 🍔',
      body: '{user_name}님, 기다리고 있는 "{course_name}" 코스를 마무리해 보세요.',
    },
    zh: {
      title: '午饭前只需 5 分钟 🍔',
      body: '{user_name}，「{course_name}」还在等你完成哦。',
    },
    ja: {
      title: 'ランチ前の5分だけ 🍔',
      body: '{user_name}さん、まだ途中の「{course_name}」を終わらせましょう。',
    },
  }),
  variant('v2', {
    vi: {
      title: 'Một chút tiến bộ mỗi ngày là đủ 🌱',
      body: 'Chỉ 5 phút để {user_name} hoàn thành khoá học còn dang dở 👉 Học ngay',
    },
    en: {
      title: 'A little progress each day is enough 🌱',
      body: 'Five minutes is all {user_name} needs to finish what is left 👉 Start now',
    },
    ko: {
      title: '매일 조금씩이면 충분해요 🌱',
      body: '{user_name}님, 5분이면 남은 학습을 마칠 수 있어요 👉 지금 시작',
    },
    zh: {
      title: '每天进步一点就够了 🌱',
      body: '{user_name}，只要 5 分钟就能完成没学完的内容 👉 立即学习',
    },
    ja: {
      title: '毎日少しずつで十分です 🌱',
      body: '{user_name}さん、5分で途中の学習を終えられます 👉 今すぐ学ぶ',
    },
  }),
  variant('v3', {
    vi: {
      title: '5 phút hôm nay, kỹ năng cả đời ⏳',
      body: '{user_name} hãy hoàn thành khoá học "{course_name}" để phát triển kỹ năng cho mình nhé!',
    },
    en: {
      title: 'Five minutes today, a skill for life ⏳',
      body: '{user_name}, finish "{course_name}" and keep building your skills!',
    },
    ko: {
      title: '오늘의 5분, 평생의 기술 ⏳',
      body: '{user_name}님, "{course_name}" 코스를 완료하고 실력을 키워 보세요!',
    },
    zh: {
      title: '今天 5 分钟，技能受用一生 ⏳',
      body: '{user_name}，完成「{course_name}」，让技能再上一层！',
    },
    ja: {
      title: '今日の5分が一生のスキルに ⏳',
      body: '{user_name}さん、「{course_name}」を終えてスキルを伸ばしましょう！',
    },
  }),
  variant('v4', {
    vi: {
      title: 'Bộ não thích sự đều đặn 🧠',
      body: 'Tiếp tục khoá học "{course_name}" dang dở để tự tổng hợp kiến thức và xây dựng thói quen.',
    },
    en: {
      title: 'Your brain likes consistency 🧠',
      body: 'Pick "{course_name}" back up to connect what you have learned and keep the habit going.',
    },
    ko: {
      title: '뇌는 꾸준함을 좋아해요 🧠',
      body: '"{course_name}" 코스를 이어서 배우며 배운 내용을 정리하고 습관을 만들어 보세요.',
    },
    zh: {
      title: '大脑喜欢规律 🧠',
      body: '继续未完成的「{course_name}」，把学过的内容串起来，也把习惯坚持下去。',
    },
    ja: {
      title: '脳は継続が好きです 🧠',
      body: '途中の「{course_name}」を再開して、学んだことを整理し習慣を続けましょう。',
    },
  }),
  variant('v5', {
    vi: {
      title: '❓ {user_name} vẫn muốn {topic_name} chứ?',
      body: 'Hãy dành 5 phút để hoàn thành "{course_name}" còn dang dở.',
    },
    en: {
      title: '❓ Still aiming for {topic_name}, {user_name}?',
      body: 'Take five minutes and finish "{course_name}".',
    },
    ko: {
      title: '❓ {user_name}님, {topic_name} 목표는 그대로죠?',
      body: '5분만 내어 "{course_name}" 코스를 마무리해 보세요.',
    },
    zh: {
      title: '❓ {user_name}，还想继续 {topic_name} 吗？',
      body: '花 5 分钟完成没学完的「{course_name}」吧。',
    },
    ja: {
      title: '❓ {user_name}さん、{topic_name} はまだ目標ですか？',
      body: '5分だけ使って「{course_name}」を終わらせましょう。',
    },
  }),
  variant('v6', {
    vi: {
      title: 'Hành động nhỏ, khác biệt lớn 🌟',
      body: '5 phút để {topic_name} bằng cách hoàn thành khoá học "{course_name}".',
    },
    en: {
      title: 'Small action, big difference 🌟',
      body: 'Five minutes toward {topic_name} — just finish "{course_name}".',
    },
    ko: {
      title: '작은 실천, 큰 변화 🌟',
      body: '"{course_name}" 코스를 마치며 {topic_name}에 5분을 투자해 보세요.',
    },
    zh: {
      title: '小行动，大不同 🌟',
      body: '用 5 分钟完成「{course_name}」，离 {topic_name} 更近一步。',
    },
    ja: {
      title: '小さな行動が大きな差に 🌟',
      body: '「{course_name}」を終えて、{topic_name} に5分を使いましょう。',
    },
  }),
  variant('v7', {
    vi: {
      title: '🍹 Thư giãn một chút...',
      body: 'Sau một buổi sáng chăm chỉ, mở HDDhistory và hoàn thành "{course_name}" nhé {user_name} ơi!',
    },
    en: {
      title: '🍹 Time for a little break...',
      body: 'After a busy morning, open HDDhistory and finish "{course_name}", {user_name}!',
    },
    ko: {
      title: '🍹 잠시 쉬어갈 시간...',
      body: '바쁜 오전을 보냈으니, HDDhistory을 열고 "{course_name}" 코스를 마무리해요 {user_name}님!',
    },
    zh: {
      title: '🍹 稍微放松一下...',
      body: '忙了一上午，打开 HDDhistory 完成「{course_name}」吧，{user_name}！',
    },
    ja: {
      title: '🍹 少し休憩しませんか...',
      body: '忙しい午前のあとは、HDDhistoryを開いて「{course_name}」を終わらせましょう、{user_name}さん！',
    },
  }),
];

/**
 * The second segment of the same sheet row: the 11:45 nudge for readers who have
 * nothing unfinished — either they have not started anything, or they finished
 * everything they started.
 *
 * Shares its titles with PROGRESS_FINISH on purpose. The sheet writes them
 * identically, and the two never reach the same reader on the same day, so the
 * pair reads as one campaign whose second sentence adapts.
 *
 * No `{course_name}` anywhere: a tap lands on the catalog rather than on a
 * course, so naming one would promise a screen the reader never sees. Variants 3
 * and 6 ask for `{topic_name}`; when it cannot be resolved the picker drops them
 * and the remaining five still rotate wide enough to clear the three-day
 * cooldown.
 */
const PROGRESS_START_VARIANTS: INotificationVariant[] = [
  variant('v1', {
    vi: {
      title: 'Chỉ 5 phút trước bữa trưa 🍔',
      body: 'Bắt đầu một bài học mới để nâng cấp bản thân nhé {user_name} ơi!',
    },
    en: {
      title: 'Just 5 minutes before lunch 🍔',
      body: 'Start a new lesson and level up, {user_name}!',
    },
    ko: {
      title: '점심 전 딱 5분 🍔',
      body: '{user_name}님, 새로운 레슨을 시작하고 한 단계 더 성장해 보세요!',
    },
    zh: {
      title: '午饭前只需 5 分钟 🍔',
      body: '{user_name}，开始一节新课，让自己再提升一点吧！',
    },
    ja: {
      title: 'ランチ前の5分だけ 🍔',
      body: '{user_name}さん、新しいレッスンを始めて自分をアップデートしましょう！',
    },
  }),
  variant('v2', {
    vi: {
      title: 'Một chút tiến bộ mỗi ngày là đủ 🌱',
      body: 'Dành 5 phút học để xây dựng một thói quen tốt {user_name} nhé 👉 Bắt đầu ngay',
    },
    en: {
      title: 'A little progress each day is enough 🌱',
      body: '{user_name}, spend five minutes learning and build a habit that lasts 👉 Start now',
    },
    ko: {
      title: '매일 조금씩이면 충분해요 🌱',
      body: '{user_name}님, 5분 동안 학습하며 좋은 습관을 만들어 보세요 👉 지금 시작',
    },
    zh: {
      title: '每天进步一点就够了 🌱',
      body: '{user_name}，花 5 分钟学习，养成一个好习惯吧 👉 立即开始',
    },
    ja: {
      title: '毎日少しずつで十分です 🌱',
      body: '{user_name}さん、5分だけ学んでよい習慣をつくりましょう 👉 今すぐ始める',
    },
  }),
  variant('v3', {
    vi: {
      title: '5 phút hôm nay, kỹ năng cả đời ⏳',
      body: 'Khám phá một bài học mới về "{topic_name}" để phát triển kỹ năng cho mình nhé!',
    },
    en: {
      title: 'Five minutes today, a skill for life ⏳',
      body: 'Explore a new lesson on "{topic_name}" and keep building your skills!',
    },
    ko: {
      title: '오늘의 5분, 평생의 기술 ⏳',
      body: '"{topic_name}"에 관한 새로운 레슨을 살펴보고 실력을 키워 보세요!',
    },
    zh: {
      title: '今天 5 分钟，技能受用一生 ⏳',
      body: '探索一节关于「{topic_name}」的新课程，让技能再上一层！',
    },
    ja: {
      title: '今日の5分が一生のスキルに ⏳',
      body: '「{topic_name}」の新しいレッスンで、スキルを伸ばしましょう！',
    },
  }),
  variant('v4', {
    vi: {
      title: 'Bộ não thích sự đều đặn 🧠',
      body: 'Giữ nhịp học mỗi ngày bằng cách mở HDDhistory và bắt đầu một bài mới ngay nha!',
    },
    en: {
      title: 'Your brain likes consistency 🧠',
      body: 'Keep the daily rhythm going — open HDDhistory and start a new lesson now.',
    },
    ko: {
      title: '뇌는 꾸준함을 좋아해요 🧠',
      body: 'HDDhistory을 열고 새 레슨을 시작해 매일의 학습 리듬을 이어 가세요!',
    },
    zh: {
      title: '大脑喜欢规律 🧠',
      body: '打开 HDDhistory，开始一节新课，把每天的学习节奏保持下去。',
    },
    ja: {
      title: '脳は継続が好きです 🧠',
      body: 'HDDhistoryを開いて新しいレッスンを始め、毎日の学習リズムを保ちましょう。',
    },
  }),
  variant('v5', {
    vi: {
      title: '❓ {user_name} muốn giỏi hơn về điều gì?',
      body: 'Dành 5 phút khám phá một chủ đề thú vị trên HDDhistory nhé.',
    },
    en: {
      title: '❓ What would {user_name} like to get better at?',
      body: 'Spend five minutes exploring a topic that interests you on HDDhistory.',
    },
    ko: {
      title: '❓ {user_name}님, 어떤 분야에서 더 성장하고 싶나요?',
      body: 'HDDhistory에서 흥미로운 주제를 5분 동안 살펴보세요.',
    },
    zh: {
      title: '❓ {user_name}，你想在哪方面变得更好？',
      body: '花 5 分钟在 HDDhistory 上探索一个感兴趣的主题吧。',
    },
    ja: {
      title: '❓ {user_name}さん、何をもっと伸ばしたいですか？',
      body: 'HDDhistoryで興味のあるテーマを5分だけのぞいてみましょう。',
    },
  }),
  variant('v6', {
    vi: {
      title: 'Hành động nhỏ, khác biệt lớn 🌟',
      body: '5 phút để tiến bộ hơn mọi ngày bằng một bài học mới về "{topic_name}", {user_name} nhé!',
    },
    en: {
      title: 'Small action, big difference 🌟',
      body: 'Move forward today with a new five-minute lesson on "{topic_name}", {user_name}!',
    },
    ko: {
      title: '작은 실천, 큰 변화 🌟',
      body: '{user_name}님, "{topic_name}"에 관한 5분 레슨으로 오늘도 한 걸음 나아가 보세요!',
    },
    zh: {
      title: '小行动，大不同 🌟',
      body: '{user_name}，用一节关于「{topic_name}」的 5 分钟新课，让今天再进步一点！',
    },
    ja: {
      title: '小さな行動が大きな差に 🌟',
      body: '{user_name}さん、「{topic_name}」の5分レッスンで今日も一歩前進しましょう！',
    },
  }),
  variant('v7', {
    vi: {
      title: '🍵 Thư giãn một chút...',
      body: 'Sau một buổi sáng chăm chỉ, mở HDDhistory và học thêm điều mới nhé {user_name} ơi!',
    },
    en: {
      title: '🍵 Time for a little break...',
      body: 'After a busy morning, open HDDhistory and learn something new, {user_name}!',
    },
    ko: {
      title: '🍵 잠시 쉬어갈 시간...',
      body: '바쁜 오전을 보냈으니, HDDhistory을 열고 새로운 것을 배워 보세요 {user_name}님!',
    },
    zh: {
      title: '🍵 稍微放松一下...',
      body: '忙了一上午，打开 HDDhistory 学点新东西吧，{user_name}！',
    },
    ja: {
      title: '🍵 少し休憩しませんか...',
      body: '忙しい午前のあとは、HDDhistoryを開いて新しいことを学びましょう、{user_name}さん！',
    },
  }),
];

/**
 * The new-course announcement, from the same sheet.
 *
 * The sheet picks between these three by behaviour (just finished a course /
 * has a declared topic / everyone else); this ships them as a plain rotation
 * instead, so the sentences must hold for ANY reader. Two claims were therefore
 * dropped from the sheet's wording: "đã hoàn thành khóa học trước rất tốt" in the
 * first and "đúng thứ bạn đang luyện" in the third — both assert a behaviour a
 * randomly-picked reader may not have.
 */
const NEW_COURSE_VARIANTS: INotificationVariant[] = [
  variant('v1', {
    vi: {
      title: '🎯 Học xong rồi, học gì nữa nhỉ?',
      body: '"{course_name}" là bước tiếp theo cho {user_name}. Thử nhé!',
    },
    en: {
      title: '🎯 Done learning — what is next?',
      body: '"{course_name}" is a good next step for {user_name}. Give it a try!',
    },
    ko: {
      title: '🎯 다 배웠다면, 다음은 뭘까요?',
      body: '{user_name}님의 다음 단계는 "{course_name}" 코스예요. 한번 시작해 보세요!',
    },
    zh: {
      title: '🎯 学完了，接下来学什么？',
      body: '「{course_name}」是 {user_name} 的下一步，试试看！',
    },
    ja: {
      title: '🎯 学び終えたら、次は何を？',
      body: '{user_name}さんの次の一歩は「{course_name}」です。試してみましょう！',
    },
  }),
  variant('v2', {
    vi: {
      title: 'Khoá mới vừa ra lò 🔥',
      body: 'Khoá học "{course_name}" vừa lên sóng. {user_name} hãy là người đầu tiên khám phá!',
    },
    en: {
      title: 'A new course just landed 🔥',
      body: '"{course_name}" is now live. Be the first to explore it, {user_name}!',
    },
    ko: {
      title: '새 코스가 도착했어요 🔥',
      body: '"{course_name}" 코스가 공개됐어요. {user_name}님이 가장 먼저 만나 보세요!',
    },
    zh: {
      title: '新课刚刚上线 🔥',
      body: '「{course_name}」已经上线，{user_name}，来做第一个探索的人！',
    },
    ja: {
      title: '新しいコースが登場 🔥',
      body: '「{course_name}」が公開されました。{user_name}さん、いちばんに体験してみて！',
    },
  }),
  variant('v3', {
    vi: {
      title: '✨ Có khoá mới cho hành trình {topic_name}',
      body: '{user_name} ơi, "{course_name}" vừa lên sóng. Học thử 5 phút nhé!',
    },
    en: {
      title: '✨ A new course for your {topic_name} journey',
      body: '{user_name}, "{course_name}" is now live. Try it for five minutes!',
    },
    ko: {
      title: '✨ {topic_name} 여정에 새 코스가 생겼어요',
      body: '{user_name}님, "{course_name}" 코스가 공개됐어요. 5분만 체험해 보세요!',
    },
    zh: {
      title: '✨ {topic_name} 之旅有新课了',
      body: '{user_name}，「{course_name}」已上线，先学 5 分钟看看！',
    },
    ja: {
      title: '✨ {topic_name} の旅に新しいコース',
      body: '{user_name}さん、「{course_name}」が公開されました。5分だけ試してみませんか！',
    },
  }),
];

/**
 * Phase 1 content, transcribed from the "Noti" sheet.
 *
 * Seeded on first read so the admin screen opens with the agreed copy instead of
 * empty boxes; after that the database wins and this is never re-applied — an
 * editor's wording must not be reverted by a deploy. Which also means an
 * environment that already has a document does NOT pick the variants up from
 * here: import `plans/260804-notification-variants-new-course/
 * notification-templates-v3.json` from the admin screen instead.
 *
 * All of them ship DISABLED. Turning one on is an explicit act in the admin
 * screen, so merging this code cannot start pushing to real users.
 */
export const DEFAULT_NOTIFICATION_TEMPLATES: INotificationTemplateSeed[] = [
  {
    type: NotificationType.DAILY_REMIND,
    enabled: false,
    localHour: 8,
    deeplink: NotificationDeeplink.HOME,
    // The sheet asks for motivation quotes rather than fixed wording, so the body
    // is just `{quote}` — the dispatcher fills it from the quotes collection.
    variants: [
      variant('v1', {
        en: { title: 'A thought for today ☀️', body: '{quote}' },
        vi: { title: 'Một câu cho hôm nay ☀️', body: '{quote}' },
        ko: { title: '오늘의 한마디 ☀️', body: '{quote}' },
        zh: { title: '今天的一句话 ☀️', body: '{quote}' },
        ja: { title: '今日のひとこと ☀️', body: '{quote}' },
      }),
    ],
  },
  {
    // 11:45 per Version 3 of the sheet — just before lunch, which several of the
    // wordings lean on.
    type: NotificationType.PROGRESS_FINISH,
    enabled: false,
    localHour: 11,
    localMinute: 45,
    deeplink: NotificationDeeplink.RESUME_LESSON,
    variants: PROGRESS_FINISH_VARIANTS,
  },
  {
    // Deliberately the same minute as PROGRESS_FINISH: the sheet treats the two
    // as one 11:45 nudge split by whether anything is unfinished, and their
    // conditions cannot both hold, so nobody receives both.
    type: NotificationType.PROGRESS_START,
    enabled: false,
    localHour: 11,
    localMinute: 45,
    // HOME, not EXPLORE, even though the sheet asks for the catalog: the app
    // ignores destinations it does not know, so shipping EXPLORE today would
    // make the tap do nothing on every install currently out there. Switch it in
    // the admin screen once a build that handles EXPLORE has shipped.
    deeplink: NotificationDeeplink.HOME,
    variants: PROGRESS_START_VARIANTS,
  },
  {
    type: NotificationType.NEW_COURSE,
    enabled: false,
    localHour: 20,
    deeplink: NotificationDeeplink.NEW_COURSE,
    variants: NEW_COURSE_VARIANTS,
  },
  {
    type: NotificationType.HABIT_TRACKING,
    enabled: false,
    localHour: 21,
    deeplink: NotificationDeeplink.HABIT_TRACKER,
    // The sheet gives one line per locale for this one, so it becomes the title
    // and the body is left for an editor to fill if they want a second line.
    variants: [
      variant('v1', {
        vi: {
          title: 'Chuỗi thói quen của bạn đang chờ được tiếp nối 🔥',
          body: '',
        },
        en: { title: "Have you checked off today's habits? 🔥", body: '' },
        ko: { title: '오늘의 습관을 모두 체크했나요? 🔥', body: '' },
        zh: { title: '今天的习惯都打卡了吗？🔥', body: '' },
        ja: { title: '今日の習慣はもうチェックしましたか？🔥', body: '' },
        id: { title: 'Sudah check-in kebiasaan hari ini? 🔥', body: '' },
        ms: { title: 'Sudahkah anda menyelesaikan tabiat hari ini? 🔥', body: '' },
        fil: { title: 'Nacheck mo na ba ang mga habit mo ngayong araw? 🔥', body: '' },
      }),
    ],
  },
  {
    // "6. Weekly recap", Nhắc lần 1 — Monday 10:00 local, all users. The first
    // weekly type: `localWeekday` keeps it to Mondays; without it the tick
    // would re-send this every day at 10:00.
    type: NotificationType.WEEKLY_RECAP_READY,
    enabled: false,
    localHour: 10,
    localWeekday: 1,
    deeplink: NotificationDeeplink.WEEK_RECAP,
    variants: [
      variant('v1', {
        vi: {
          title: 'Recap tuần qua của bạn đã sẵn sàng ✨',
          body: '{user_name} ơi, cùng nhìn lại tiến độ học và thói quen tuần qua để biết mình đã tiến bộ thế nào nhé!',
        },
        en: {
          title: 'Your weekly recap is ready ✨',
          body: "{user_name}, look back at your learning and habits to see how far you've come!",
        },
        ko: {
          title: '지난주 리캡이 준비됐어요 ✨',
          body: '{user_name}, 지난주 학습과 습관을 돌아보고 얼마나 성장했는지 확인해 보세요!',
        },
        zh: {
          title: '你的每周回顾已准备好 ✨',
          body: '{user_name}，一起回顾上周的学习和习惯，看看自己进步了多少吧！',
        },
        ja: {
          title: '先週の振り返りができました ✨',
          body: '{user_name}さん、先週の学習と習慣を振り返って、どれだけ成長したか見てみましょう！',
        },
      }),
    ],
  },
  {
    // Nhắc lần 2 — Monday 19:00 local, only for readers whose recap is still
    // unVIEWED (`viewedAt` on the week's snapshot; no snapshot row counts as
    // unviewed — generation is lazy, so a reader who never opened the app since
    // Monday has no row and is exactly who this is for).
    type: NotificationType.WEEKLY_RECAP_REMINDER,
    enabled: false,
    localHour: 19,
    localWeekday: 1,
    deeplink: NotificationDeeplink.WEEK_RECAP,
    variants: [
      variant('v1', {
        vi: {
          title: 'Đừng bỏ lỡ tiến bộ tuần qua 🔍',
          body: '{user_name} ơi, xem lại tiến độ và thói quen tuần qua trước khi bắt đầu tuần mới nhé!',
        },
        en: {
          title: "Don't miss your progress 🔍",
          body: "{user_name}, look back at last week's progress and habits before starting the new week!",
        },
        ko: {
          title: '지난주 성장을 놓치지 마세요 🔍',
          body: '{user_name}, 새 주를 시작하기 전에 지난주 학습과 습관을 돌아보세요!',
        },
        zh: {
          title: '别错过上周的进步 🔍',
          body: '{user_name}，新的一周开始前，一起回顾上周的进步和习惯吧！',
        },
        ja: {
          title: '先週の成長を見逃さないで 🔍',
          body: '{user_name}さん、新しい週を始める前に、先週の学習と習慣を振り返りましょう！',
        },
      }),
    ],
  },
  {
    /**
     * ④ The Coach's commitment reminder.
     *
     * `localHour` here is INERT and 0 says so: this type is skipped by the
     * template loop entirely (`dispatchDueNotifications`), because the reader
     * chose the hour themselves when they made the promise. What this row
     * actually carries is the sentence FRAME in five languages — the reminder's
     * content is `{context}` and `{action}`, which are the reader's own words
     * and could never live in a template.
     *
     * Disabled by default like the recap pair: someone turns this on when the
     * feature is ready to reach real people.
     */
    type: NotificationType.COACH_PLAN_REMINDER,
    enabled: false,
    localHour: 0,
    deeplink: NotificationDeeplink.COACH,
    variants: [
      variant('v1', {
        vi: {
          title: '{context} — {action}.',
          body: 'Hôm nay có dịp nào chưa?',
        },
        en: {
          title: '{context} — {action}.',
          body: 'Has the moment come up yet today?',
        },
        ko: {
          title: '{context} — {action}.',
          body: '오늘 그런 순간이 있었나요?',
        },
        zh: {
          title: '{context} — {action}。',
          body: '今天遇到这样的时刻了吗？',
        },
        ja: {
          title: '{context} — {action}。',
          body: '今日、その場面はありましたか？',
        },
      }),
    ],
  },
  {
    /**
     * Nhắc học theo GIỜ USER CHỌN ở onboarding (S8) — cùng dạng với
     * COACH_PLAN_REMINDER: `localHour` ở đây TRƠ, bị bỏ qua ở
     * `dispatchDueNotifications`, vì giờ gửi thật nằm ở
     * `users.studyReminderTime`. Xem `OnboardingStudyReminderDispatcher`.
     */
    type: NotificationType.ONBOARDING_STUDY_REMINDER,
    enabled: false,
    localHour: 0,
    deeplink: NotificationDeeplink.HOME,
    variants: [
      // `{user_name}` lives in the TITLE, not the body: `pickVariant` treats it
      // as optional, and a reader with no name still gets v1 whenever v2 is
      // disqualified (its `{course_name}` cannot resolve). A trailing
      // `{user_name}` in the body rendered as an orphaned ", ." for that reader
      // — putting it in the title keeps the body a complete sentence either way.
      variant('v1', {
        vi: {
          title: 'Đến giờ tập trung, {user_name} 🌟',
          body: 'Bài học 2 phút của bạn đã sẵn sàng.',
        },
        en: {
          title: 'Time to focus, {user_name} 🌟',
          body: 'Your 2-minute lesson is ready.',
        },
        ko: {
          title: '집중할 시간이에요, {user_name}님 🌟',
          body: '2분 레슨이 준비되었어요.',
        },
        zh: {
          title: '专注时间到，{user_name} 🌟',
          body: '你的2分钟课程已准备好。',
        },
        ja: {
          title: '集中の時間です、{user_name}さん 🌟',
          body: '2分レッスンの準備ができました。',
        },
      }),
      variant('v2', {
        vi: {
          title: 'Giữ nhịp học hôm nay',
          body: 'Tiếp tục «{course_name}» — 2 phút là đủ.',
        },
        en: {
          title: "Keep today's streak",
          body: 'Continue “{course_name}” — two minutes is enough.',
        },
        ko: {
          title: '오늘의 학습 리듬 유지하기',
          body: '“{course_name}” 이어서 — 2분이면 충분해요.',
        },
        zh: {
          title: '保持今天的学习节奏',
          body: '继续《{course_name}》— 两分钟就够。',
        },
        ja: {
          title: '今日の学習リズムを保とう',
          body: '「{course_name}」を続けよう — 2分で十分。',
        },
      }),
    ],
  },
];

/**
 * At most this many notifications per user per local day, across all types.
 *
 * Nine types now exist (daily quote, the progress finish/start pair sharing
 * one slot, new course, habit tracking, the weekly recap pair, the Coach's
 * plan reminder, and onboarding_study_reminder), so a cap of 4 can now
 * genuinely outrank one of them on a busy day — including
 * onboarding_study_reminder, even though its send time is the one thing the
 * READER chose for themselves at onboarding, not a time this file picked.
 * Whether a self-chosen reminder should win a slot over a system nudge ahead
 * of it, or whether the cap itself should grow past four now that there are
 * nine types instead of five, is an open product decision this comment does
 * not settle — don't bump the number without that conversation.
 *
 * It was 2 while there were three types, which meant the 20:00 and 21:00
 * nudges were unreachable for any reader who qualified for the two morning
 * ones.
 */
export const MAX_NOTIFICATIONS_PER_DAY = 4;
