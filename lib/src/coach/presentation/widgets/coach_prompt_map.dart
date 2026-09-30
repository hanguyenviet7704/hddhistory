part of '../../coach.dart';

/// Turns a server prompt key into the sentence for this reader's language.
///
/// An explicit switch rather than slang's `flat_map`, on purpose. Dynamic key
/// lookup would make every one of these strings resolvable only at runtime, so
/// a key the server started sending that the app never added would surface as a
/// blank line in front of somebody mid-conversation. Here it is a hole you can
/// see in this file.
///
/// [args] are the reader's own words the line quotes — the commitment at the
/// check-in, the habit just added, the reminder time in the closing line.
/// Never the model's words, with ONE exception: `topic` in
/// `coach.prompt.hubBack` is a phrase the Coach wrote (≤80 chars, written when
/// the previous session ended). It is allowed in because the alternative — a
/// whole greeting generated as `reply` — costs the opening question: `reply`
/// and `promptKey` never both arrive, so a generated greeting REPLACES the
/// fixed line, and a model that forgets to ask leaves the reader in front of a
/// hello with nothing to answer. The server only sends it when it was written
/// in the language now on screen, and it is protected from the address rewriter
/// below like any other content span.
///
/// An unknown key returns null and the sheet simply prints nothing — a missing
/// navigation line is a quieter failure than a raw key on screen.
String? coachPrompt(BuildContext context, String key, [Map<String, String> args = const {}]) {
  final line = _coachPromptLine(context, key, args);
  if (line == null) return null;

  // The reader's address, as the server sends it on every turn once known:
  // Vietnamese fixed lines are written to "bạn" and follow it here — the one
  // fix for "lúc thì anh lúc thì bạn" (owner, 2026-09-04).
  // Both shapes the habit title can appear in: quoted as authored
  // (`lessonIntro`) and lower-cased inside a sentence (`checkinAsk`).
  return LocaleSettings.currentLocale.languageCode == 'vi'
      // `topic` rides along in `protect` for the same reason the habit title
      // does: it is CONTENT, and rewriting a "bạn" inside it would put the
      // reader's own name in the middle of the sentence they told the Coach.
      ? _addressVi(
          line,
          args['address'],
          protect: {args['habit'] ?? '', _habitInline(args), args['topic'] ?? ''},
        )
      : line;
}

