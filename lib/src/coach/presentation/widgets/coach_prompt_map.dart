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
/// check-in, its context, the reminder time in the closing line. Never the
/// model's words.
///
/// An unknown key returns null and the sheet simply prints nothing — a missing
/// navigation line is a quieter failure than a raw key on screen.
String? coachPrompt(BuildContext context, String key, [Map<String, String> args = const {}]) {
  final l10n = context.l10n.coach;

  switch (key) {
    case 'coach.prompt.mood':
      return l10n.promptMood;
    case 'coach.prompt.moodEnd':
      return l10n.promptMoodEnd;
    case 'coach.prompt.pickNew':
      return l10n.promptPickNew;
    // ② — the door's one opening line.
    case 'coach.prompt.story':
      return l10n.promptStory;
    // After the first line: two equal chips.
    case 'coach.prompt.depth':
      return l10n.promptDepth;
    // ②A opens by quoting the reader's own commitment back at them.
    case 'coach.prompt.intent':
      return l10n.promptIntent(
        context: args['context'] ?? '',
        action: args['action'] ?? '',
      );
    case 'coach.prompt.intentTell':
      return l10n.promptIntentTell;
    case 'coach.prompt.barrier':
      return l10n.promptBarrier;
    case 'coach.prompt.contextAsk':
      return l10n.promptContextAsk(context: args['context'] ?? '');
    case 'coach.prompt.contextEdit':
      return l10n.promptContextEdit;
    case 'coach.prompt.planSlept':
      return l10n.planSlept;
    case 'coach.prompt.invite':
      return l10n.promptInvite;
    case 'coach.prompt.planAsk':
      return l10n.promptPlanAsk;
    case 'coach.prompt.plan':
      return l10n.promptPlan;
    case 'coach.prompt.schedule':
      return l10n.promptSchedule;
    case 'coach.prompt.loop':
      return l10n.promptLoop;
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
    // ① closes on this and nothing else.
    case 'coach.prompt.endLesson':
      return l10n.promptEndLesson;
    case 'coach.prompt.jot':
      return l10n.promptJot;
    case 'coach.prompt.safety':
      return l10n.promptSafety;
    case 'coach.prompt.twoCols':
      return l10n.promptTwoCols;
    case 'coach.prompt.redraft':
      return l10n.redraftPrompt;
    case 'coach.prompt.nextAction':
      return l10n.promptNextAction;
    // What nhịp 2 falls back to when the guard rejected the model's question
    // twice. Asking about the next event is the one shape never banned.
    case 'coach.prompt.tellFollowUp':
      return l10n.promptTellFollowUp;
    case 'coach.fallback.reply':
      return l10n.fallbackReply;
    // Retired steps — a session parked on one still renders its line.
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

/// The second line of the sheet header.
///
/// The design draws a two-line header and fills the lower line with its own
/// step ids. Those are instrumentation for whoever is reading the drawing;
/// shipping them would put internal numbering in front of somebody
/// mid-conversation. The slot keeps its shape; the words are ones a person can
/// actually read.
String? coachStepLabel(BuildContext context, String step) {
  final l10n = context.l10n.coach;

  switch (step) {
    case 'mood':
      return l10n.stepMood;
    case 'pickNew':
    case 'pickHabit':
      return l10n.stepPickHabit;
    case 'story':
      return l10n.stepStory;
    case 'depth':
      return l10n.stepDepth;
    case 'tell':
    case 'tell2':
    case 'free':
      return l10n.stepTelling;
    case 'twoCols':
      return l10n.stepTwoCols;
    case 'redraft':
      return l10n.stepRedraft;
    case 'nextAction':
      return l10n.stepNextAction;
    case 'closing':
      return l10n.stepClosing;
    case 'invite':
    case 'tellOnce':
    case 'tellOnceA':
    case 'tellOnceB':
    case 'practiceAnswer':
      return l10n.stepSituation;
    case 'intent':
    case 'intentTell':
      return l10n.stepIntent;
    case 'barrier':
      return l10n.stepBarrier;
    case 'shrink':
      return l10n.stepShrink;
    case 'contextAsk':
    case 'contextEdit':
      return l10n.stepContext;
    case 'planAsk':
    case 'plan':
      return l10n.stepPlan;
    case 'schedule':
      return l10n.stepSchedule;
    case 'loop':
      return l10n.stepLoop;
    case 'courseCard':
      return l10n.stepCourse;
    case 'moodEnd':
      return l10n.stepMoodEnd;
    case 'rating':
      return l10n.stepRating;
    case 'nextSession':
      return l10n.stepNextSession;
    case 'jot':
      return l10n.stepJot;
    case 'persona':
      return l10n.stepPersona;
    case 'time':
      return l10n.stepTime;
    case 'checkin':
      return l10n.stepCheckin;
    default:
      return null;
  }
}
