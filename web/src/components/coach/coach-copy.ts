/**
 * Chữ của Coach, chép từ `assets/i18n/vi/coach.yaml` của app.
 *
 * Server chỉ gửi KHOÁ cho các câu cố định (điều hướng: "hôm nay bạn thấy thế
 * nào?") và gửi nguyên câu cho phần model viết. Bốn bảng đầu được sinh từ
 * `coach_prompt_map.dart` + yaml, cùng thứ tự với app, nên một khoá server mới
 * mà web chưa có sẽ là một lỗ nhìn thấy được ở đây chứ không phải khoá thô hiện
 * lên màn hình (`coachPrompt` trả null và bong bóng bị bỏ qua — như app).
 */

export const PROMPTS: Record<string, string> = {
  'coach.prompt.mood': 'Trước khi bắt đầu — hôm nay bạn thấy thế nào?',
  'coach.prompt.moodEnd': 'Trước khi đóng — giờ bạn thấy thế nào?',
  'coach.prompt.pickNew': 'Bạn vừa thêm mấy habit mới. Mình nói về cái nào trước?',
  'coach.prompt.intent': 'Hôm trước bạn nói: ${context} sẽ ${action}. Có dịp nào chưa?',
  'coach.prompt.intentTell': 'Kể mình nghe một câu: lúc đó bạn nói hay làm gì?',
  'coach.prompt.barrier': 'Có dịp mà chưa làm là chuyện thường, mình không tính là thất bại. Lúc đó điều gì làm bạn dừng lại?',
  'coach.prompt.intentNone': 'Vậy là bối cảnh chưa xuất hiện, không phải bạn tránh. Mình giữ nhắc hẹn này lại.',
  'coach.prompt.intentTellDone': 'Mình lưu nguyên văn câu bạn vừa kể.',
  'coach.prompt.intentTellMissed': 'Mình ghi nhận.',
  'coach.prompt.planSlept': 'Cái hẹn này mình tạm cất đi nhé. Khi nào cần thì bạn gọi lại.',
  'coach.prompt.loop': 'Còn một nhắc hẹn nữa. Nói tiếp hay dừng ở đây?',
  'coach.prompt.shrinkAsk': 'Bạn có muốn thay đổi nhắc hẹn cho đơn giản hơn không?',
  'coach.prompt.shrinkEdit': 'Sửa lại cho nhỏ hơn — vẫn là chữ của bạn.',
  'coach.prompt.shrinkDone': 'Mình đổi sang bản nhỏ hơn. Giờ nhắc giữ nguyên.',
  'coach.prompt.onboardAddress': 'Mình gọi bạn là gì cho tiện nhỉ?',
  'coach.prompt.onboardAddressConfirm': 'Mình gọi là ${name} nhé?',
  'coach.prompt.story': 'Hôm nay có chuyện gì mới không?',
  'coach.prompt.storyOpen': 'Ừ, kể mình nghe đi. Dạo này thế nào rồi — có gì vui hay đang nghĩ về chuyện gì không?',
  'coach.prompt.storyMore': 'Hôm nay còn chuyện gì mới không?',
  'coach.prompt.tellFollowUp': 'Mình hỏi lại đúng điều đã xảy ra: lúc đó ai nói gì, ai làm gì?',
  'coach.prompt.twoCols': 'Mình gom lại thành nháp hai cột — toàn bằng lời bạn. Kéo dòng nào là vấn đề thật của bạn sang phải, rồi viết lại một câu.',
  'coach.prompt.redraft': 'Mình hiểu sai rồi. Vậy bạn kể lại giúp mình: chuyện gì đã xảy ra?',
  'coach.prompt.problemAck': 'Đó là câu của bạn, mình không sửa.',
  'coach.prompt.invite': 'Mình có một cảnh ngắn để tập. Không bắt buộc — bỏ qua cũng được.',
  'coach.prompt.lessonIntro': 'Bạn vừa thêm “${habit}”.',
  'coach.prompt.sceneLead': 'Một cảnh ngắn:',
  'coach.prompt.sceneAck': 'Mình nghe rồi — không chấm đúng sai. Đây là cách bạn nhìn tình huống đó hôm nay.',
  'coach.prompt.jotAck': 'Mình ghi lại rồi nhé.',
  'coach.prompt.sceneAgain': 'Thử nói lại theo cách của bạn xem?',
  'coach.prompt.sceneDone': 'Vậy mình dừng cảnh ở đây nhé.',
  'coach.prompt.closingHeard': 'Mình nghe rồi. Khi nào muốn nói tiếp thì mình ở đây.',
  'coach.prompt.sceneFeeling': 'Lúc đó, bạn cảm thấy thế nào?',
  'coach.prompt.sceneFeelingThird': 'Nếu là người đó, lúc đó bạn cảm thấy thế nào?',
  'coach.prompt.sceneFeelingAck': 'Cảm giác đó dễ hiểu.',
  'coach.prompt.hub': 'Xong rồi. Còn gì bạn muốn nói không?',
  'coach.prompt.hubBack': 'Hôm trước bạn kể chuyện ${topic}. Hôm nay thế nào?',
  'coach.prompt.talkAsk': 'Nói một chút về phần vừa học nhé? Bắt đầu kiểu nào?',
  'coach.prompt.quizHandoff': 'Vài câu về phần này nhé.',
  'coach.prompt.talkWhen': 'Học tiếp phần sau chứ?',
  'coach.prompt.recapPick': 'Bạn vừa xong «${course}». Nhìn lại một chút nhé? Bài nào ở lại với bạn lâu nhất?',
  'coach.prompt.recapQuiz': 'Làm vài câu random từ cả khoá xem còn nhớ gì nhé?',
  'coach.prompt.checkinTell': 'Kể mình một câu: lúc đó bạn đã nói hay làm gì?',
  'coach.prompt.scenePick': 'Bạn muốn tập cái nào trong kho của bạn?',
  'coach.prompt.sceneRetry': 'Một tình huống tương tự:',
  'coach.prompt.hubOpen': 'Hôm nay bạn muốn làm gì?',
  'coach.prompt.sceneMet': 'Ngoài đời bạn gặp chuyện kiểu này chưa?',
  'coach.prompt.sceneWhen': 'Lúc đó là lúc nào?',
  'coach.prompt.sceneDid': 'Hôm đó bạn làm gì?',
  'coach.prompt.sceneChange': 'Lần sau gặp lại, bạn muốn làm khác đi không?',
  'coach.prompt.retryScene': 'Tình huống này bạn từng gặp ba tuần trước. Thử lại xem sao?',
  'coach.prompt.retryAck': 'Ghi rồi. Recap thứ 2 sẽ đặt hai câu cạnh nhau và im lặng — không bình luận.',
  'coach.prompt.storyOpenBad1': 'Hôm nay thế nào?',
  'coach.prompt.storyOpenBad2': 'Hôm nay của bạn ra sao?',
  'coach.prompt.storyOpenBad3': 'Giờ này bạn thế nào?',
  'coach.prompt.storyOpenTired1': 'Có gì đang chiếm chỗ trong đầu bạn không?',
  'coach.prompt.storyOpenTired2': 'Đang có gì vướng trong đầu không?',
  'coach.prompt.storyOpenTired3': 'Có chuyện gì đang lởn vởn không?',
  'coach.prompt.storyOpenOk1': 'Hôm nay có chuyện gì mới không?',
  'coach.prompt.storyOpenOk2': 'Hôm nay có gì mới không?',
  'coach.prompt.storyOpenOk3': 'Có chuyện gì hôm nay không?',
  'coach.prompt.storyOpenGood1': 'Hôm nay có gì đáng kể lại không?',
  'coach.prompt.storyOpenGood2': 'Có chuyện gì đáng kể lại hôm nay không?',
  'coach.prompt.storyOpenGood3': 'Hôm nay có gì muốn kể không?',
  'coach.prompt.storyOpenGreat1': 'Hôm nay có chuyện gì hay không?',
  'coach.prompt.storyOpenGreat2': 'Có chuyện gì hay hôm nay không?',
  'coach.prompt.storyOpenGreat3': 'Hôm nay có gì vui không?',
  'coach.scene.habitLabel': 'Với thói quen:',
  'coach.scene.setupLabel': 'Tôi có tình huống:',
  'coach.prompt.sceneScore': 'Mình bước ra khỏi tình huống một chút.',
  'coach.prompt.planAsk': 'Muốn đặt một Nhắc hẹn cho lần tới không?',
  'coach.prompt.plan': 'Viết bằng chữ của bạn: khi nào, và sẽ làm gì?',
  'coach.prompt.schedule': 'Ghi rồi. Nhắc bạn lúc nào?',
  'coach.prompt.courseCard': 'Có một khoá gần với chuyện bạn vừa nói tới.',
  'coach.prompt.courseLeave': 'Mình mở khoá đó cho bạn. Cứ xem một lesson thôi cũng được.',
  'coach.prompt.rating': 'Cảm ơn bạn.',
  'coach.prompt.closingNoPlan': 'Ghi lại rồi nhé. Khi nào muốn nói tiếp thì mình ở đây.',
  'coach.prompt.endLesson': 'Tập vậy là đủ cho hôm nay.',
  'coach.prompt.endStop': 'Vậy mình dừng ở đây nhé.',
  'coach.prompt.safety': 'Cảm ơn bạn đã nói ra điều này. Mình muốn bạn không phải ở một mình với nó.',
  'coach.fallback.reply': 'Mình nghe rồi.',
  'coach.prompt.depth': 'Bạn muốn chia sẻ thêm không?',
  'coach.prompt.contextAsk': 'Chưa tới dịp thì thôi, mình để nguyên. Bối cảnh “${context}” có hay xảy ra không?',
  'coach.prompt.contextEdit': 'Vậy bối cảnh mới là gì?',
  'coach.prompt.nextAction': 'Vậy lần tới bạn sẽ làm gì?',
  'coach.prompt.jot': 'Được. Ghi một dòng cho hôm nay thôi, mình không hỏi gì thêm.',
  'coach.prompt.pickHabit': 'Mình hiểu sai rồi — bạn muốn nói về habit nào?',
  'coach.prompt.persona': 'Bạn muốn mình nói kiểu nào hôm nay?',
  'coach.prompt.time': 'Hôm nay bạn có bao nhiêu thời gian?',
  'coach.prompt.tell': 'Kể mình nghe chuyện gần nhất của bạn với thói quen này. Cứ nói tự do, mình không chen.',
  'coach.prompt.free': 'Hôm nay có chuyện gì không? Kể mình nghe.',
  'coach.prompt.checkin': 'Mấy hôm nay habit này có dịp nào dùng tới không?',
  'coach.prompt.end': 'Bạn muốn làm gì tiếp?',
};