String? _coachPromptLine(BuildContext context, String key, Map<String, String> args) {
  final l10n = context.l10n.coach;

  switch (key) {
    // -- mood, both ends of the session
    case 'coach.prompt.mood':
      return l10n.promptMood;
    case 'coach.prompt.moodEnd':
      return l10n.promptMoodEnd;
    case 'coach.prompt.pickNew':
      return l10n.promptPickNew;

    // -- ②A check-in: the reader's own commitment quoted back, then one sentence
    case 'coach.prompt.intent':
      return l10n.promptIntent(
        context: args['context'] ?? '',
        action: args['action'] ?? '',
      );
    case 'coach.prompt.intentTell':
      return l10n.promptIntentTell;
    case 'coach.prompt.barrier':
      return l10n.promptBarrier;
    case 'coach.prompt.intentNone':
      return l10n.intentNoneNote;
    case 'coach.prompt.intentTellDone':
      return l10n.intentTellDone;
    case 'coach.prompt.intentTellMissed':
      return l10n.intentTellMissed;
    case 'coach.prompt.planSlept':
      return l10n.planSlept;
    case 'coach.prompt.loop':
      return l10n.promptLoop;
    // ②A after "có dịp mà chưa làm": the offer to make the commitment smaller,
    // then the form pre-filled with the old wording, then the fact it replaced.
    case 'coach.prompt.shrinkAsk':
      return l10n.promptShrinkAsk;
    case 'coach.prompt.shrinkEdit':
      return l10n.promptShrinkEdit;
    case 'coach.prompt.shrinkDone':
      return l10n.shrinkDoneNote;

    // -- the replay's divider between sessions: "Hôm qua · Trang chủ"
    case 'coach.divider':
      return _dividerLabel(l10n, args);

    // -- luồng 1: the onboarding. An empty `address` means the neutral wording
    // (a non-Vietnamese reader who kept "bạn").
    case 'coach.prompt.onboardAddress':
      return l10n.promptOnboardAddress;
    case 'coach.prompt.onboardAddressConfirm':
      return l10n.promptOnboardAddressConfirm(name: args['name'] ?? '');
    case 'coach.prompt.onboardGoal':
      return _addressed(args) ? l10n.promptOnboardGoalTo(address: _addressFor('promptOnboardGoal', args['address']!)) : l10n.promptOnboardGoal;
    case 'coach.prompt.onboardBarrier':
      return _addressed(args) ? l10n.promptOnboardBarrierTo(address: _addressFor('promptOnboardBarrier', args['address']!)) : l10n.promptOnboardBarrier;
    case 'coach.prompt.onboardCurrent':
      return _addressed(args) ? l10n.promptOnboardCurrentTo(address: _addressFor('promptOnboardCurrent', args['address']!)) : l10n.promptOnboardCurrent;
    case 'coach.prompt.onboardStyle':
      return _addressed(args) ? l10n.promptOnboardStyleTo(address: _addressFor('promptOnboardStyle', args['address']!)) : l10n.promptOnboardStyle;
    case 'coach.prompt.onboardAge':
      return _addressed(args) ? l10n.promptOnboardAgeTo(address: _addressFor('promptOnboardAge', args['address']!)) : l10n.promptOnboardAge;
    case 'coach.prompt.onboardGender':
      return _addressed(args) ? l10n.promptOnboardGenderTo(address: _addressFor('promptOnboardGender', args['address']!)) : l10n.promptOnboardGender;
    case 'coach.prompt.onboardJob':
      return _addressed(args) ? l10n.promptOnboardJobTo(address: _addressFor('promptOnboardJob', args['address']!)) : l10n.promptOnboardJob;

    // -- the 5 beats
    case 'coach.prompt.story':
      return l10n.promptStory;
    // Home · "Kể chuyện hôm nay" — the one open question, nothing to tap.
    case 'coach.prompt.storyOpen':
      return l10n.promptStoryOpen;
    case 'coach.prompt.storyMore':
      return l10n.promptStoryMore;
    // Nhịp 2's question when the model could not write one.
    case 'coach.prompt.tellFollowUp':
      return l10n.promptTellFollowUp;
    case 'coach.prompt.twoCols':
      return l10n.promptTwoCols;
    // ⑤ — "Mình hiểu sai rồi. Vậy bạn kể lại giúp mình…"
    case 'coach.prompt.redraft':
      return l10n.redraftPrompt;
    // After the sentence: "Đó là câu của bạn, mình không sửa." — no model call.
    case 'coach.prompt.problemAck':
      return l10n.problemAck;
    case 'coach.prompt.invite':
      return l10n.promptInvite;
    // ① names the habit in one bubble, then opens the scene bubble with a lead.
    case 'coach.prompt.lessonIntro':
      return l10n.lessonIntro(habit: args['habit'] ?? '');
    case 'coach.prompt.sceneLead':
      return l10n.sceneLead;
    // After the scene, when the model could not reply.
    case 'coach.prompt.sceneAck':
      return l10n.sceneAck;
    // T4 — "Mình ghi lại rồi nhé.", said on the way to the commitment question.
    case 'coach.prompt.jotAck':
      return l10n.promptJotAck;
    // Nhịp 4 of the scene, and the line that closes it when nhịp 5 is skipped.
    case 'coach.prompt.sceneAgain':
      return l10n.promptSceneAgain;
    case 'coach.prompt.sceneDone':
      return l10n.promptSceneDone;
    // ②C keeps nothing, so it does not say "ghi lại rồi nhé".
    case 'coach.prompt.closingHeard':
      return l10n.promptClosingHeard;
    // The scene's opening beat — the feeling first, the question after.
    case 'coach.prompt.sceneFeeling':
      return l10n.promptSceneFeeling;
    case 'coach.prompt.sceneFeelingThird':
      return l10n.promptSceneFeelingThird;
    case 'coach.prompt.sceneFeelingAck':
      return l10n.sceneFeelingAck;
    // Bộ điều phối, and the scene's last two beats.
    case 'coach.prompt.hub':
      return l10n.promptHub;
    // Câu mở phiên Home NHẮC LẠI chuyện hôm trước. Khung câu là chữ cố định ở
    // đây; chỉ `topic` là chữ Coach viết (một mảnh ≤80 ký tự, viết từ lúc phiên
    // trước kết). Không có mảnh nào thì server gửi `coach.prompt.hub` như cũ.
    case 'coach.prompt.hubBack':
      return l10n.promptHubBack(topic: args['topic'] ?? '');
    // The coordinator is ②'s opening step as well as the seam between tasks;
    // "Xong rồi…" reads as a goodbye before anything has happened.
    // Luồng 2/3 — the talk after a keypoint, the course recap.
    case 'coach.prompt.talkAsk':
      return l10n.promptTalkAsk;
    case 'coach.prompt.quizHandoff':
      return l10n.promptQuizHandoff;
    case 'coach.prompt.talkWhen':
      return l10n.promptTalkWhen;
    case 'coach.prompt.recapPick':
      return l10n.promptRecapPick(course: args['course'] ?? '');
    case 'coach.prompt.recapQuiz':
      return l10n.promptRecapQuiz;
    // Luồng 5 — the Habit screen.
    // Luồng 5 — the check-in names the habit it is asking about. Titles are
    // verb phrases ("nghỉ đúng lúc trước khi cạn sức"), so they read as part of
    // the question rather than as a quoted object; the fallback covers a title
    // the server could not resolve, where "nó" would have nothing to point at.
    case 'coach.prompt.checkinAsk':
      final habit = _habitInline(args);

      return habit.isEmpty ? l10n.promptCheckinAskNoName : l10n.promptCheckinAsk(habit: habit);
    case 'coach.prompt.checkinTell':
      return l10n.promptCheckinTell;
    // Luồng 4 — the Home scene.
    case 'coach.prompt.scenePick':
      return l10n.promptScenePick;
    case 'coach.prompt.sceneRetry':
      return l10n.promptSceneRetry;
    case 'coach.prompt.hubOpen':
      return l10n.hubOpen;
    case 'coach.prompt.sceneMet':
      return l10n.promptSceneMet;
    case 'coach.prompt.sceneWhen':
      return l10n.promptSceneWhen;
    // 6b · 6d — the real occurrence, and the change question.
    case 'coach.prompt.sceneDid':
      return l10n.promptSceneDid;
    case 'coach.prompt.sceneChange':
      return l10n.promptSceneChange;
    // ④ — the scene from three weeks ago.
    case 'coach.prompt.retryScene':
      return l10n.retryScene;
    case 'coach.prompt.retryAck':
      return l10n.retryAck;

    // -- nhịp 5: the commitment and the tail
    // Mood-chosen openers — the server picks the level and the day's variant.
    case 'coach.prompt.storyOpenBad1':
      return l10n.storyOpenBad1;
    case 'coach.prompt.storyOpenBad2':
      return l10n.storyOpenBad2;
    case 'coach.prompt.storyOpenBad3':
      return l10n.storyOpenBad3;
    case 'coach.prompt.storyOpenTired1':
      return l10n.storyOpenTired1;
    case 'coach.prompt.storyOpenTired2':
      return l10n.storyOpenTired2;
    case 'coach.prompt.storyOpenTired3':
      return l10n.storyOpenTired3;
    case 'coach.prompt.storyOpenOk1':
      return l10n.storyOpenOk1;
    case 'coach.prompt.storyOpenOk2':
      return l10n.storyOpenOk2;
    case 'coach.prompt.storyOpenOk3':
      return l10n.storyOpenOk3;
    case 'coach.prompt.storyOpenGood1':
      return l10n.storyOpenGood1;
    case 'coach.prompt.storyOpenGood2':
      return l10n.storyOpenGood2;
    case 'coach.prompt.storyOpenGood3':
      return l10n.storyOpenGood3;
    case 'coach.prompt.storyOpenGreat1':
      return l10n.storyOpenGreat1;
    case 'coach.prompt.storyOpenGreat2':
      return l10n.storyOpenGreat2;
    case 'coach.prompt.storyOpenGreat3':
      return l10n.storyOpenGreat3;
    case 'coach.scene.habitLabel':
      return l10n.sceneHabitLabel;
    case 'coach.scene.setupLabel':
      return l10n.sceneSetupLabel;
    case 'coach.prompt.sceneScore':
      return l10n.promptSceneScore;
    case 'coach.prompt.planAsk':
      return l10n.promptPlanAsk;
    case 'coach.prompt.plan':
      return l10n.promptPlan;
    case 'coach.prompt.schedule':
      return l10n.promptSchedule;
    case 'coach.prompt.courseCard':
      return l10n.promptCourseCard;
    case 'coach.prompt.courseLeave':
      return l10n.promptCourseLeave;
    case 'coach.prompt.rating':
      return l10n.promptRating;
    // The closing line when the model could not write one — still the reader's
    // words, still not a question.
    case 'coach.prompt.closingWithPlan':
      final time = args['time'] ?? '';
      return time.isEmpty ? l10n.closingWithPlanNoTime(context: args['context'] ?? '') : l10n.closingWithPlan(context: args['context'] ?? '', time: time);
    case 'coach.prompt.closingNoPlan':
      return l10n.closingNoPlan;
    // ① closes on this; ② on "Vậy mình dừng ở đây nhé."
    case 'coach.prompt.endLesson':
      return l10n.promptEndLesson;
    case 'coach.prompt.endStop':
      return l10n.promptEndStop;
    case 'coach.prompt.safety':
      return l10n.promptSafety;
    case 'coach.fallback.reply':
      return l10n.fallbackReply;

    // -- retired steps — a session parked on one still renders its line
    case 'coach.prompt.depth':
      return l10n.promptDepth;
    case 'coach.prompt.contextAsk':
      return l10n.promptContextAsk(context: args['context'] ?? '');
    case 'coach.prompt.contextEdit':
      return l10n.promptContextEdit;
    case 'coach.prompt.nextAction':
      return l10n.promptNextAction;
    case 'coach.prompt.jot':
      return l10n.promptJot;
    case 'coach.prompt.pickHabit':
      return l10n.promptPickHabit;
    case 'coach.prompt.persona':
      return l10n.promptPersona;
    case 'coach.prompt.time':
      return l10n.promptTime;
    case 'coach.prompt.tell':
      return l10n.promptTell;
    case 'coach.prompt.free':
      return l10n.promptFree;
    case 'coach.prompt.checkin':
      return l10n.promptCheckin;
    case 'coach.prompt.end':
      return l10n.promptEnd;
    default:
      return null;
  }
}

