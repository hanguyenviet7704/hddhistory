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
/// Never the model's words.
///
/// An unknown key returns null and the sheet simply prints nothing — a missing
/// navigation line is a quieter failure than a raw key on screen.
String? coachPrompt(BuildContext context, String key, [Map<String, String> args = const {}]) {
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

    // -- the 5 beats
    case 'coach.prompt.story':
      return l10n.promptStory;
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
      return time.isEmpty
          ? l10n.closingWithPlanNoTime(context: args['context'] ?? '')
          : l10n.closingWithPlan(context: args['context'] ?? '', time: time);
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
    case 'coach.course.reasonSkillset':
      return l10n.courseReasonSkillset;
    case 'coach.course.reasonSaved':
      return l10n.courseReasonSaved;
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