export const TEASERS: Record<string, string> = {
  'coach.teaser.retry': 'Tình huống ba tuần trước…',
  'coach.teaser.firstHabit': 'Chưa có thói quen nào trong kho. Học một bài để thêm nhé?',
  'coach.teaser.habit': 'Kể mình nghe một lần thật, hay làm quiz cùng mình?',
  'coach.teaser.home': 'Vào trò chuyện một chút nhé?',
  'coach.teaser.onboard': 'Mình làm quen với bạn một chút nhé?',
};

export const COURSE_REASONS: Record<string, string> = {
  'coach.course.reasonOutside': 'Chuyện bạn vừa kể chạm tới một thứ chưa có trong kho của bạn',
  'coach.course.reasonKeypoint': 'Ý mình vừa nói nằm trong khoá này',
  'coach.course.reasonBarrier': 'Vì bạn còn vướng ở «${habit}»',
  'coach.course.reasonHabit': 'Bài đầu tiên của khoá này là «${habit}»',
  'coach.course.reasonStory': 'Từ chuyện bạn vừa kể',
  'coach.course.reasonRecap': 'Cùng nhóm kỹ năng với khoá bạn vừa xong',
  'coach.course.reasonCategory': 'Cùng hướng với thói quen bạn đang tập',
  'coach.course.reasonSaved': 'Bạn đã lưu khoá này',
  'coach.course.reasonResume': 'Khoá bạn đang học dở',
};