/// The bubble's fixed teaser, by key. ②A quotes the reader's own commitment
/// and needs none of this; ④ has no words of theirs yet.
String? coachTeaser(BuildContext context, String? key) {
  switch (key) {
    case 'coach.teaser.retry':
      return context.l10n.coach.teaserRetry;
    // Luồng 5 — the Habit screen with nothing in the kho yet.
    case 'coach.teaser.firstHabit':
      return context.l10n.coach.teaserFirstHabit;
    // Luồng 5 — the Habit screen with a kho: the two things it can do.
    case 'coach.teaser.habit':
      return context.l10n.coach.teaserHabit;
    // Home — one line, and before the onboarding has run, its own.
    case 'coach.teaser.home':
      return context.l10n.coach.teaserHome;
    case 'coach.teaser.onboard':
      return context.l10n.coach.teaserOnboard;
    default:
      return null;
  }
}

/// Why the course card shows THIS course — a fact about the reader, from the
/// server as a key. Null for a card that came with no reason (an older API).
String? coachCourseReason(BuildContext context, String? key, [Map<String, String> args = const {}]) {
  final l10n = context.l10n.coach;

  switch (key) {
    // Ưu tiên 1 — "Ý mình vừa nói nằm trong khoá này."
    // The card's one reason (doc v4): a habit they do not have yet.
    case 'coach.course.reasonOutside':
      return l10n.courseReasonOutside;
    case 'coach.course.reasonKeypoint':
      return l10n.courseReasonKeypoint;
    case 'coach.course.reasonBarrier':
      return l10n.courseReasonBarrier(habit: args['habit'] ?? '');
    case 'coach.course.reasonHabit':
      return l10n.courseReasonHabit(habit: args['habit'] ?? '');
    case 'coach.course.reasonStory':
      return l10n.courseReasonStory;
    case 'coach.course.reasonRecap':
      return l10n.courseReasonRecap;
    case 'coach.course.reasonSkillset':
      return l10n.courseReasonSkillset;
    case 'coach.course.reasonSaved':
      return l10n.courseReasonSaved;
    // Ưu tiên cuối — chuyện vừa kể không khớp habit nào, nên card là khoá
    // chính họ đang học dở. Không phải một gợi ý, mà là việc họ đang làm.
    case 'coach.course.reasonResume':
      return l10n.courseReasonResume;
    default:
      return null;
  }
}

