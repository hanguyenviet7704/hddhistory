part of '../../coach.dart';

/// Turns a server prompt key into the sentence for this reader's language.
///
/// An explicit switch rather than slang's `flat_map`, on purpose. Dynamic key
/// lookup would make every one of these strings resolvable only at runtime, so
/// a key the server started sending that the app never added would surface as a
/// blank line in front of somebody mid-conversation. Here it is a hole you can
/// see in this file.
///
/// An unknown key returns null and the sheet simply prints nothing — a missing
/// navigation line is a quieter failure than a raw key on screen.
String? coachPrompt(BuildContext context, String key) {
  final l10n = context.l10n.coach;

  switch (key) {
    case 'coach.prompt.mood':
      return l10n.promptMood;
    case 'coach.prompt.moodEnd':
      return l10n.promptMoodEnd;
    case 'coach.prompt.pickNew':
      return l10n.promptPickNew;
    case 'coach.prompt.pickHabit':
      return l10n.promptPickHabit;
    case 'coach.prompt.persona':
      return l10n.promptPersona;
    case 'coach.prompt.time':
      return l10n.promptTime;
    // Nhịp 1 of the ② scripts, and ③C's opening. Both steps arrive before
    // anybody has said anything, so there is no reply to render and no scene —
    // without these two the reader met an empty composer and the script they
    // had just chosen never announced itself.
    case 'coach.prompt.tell':
      return l10n.promptTell;
    // What nhịp 2 falls back to when the guard rejected the model's question
    // twice. Asking about the next event is the one shape never banned.
    case 'coach.prompt.tellFollowUp':
      return l10n.promptTellFollowUp;
    case 'coach.prompt.free':
      return l10n.promptFree;
    case 'coach.prompt.intentTell':
      return l10n.promptIntentTell;
    case 'coach.prompt.nextAction':
      return l10n.promptNextAction;
    case 'coach.prompt.checkin':
      return l10n.promptCheckin;
    case 'coach.prompt.plan':
      return l10n.promptPlan;
    case 'coach.prompt.schedule':
      return l10n.promptSchedule;
    case 'coach.prompt.loop':
      return l10n.promptLoop;
    case 'coach.prompt.rating':
      return l10n.promptRating;
    case 'coach.prompt.end':
      return l10n.promptEnd;
    case 'coach.prompt.jot':
      return l10n.promptJot;
    case 'coach.prompt.safety':
      return l10n.promptSafety;
    case 'coach.prompt.twoCols':
      return l10n.promptTwoCols;
    case 'coach.prompt.redraft':
      return l10n.redraftPrompt;
    case 'coach.prompt.intent':
      return l10n.promptIntent;
    case 'coach.fallback.reply':
      return l10n.fallbackReply;
    default:
      return null;
  }
}

/// The second line of the sheet header.
///
/// The design draws a two-line header and fills the lower line with its own
/// step ids — "③A hỏi lại nhắc hẹn", "⑥ lối thoát 20 giây". Those are
/// instrumentation for whoever is reading the drawing: shipping them would put
/// internal numbering in front of somebody mid-conversation. The slot keeps its
/// shape; the words are the ones a person can actually read.
///
/// Returns null where the header is better with one line — the closing choices
/// and ⑧, both of which already say what they are.
String? coachStepLabel(BuildContext context, String step) {
  final l10n = context.l10n.coach;

  switch (step) {
    case 'mood':
      return l10n.stepMood;
    case 'pickNew':
    case 'pickHabit':
      return l10n.stepPickHabit;
    case 'persona':
      return l10n.stepPersona;
    case 'time':
      return l10n.stepTime;
    case 'tell':
    case 'tell2':
    case 'free':
      return l10n.stepTelling;
    case 'twoCols':
      return l10n.stepTwoCols;
    case 'tellOnce':
    case 'tellOnceA':
    case 'tellOnceB':
    case 'practiceAnswer':
      return l10n.stepSituation;
    case 'intent':
    case 'intentTell':
      return l10n.stepIntent;
    case 'checkin':
      return l10n.stepCheckin;
    case 'plan':
      return l10n.stepPlan;
    case 'schedule':
      return l10n.stepSchedule;
    case 'loop':
      return l10n.stepLoop;
    case 'moodEnd':
      return l10n.stepMoodEnd;
    case 'rating':
      return l10n.stepRating;
    case 'jot':
      return l10n.stepJot;
    case 'nextAction':
      return l10n.stepNextAction;
    case 'closing':
      return l10n.stepClosing;
    case 'redraft':
      return l10n.stepRedraft;
    default:
      return null;
  }
}