export const STEP_LABELS: Record<string, string> = {
  mood: 'mood đầu ngày · 5 mức, 1 chạm',
  pickNew: 'chọn thói quen',
  pickHabit: 'chọn thói quen',
  intent: 'hỏi lại Nhắc hẹn cũ',
  intentTell: 'hỏi thực chất',
  barrier: 'hỏi thực chất',
  shrinkAsk: 'thu nhỏ nhắc hẹn',
  shrink: 'thu nhỏ nhắc hẹn',
  loop: 'còn một nhắc hẹn nữa',
  story: '“Hôm nay có chuyện gì mới không?”',
  tell: 'Coach hỏi lại điều đã xảy ra',
  tell2: 'Coach hỏi lại điều đã xảy ra',
  free: 'Coach hỏi lại điều đã xảy ra',
  depth: 'Coach hỏi lại điều đã xảy ra',
  sceneFeeling: 'luyện tập tình huống',
  sceneStage2: 'luyện tập tình huống',
  sceneMet: 'luyện tập tình huống',
  sceneWhen: 'luyện tập tình huống',
  sceneDid: 'luyện tập tình huống',
  sceneChange: 'luyện tập tình huống',
  hub: 'còn gì muốn nói không',
  scenePick: 'chọn habit để tập',
  sceneFix: 'luyện tập tình huống',
  sceneRetry: 'luyện tập tình huống',
  checkinAsk: 'ghi nhận hôm nay',
  checkinTell: 'ghi nhận hôm nay',
  checkinOffer: 'ghi nhận hôm nay',
  quizInChat: 'quiz trong chat',
  talkAsk: 'thảo luận bài vừa học',
  talkSummary: 'thảo luận bài vừa học',
  talkFree: 'thảo luận bài vừa học',
  quizHandoff: 'thảo luận bài vừa học',
  quizRun: 'thảo luận bài vừa học',
  talkWhen: 'thảo luận bài vừa học',
  recapPick: 'nhìn lại cả khoá',
  recapQuiz: 'nhìn lại cả khoá',
  twoCols: 'nhịp 3 · tách 2 cột',
  redraft: 'nhịp 3 · tách 2 cột',
  invite: 'mời luyện tập tình huống',
  tellOnce: 'luyện tập tình huống',
  tellOnceA: 'luyện tập tình huống',
  tellOnceB: 'luyện tập tình huống',
  practiceAnswer: 'luyện tập tình huống',
  retryScene: 'tập lại tình huống cũ',
  sceneScore: 'xem lại cách bạn xử lý',
  planAsk: 'muốn đặt Nhắc hẹn không?',
  plan: 'Nhắc hẹn — chữ của bạn',
  schedule: 'đặt giờ + thứ trong tuần',
  courseCard: 'card course · 3 lựa chọn',
  leave: 'sang Roadmap khoá học',
  moodEnd: 'mood cuối phiên · 5 mức',
  rating: 'đánh giá cuộc trò chuyện',
  nextSession: 'dừng hay bắt đầu phiên mới?',
  end: 'câu chốt · rồi đóng',
  safety: 'đường thoát an toàn',
  jot: 'một dòng cho hôm nay',
  nextAction: 'Coach hỏi lại điều đã xảy ra',
  closing: 'Coach hỏi lại điều đã xảy ra',
  contextAsk: 'Coach hỏi lại điều đã xảy ra',
  contextEdit: 'Coach hỏi lại điều đã xảy ra',
  persona: 'Coach hỏi lại điều đã xảy ra',
  time: 'Coach hỏi lại điều đã xảy ra',
  checkin: 'Coach hỏi lại điều đã xảy ra',
};