/// The second line of the sheet header — which moment of the conversation
/// this is, in the design's own words ("mood đầu ngày · 5 mức, 1 chạm").
String? coachStepLabel(BuildContext context, String step) {
  final l10n = context.l10n.coach;

  switch (step) {
    case 'mood':
      return l10n.stepMood;
    case 'pickNew':
    case 'pickHabit':
      return l10n.stepPickHabit;
    case 'intent':
      return l10n.stepIntent;
    case 'intentTell':
    case 'barrier':
      return l10n.stepIntentTell;
    case 'shrinkAsk':
    case 'shrink':
      return l10n.stepShrinkAsk;
    case 'loop':
      return l10n.stepLoop;
    case 'story':
      return l10n.stepStory;
    case 'tell':
    case 'tell2':
    case 'free':
    case 'depth':
      return l10n.stepTelling;
    case 'sceneFeeling':
    case 'sceneStage2':
    case 'sceneMet':
    case 'sceneWhen':
    case 'sceneDid':
    case 'sceneChange':
      return l10n.stepSituation;
    case 'hub':
      return l10n.stepHub;
    // Luồng 4 — the Home scene.
    case 'scenePick':
      return l10n.stepScenePick;
    case 'sceneFix':
    case 'sceneRetry':
      return l10n.stepSituation;
    // Luồng 5 — the Habit screen.
    case 'checkinAsk':
    case 'checkinTell':
    case 'checkinOffer':
      return l10n.stepCheckinToday;
    case 'quizInChat':
      return l10n.stepQuiz;
    // Luồng 2/3.
    case 'talkAsk':
    case 'talkSummary':
    case 'talkFree':
    case 'quizHandoff':
    case 'quizRun':
    case 'talkWhen':
      return l10n.stepTalk;
    case 'recapPick':
    case 'recapQuiz':
      return l10n.stepRecap;
    case 'twoCols':
    case 'redraft':
      return l10n.stepTwoCols;
    case 'invite':
      return l10n.stepInvite;
    case 'tellOnce':
    case 'tellOnceA':
    case 'tellOnceB':
    case 'practiceAnswer':
      return l10n.stepSituation;
    case 'retryScene':
      return l10n.stepRetry;
    case 'sceneScore':
      return l10n.stepSceneScore;
    case 'planAsk':
      return l10n.stepPlanAsk;
    case 'plan':
      return l10n.stepPlan;
    case 'schedule':
      return l10n.stepSchedule;
    case 'courseCard':
      return l10n.stepCourse;
    case 'leave':
      return l10n.stepLeave;
    case 'moodEnd':
      return l10n.stepMoodEnd;
    case 'rating':
      return l10n.stepRating;
    case 'nextSession':
      return l10n.stepNextSession;
    case 'end':
      return l10n.stepEnd;
    case 'safety':
      return l10n.stepSafety;
    case 'jot':
      return l10n.stepJot;
    case 'nextAction':
    case 'closing':
    case 'contextAsk':
    case 'contextEdit':
    case 'persona':
    case 'time':
    case 'checkin':
      return l10n.stepTelling;
    default:
      return null;
  }
}

