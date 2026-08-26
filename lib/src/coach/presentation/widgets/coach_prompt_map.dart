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
    // ④ — the scene from three weeks ago.
    case 'coach.prompt.retryScene':
      return l10n.retryScene;
    case 'coach.prompt.retryAck':
      return l10n.retryAck;

    // -- nhịp 5: the commitment and the tail
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
    case 'loop':
      return l10n.stepLoop;
    case 'story':
      return l10n.stepStory;
    case 'tell':
    case 'tell2':
    case 'free':
    case 'depth':
      return l10n.stepTelling;
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
    case 'shrink':
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