/** Các câu có nhánh riêng trong app (gọi tên người đọc, nêu tên habit…). */
const ONBOARD_LINES: Record<string, { plain: string; to: string; leading: boolean }> = {
  'coach.prompt.onboardGoal': {
    plain: 'Bạn muốn cải thiện điều gì nhất khi trò chuyện với mọi người?',
    to: '${address} muốn cải thiện điều gì nhất khi trò chuyện với mọi người?',
    leading: true,
  },
  'coach.prompt.onboardBarrier': {
    plain: 'Điều gì hay làm bạn khó mở lời nhất?',
    to: 'Điều gì hay làm ${address} khó mở lời nhất?',
    leading: false,
  },
  'coach.prompt.onboardCurrent': {
    plain: 'Hiện tại bạn đang làm gì để luyện nói?',
    to: 'Hiện tại ${address} đang làm gì để luyện nói?',
    leading: false,
  },
  'coach.prompt.onboardStyle': {
    plain: 'Bạn học kiểu nào thấy vào nhất?',
    to: '${address} học kiểu nào thấy vào nhất?',
    leading: true,
  },
  'coach.prompt.onboardAge': {
    plain: 'Bạn ở khoảng tuổi nào? Để mình chọn tình huống cho hợp.',
    to: '${address} ở khoảng tuổi nào? Để mình chọn tình huống cho hợp.',
    leading: true,
  },
  'coach.prompt.onboardGender': {
    plain: 'Mình nên xưng hô với bạn theo giới tính nào? Không nói cũng được.',
    to: 'Mình nên hiểu ${address} theo giới tính nào? Không nói cũng được.',
    leading: false,
  },
  'coach.prompt.onboardJob': {
    plain: 'Bạn đang làm công việc gì? Gõ tay cũng được.',
    to: '${address} đang làm công việc gì? Gõ tay cũng được.',
    leading: true,
  },
};