/// Luồng 1 — whether the server sent an address worth writing into the line.
bool _addressed(Map<String, String> args) => args['address']?.trim().isNotEmpty ?? false;

/// The habit's title as it goes INSIDE a sentence.
///
/// vi/en drop its leading capital so it reads as a phrase in the middle of the
/// question ("có dịp nào nghỉ đúng lúc…" rather than "…nào Nghỉ đúng lúc…");
/// zh/ja/ko quote it in their frame instead and have no case to change.
String _habitInline(Map<String, String> args) {
  final habit = (args['habit'] ?? '').trim();
  if (habit.isEmpty) return '';
  final language = LocaleSettings.currentLocale.languageCode;
  if (language != 'vi' && language != 'en') return habit;

  return habit[0].toLowerCase() + habit.substring(1);
}

/// The Vietnamese lines put the pronoun at the head of some sentences and inside
/// others, and only a pronoun changes case — a name is written as typed. The
/// server sends it lowercase; which questions open with it is this list.
const _leadingInVi = {'promptOnboardGoal', 'promptOnboardStyle', 'promptOnboardAge', 'promptOnboardJob'};
const _pronouns = {'bạn', 'anh', 'chị', 'em'};

String _addressFor(String key, String address) {
  final word = address.trim();
  if (!_pronouns.contains(word)) return word;
  if (LocaleSettings.currentLocale.languageCode != 'vi' || !_leadingInVi.contains(key)) return word;

  return word[0].toUpperCase() + word.substring(1);
}