const PRONOUNS = new Set(['bạn', 'anh', 'chị', 'em']);

function fill(template: string, args: Record<string, string>): string {
  return template.replace(/\$\{(\w+)\}/g, (_, name: string) => args[name] ?? '');
}

/** Tên habit đặt GIỮA câu: bỏ chữ hoa đầu để đọc như một cụm từ. */
function habitInline(args: Record<string, string>): string {
  const habit = (args.habit ?? '').trim();
  return habit ? habit[0].toLowerCase() + habit.slice(1) : '';
}

function capitalize(word: string): string {
  return word ? word[0].toUpperCase() + word.slice(1) : word;
}

/**
 * Câu cố định cho một khoá server, đã điền chữ của người đọc.
 *
 * Trả null với khoá lạ — bong bóng bị bỏ qua, như app: thiếu một câu điều
 * hướng còn đỡ hơn hiện khoá thô trước mặt người đang nói chuyện.
 */
export function coachPrompt(
  key: string,
  args: Record<string, string> = {},
): string | null {
  let line: string | null;
  const onboard = ONBOARD_LINES[key];
  if (onboard) {
    const address = (args.address ?? '').trim();
    if (!address) {
      line = onboard.plain;
    } else {
      // Đại từ đứng đầu câu thì viết hoa; tên riêng giữ nguyên như người ta gõ.
      const word =
        PRONOUNS.has(address) && onboard.leading ? capitalize(address) : address;
      line = fill(onboard.to, { address: word });
    }
  } else if (key === 'coach.prompt.checkinAsk') {
    const habit = habitInline(args);
    line = habit
      ? `Hôm nay bạn có dịp nào ${habit} chưa?`
      : 'Hôm nay bạn có dịp nào dùng tới thói quen này chưa?';
  } else if (key === 'coach.prompt.closingWithPlan') {
    const time = args.time ?? '';
    line = time
      ? `Vậy mai ${args.context ?? ''} nhé. Mình nhắc bạn ${time}.`
      : `Vậy mai ${args.context ?? ''} nhé.`;
  } else {
    const template = PROMPTS[key];
    line = template === undefined ? null : fill(template, args);
  }
  if (line === null) return null;

  // Câu tiếng Việt viết cho "bạn" và đi theo cách xưng hô người đọc đã chọn
  // ở bước làm quen — cách app sửa "lúc thì anh lúc thì bạn".
  return addressVi(line, args.address, [
    args.habit ?? '',
    habitInline(args),
    args.topic ?? '',
  ]);
}

/**
 * "bạn" → «anh» / «chị» / «em» / một cái tên — chỉ ngôi thứ hai, không đụng
 * danh từ ("bạn bè", "người bạn"). Bản sao của `_addressVi` trong app (và
 * `addressVi` của server). Các đoạn lấy từ NỘI DUNG (tên habit, chủ đề) được
 * giữ nguyên: đổi "bạn" trong tên habit là đặt tên người đọc vào giữa nó.
 *
 * RegExp dựng bằng constructor vì cờ `u` + `\p{L}` cần ES2018, còn tsconfig
 * nhắm ES2017.
 */
function addressVi(text: string, address: string | undefined, protect: string[]): string {
  const to = address?.trim() ?? '';
  if (!text || !to || to === 'bạn') return text;
  const cap = capitalize(to);

  const keep: [number, number][] = [];
  for (const candidate of protect) {
    const needle = candidate.trim();
    if (!needle) continue;
    for (let at = text.indexOf(needle); at !== -1; at = text.indexOf(needle, at + needle.length)) {
      keep.push([at, at + needle.length]);
    }
  }
  const isContent = (index: number) => keep.some(([a, b]) => index >= a && index < b);
  const nounAfter = new RegExp('^\\s+(bè|thân|trai|gái|cùng|học|đồng|đời|cũ|mới)(?![\\p{L}])', 'u');
  const nounBefore = new RegExp(
    '(người|cô|anh|chị|ông|bà|thằng|đứa|tụi|các|nhóm|mấy|những|đám|bọn)\\s*$',
    'u',
  );
  const pattern = new RegExp('(^|[^\\p{L}])([Bb])ạn(?![\\p{L}])', 'gu');

  return text.replace(pattern, (match: string, pre: string, b: string, offset: number) => {
    const start = offset + pre.length;
    const after = text.slice(offset + match.length);
    const before = text.slice(0, start);
    if (isContent(start)) return match;
    if (nounAfter.test(after) || nounBefore.test(before)) return match;
    return pre + (b === 'B' ? cap : to);
  });
}

export function coachTeaser(key?: string | null): string | null {
  if (!key) return null;
  if (key === 'coach.teaser.retry') return 'Tình huống ba tuần trước…';
  return TEASERS[key] ?? null;
}

export function coachCourseReason(
  key?: string | null,
  args: Record<string, string> = {},
): string | null {
  if (!key) return null;
  const template = COURSE_REASONS[key];
  return template === undefined ? null : fill(template, args);
}

export function coachStepLabel(step: string): string | null {
  return STEP_LABELS[step] ?? null;
}

/** "Hôm nay · Trang chủ" — vạch ngăn giữa hai phiên khi mở lại. */
export function dividerLabel(at: string, entry: string): string {
  const door = entry === 'lesson' ? 'Bài học' : entry === 'habit' ? 'Thói quen' : 'Trang chủ';
  const date = new Date(at);
  if (Number.isNaN(date.getTime())) return door;
  const startOf = (d: Date) => new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
  const days = Math.round((startOf(new Date()) - startOf(date)) / 86_400_000);
  const when =
    days <= 0
      ? 'Hôm nay'
      : days === 1
        ? 'Hôm qua'
        : `${date.getDate()} thg ${date.getMonth() + 1}`;
  return `${when} · ${door}`;
}

/** Một chip: giá trị gửi lên, chữ trên chip, và câu "vọng lại" thành bong bóng của người đọc. */
export interface ChipSpec {
  value: string;
  label: string;
  echo?: string;
}

/**
 * Chữ của từng bước chip — đặt cạnh nhau để một bước mới không thể có chữ mà
 * không có đích (bản sao `_chipSpecsFor` của app).
 */