/// "Hôm nay · Trang chủ" / "Hôm qua · Bài học" / "12 thg 8 · Thói quen" — the
/// day the session happened and the door it was opened from.
String _dividerLabel(dynamic l10n, Map<String, String> args) {
  final door = switch (args['entry']) {
    'lesson' => l10n.doorLesson as String,
    'habit' => l10n.doorHabit as String,
    _ => l10n.doorHome as String,
  };
  final at = DateTime.tryParse(args['at'] ?? '')?.toLocal();
  if (at == null) return door;

  final now = DateTime.now();
  final days = DateTime(now.year, now.month, now.day).difference(DateTime(at.year, at.month, at.day)).inDays;
  final when = days <= 0
      ? l10n.dividerToday as String
      : days == 1
      ? l10n.dividerYesterday as String
      : DateFormat.MMMd(LocaleSettings.currentLocale.languageCode).format(at);

  return '$when · $door';
}

/// "bạn" → «anh» / «chị» / «em» / a name — the second person only, never the
/// noun ("bạn bè", "người bạn", "bạn thân"). Mirrors the server's `addressVi`.
String _addressVi(String text, String? address, {Iterable<String> protect = const []}) {
  final to = address?.trim() ?? '';
  if (text.isEmpty || to.isEmpty || to == 'bạn') return text;
  final cap = to[0].toUpperCase() + to.substring(1);

  // Spans that came from CONTENT rather than from the fixed line — today just
  // the habit title. The library writes titles to the reader too ("Ôn lại một
  // điều bạn đã học hôm qua"), and rewriting THAT "bạn" produced "…một điều Hà
  // đã học hôm qua", the reader's name inside their own habit's name. Every
  // line carrying ${habit} had this; it only became visible once the check-in
  // question started naming the habit.
  final keep = <List<int>>[];
  for (final candidate in protect) {
    final needle = candidate.trim();
    if (needle.isEmpty) continue;
    for (var at = text.indexOf(needle); at != -1; at = text.indexOf(needle, at + needle.length)) {
      keep.add([at, at + needle.length]);
    }
  }
  bool isContent(int index) => keep.any((range) => index >= range[0] && index < range[1]);
  final nounAfter = RegExp(r'^\s+(bè|thân|trai|gái|cùng|học|đồng|đời|cũ|mới)(?![\p{L}])', unicode: true);
  final nounBefore = RegExp(r'(người|cô|anh|chị|ông|bà|thằng|đứa|tụi|các|nhóm|mấy|những|đám|bọn)\s*$', unicode: true);

  return text.replaceAllMapped(RegExp(r'(^|[^\p{L}])([Bb])ạn(?![\p{L}])', unicode: true), (m) {
    final pre = m.group(1)!;
    final after = text.substring(m.end);
    final before = text.substring(0, m.start + pre.length);
    if (isContent(m.start + pre.length)) return m.group(0)!;
    if (nounAfter.hasMatch(after) || nounBefore.hasMatch(before)) return m.group(0)!;

    return pre + (m.group(2) == 'B' ? cap : to);
  });
}