export function chipSpecsFor(
  step: string,
  choices: { value: string; label?: string | null }[],
  allowNewSession: boolean,
): ChipSpec[] {
  switch (step) {
    case 'intent':
      // Ba nút PHẢI giống hệt nhau — không có câu "đúng" được tô nổi.
      return [
        { value: 'done', label: 'Đã làm được', echo: 'Mình làm được rồi.' },
        { value: 'missed', label: 'Có dịp nhưng chưa làm', echo: 'Có dịp mà mình chưa làm.' },
        { value: 'none', label: 'Không có tình huống nào', echo: 'Chưa có dịp nào.' },
      ];
    case 'invite':
      return [
        { value: 'yes', label: 'Tập thử một cảnh', echo: 'Tập thử.' },
        { value: 'no', label: 'Hôm nay bỏ qua', echo: 'Hôm nay bỏ qua.' },
      ];
    case 'onboardAddressConfirm':
      return [
        { value: 'yes', label: 'Đúng rồi', echo: 'Đúng rồi.' },
        { value: 'no', label: 'Không, gọi khác', echo: 'Không, gọi khác.' },
      ];
    case 'sceneMet':
      return [
        { value: 'yes', label: 'Rồi', echo: 'Rồi.' },
        { value: 'no', label: 'Chưa', echo: 'Chưa.' },
      ];
    case 'sceneAgain':
      return [
        { value: 'yes', label: 'Nói lại', echo: 'Nói lại.' },
        { value: 'no', label: 'Đủ rồi', echo: 'Đủ rồi.' },
      ];
    case 'quizHandoff':
      return [
        { value: 'start', label: 'Bắt đầu', echo: 'Bắt đầu.' },
        { value: 'later', label: 'Thôi, để sau', echo: 'Thôi, để sau.' },
      ];
    case 'talkWhen':
      return [
        { value: 'continue', label: 'Học tiếp', echo: 'Học tiếp.' },
        { value: 'later', label: 'Để sau', echo: 'Để sau.' },
      ];
    case 'recapQuiz':
      return [
        { value: 'try', label: 'Làm thử', echo: 'Làm thử.' },
        { value: 'later', label: 'Để sau', echo: 'Để sau.' },
      ];
    case 'quizRun':
      return [];
    case 'checkinAsk':
      return [
        { value: 'yes', label: 'Có, mình làm được', echo: 'Có, mình làm được.' },
        { value: 'no', label: 'Chưa, hôm nay không có dịp', echo: 'Chưa, hôm nay không có dịp.' },
      ];
    case 'checkinOffer':
      return [
        { value: 'yes', label: 'Ghi nhận habit đó', echo: 'Ghi nhận habit đó.' },
        { value: 'no', label: 'Để sau', echo: 'Để sau.' },
      ];
    case 'sceneFix':
      return [
        { value: 'retry', label: 'Luyện lại cảnh này', echo: 'Luyện lại cảnh này.' },
        { value: 'later', label: 'Để sau', echo: 'Để sau.' },
      ];
    case 'planAsk':
      return [
        { value: 'yes', label: 'Có, đặt Nhắc hẹn', echo: 'Có.' },
        { value: 'no', label: 'Không, đóng luôn', echo: 'Không, đóng luôn.' },
      ];
    case 'loop':
      return [
        { value: 'continue', label: 'Nói tiếp nhắc hẹn nữa' },
        { value: 'stop', label: 'Dừng ở đây' },
      ];
    case 'shrinkAsk':
      return [
        { value: 'yes', label: 'Thu nhỏ lại', echo: 'Thu nhỏ lại.' },
        { value: 'no', label: 'Giữ nguyên, thử lại', echo: 'Giữ nguyên.' },
      ];
    case 'depth':
      return [
        { value: 'shallow', label: 'Chỉ ghi lại thôi' },
        { value: 'deep', label: 'Kể sâu hơn' },
      ];
    case 'contextAsk':
      return [
        { value: 'keep', label: 'Giữ nguyên' },
        { value: 'change', label: 'Đổi bối cảnh' },
      ];
    case 'nextSession':
      return [
        ...(allowNewSession
          ? [{ value: 'again', label: 'Bắt đầu phiên mới', echo: 'Bắt đầu phiên mới.' }]
          : []),
        { value: 'stop', label: 'Dừng ở đây', echo: 'Dừng ở đây.' },
      ];
    default:
      // pickNew / pickHabit / quizInChat — chip duy nhất mà chữ là DỮ LIỆU.
      return choices.map((choice) => ({
        value: choice.value,
        label: choice.label ?? choice.value,
      }));
  }
}

/** Nhãn chip ở bộ điều phối (HUB / TALK_ASK) — server gửi giá trị, chữ là của app. */
export const HUB_TASK_LABELS: Record<string, string> = {
  T1: 'Xem lại nhắc hẹn',
  T2: 'Luyện tập tình huống',
  T3: 'Kể chuyện hôm nay',
  T4: 'Đặt Nhắc hẹn',
  checkin: 'Ghi nhận hôm nay',
  quiz: 'Làm quiz với mình',
  summary: 'Bàn luận về bài vừa học',
  talkQuiz: 'Làm quiz',
};

export const MOOD_LABELS = ['Tệ', 'Hơi mệt', 'Bình thường', 'Ổn', 'Tốt'];

export const PERSONA_LABELS: Record<string, string> = {
  friend: 'Người bạn',
  direct: 'Người thẳng',
  guide: 'Người dẫn',
};

export const DAY_LABELS = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

/** Câu níu khi bấm Đóng giữa phiên, theo chỗ người đọc đang đứng. */
export function exitPleaLine(step: string, quizRemaining?: number): string {
  const story = ['story', 'storyTalk', 'depth', 'checkinTell', 'tell', 'tell2'];
  const scene = ['tellOnce', 'sceneRetry', 'sceneFix', 'sceneStage2', 'sceneMet', 'sceneDid', 'sceneChange'];
  if (story.includes(step)) return 'Bạn kể chưa hết mà. Ở thêm một câu nữa nhé?';
  if (scene.includes(step)) return 'Cảnh này còn một câu nữa là xong. Nói thử rồi mình đóng?';
  if (step === 'quizInChat') {
    return `Còn ${quizRemaining ?? 2} câu thôi. Làm nốt rồi mình ghi hôm nay cho bạn nhé?`;
  }
  return 'Mình vẫn ở đây mà. Nói thêm một câu rồi đóng cũng được?';
}

/** Bộ chip đánh giá theo LOẠI việc lúc đóng — loại do server gửi, client không tự đoán. */
export function ratingChipsFor(kind?: string): [string, string][] {
  switch (kind) {
    case 'scene':
      return [
        ['scene_realistic', 'Tình huống giống đời thật'],
        ['scene_useful', 'Gợi ý trả lời dùng được'],
        ['scene_unrealistic', 'Tình huống không giống đời mình'],
        ['scene_unnatural', 'Câu gợi ý nghe không tự nhiên'],
        ['not_helpful', 'Chưa giúp được gì'],
      ];
    case 'recap':
      return [
        ['recap_accurate', 'Tóm đúng ý mình'],
        ['recap_on_point', 'Câu hỏi ôn đúng trọng tâm'],
        ['recap_wrong', 'Tóm sai hoặc thiếu ý'],
        ['recap_bad_level', 'Câu hỏi quá dễ hoặc quá khó'],
        ['not_helpful', 'Chưa giúp được gì'],
      ];
    case 'onboard':
      return [
        ['onboard_easy', 'Câu hỏi dễ trả lời'],
        ['too_many_questions', 'Hỏi quá nhiều'],
        ['onboard_too_personal', 'Hỏi riêng tư quá'],
        ['onboard_unclear', 'Chưa hiểu Coach để làm gì'],
      ];
    case 'hub':
      return [
        ['hub_unsure', 'Không biết chọn gì'],
        ['hub_nothing_fits', 'Không có mục nào hợp'],
        ['hub_just_looking', 'Chỉ ghé xem thử'],
        ['hub_busy', 'Đang bận, để sau'],
      ];
    default:
      return [
        ['understood_me', 'Coach hiểu đúng chuyện mình kể'],
        ['right_questions', 'Câu hỏi đúng chỗ'],
        ['too_long', 'Nói nhiều quá'],
        ['imposed_thinking', 'Áp đặt suy nghĩ của mình'],
        ['not_helpful', 'Chưa giúp được gì'],
      ];
  }
}
