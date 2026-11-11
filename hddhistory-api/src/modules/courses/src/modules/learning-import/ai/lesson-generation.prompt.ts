import {
  LessonContinuationInput,
  LessonGenerationInput,
} from './lesson-generation.types';
import { stripHtml } from '../audio/user-lesson-narration.util';
import { LessonBlockType } from '../enum/learning-import.enum';
import { ILessonKeypoint } from '../interface/learning-import.interface';

// Locale code -> the language name we put in the prompt. Naming the language
// beats passing a bare code: models follow "write in Vietnamese" far more
// reliably than "write in vi", and a code we don't recognise falls back to
// English rather than producing a lesson in whatever the source happened to be.
const LANGUAGE_NAMES: Record<string, string> = {
  en: 'English',
  vi: 'Vietnamese',
  zh: 'Chinese (Simplified)',
  ja: 'Japanese',
  ko: 'Korean',
};

export function languageName(locale: string): string {
  return LANGUAGE_NAMES[locale] ?? LANGUAGE_NAMES.en;
}

/**
 * One keypoint, as both phases must return it.
 *
 * Expressed in the OpenAPI subset the provider's structured-output mode accepts
 * (type names uppercase, no `$ref`, no `oneOf`). Extracted so the opening and
 * continuation schemas cannot drift apart on the shape of the thing they both
 * produce.
 *
 * Note the absence of min/max on the arrays: the dialect ignores those, so
 * length is asked for in the prompt and ENFORCED in normalizeGeneratedLesson --
 * never assume the shape guarantees the size.
 */
const KEYPOINT_SCHEMA = {
  type: 'OBJECT',
  properties: {
    title: {
      type: 'STRING',
      description: 'Keypoint heading — names the idea this whole group covers.',
    },
    takeaway: {
      type: 'STRING',
      description:
        "The closing recap: ONE flowing paragraph folding the keypoint's two or three main ideas into a natural closing thought. Shown on the recap card that ends the keypoint, so it must stand alone without the cards above it.",
    },
    sections: {
      type: 'ARRAY',
      description: 'The theory cards inside this keypoint, in reading order.',
      items: {
        type: 'OBJECT',
        properties: {
          title: {
            type: 'STRING',
            description:
              'Card heading — OMIT on most cards. A heading is earned only by the move to a new major idea or by a concept the reader must remember, at most three per keypoint. The reader draws it above the card body on its own — do NOT repeat it as a block inside `blocks`.',
          },
          blocks: {
            type: 'ARRAY',
            description: 'The card body: paragraphs only.',
            items: {
              type: 'OBJECT',
              properties: {
                type: {
                  type: 'STRING',
                  enum: [LessonBlockType.PARAGRAPH],
                },
                text: { type: 'STRING' },
              },
              required: ['type', 'text'],
            },
          },
        },
        required: ['blocks'],
      },
    },
  },
  required: ['title', 'takeaway', 'sections'],
} as const;

/**
 * The whole lesson, in the ONE streamed call.
 *
 * `propertyOrdering` is load-bearing, not documentation: the response STREAMS,
 * and the server commits the lesson (and completes the import job) the moment
 * `keypointPlan` closes — before a single keypoint body exists. Identity and
 * outline first, bodies after, or the roadmap-first behaviour evaporates.
 */
export const STREAMED_LESSON_RESPONSE_SCHEMA = {
  type: 'OBJECT',
  properties: {
    title: {
      type: 'STRING',
      description: 'Short lesson title, at most 80 characters.',
    },
    description: {
      type: 'STRING',
      description: 'One or two sentences describing what the learner will get.',
    },
    keypointPlan: {
      type: 'ARRAY',
      description:
        'Every keypoint title the lesson will have, in reading order. This is the committed table of contents — the keypoints below follow it exactly.',
      items: { type: 'STRING' },
    },
    keypoints: {
      type: 'ARRAY',
      description:
        'Every keypoint of the plan, written in full, in plan order, titles matching the plan exactly.',
      items: KEYPOINT_SCHEMA,
    },
  },
  required: ['title', 'description', 'keypointPlan', 'keypoints'],
  propertyOrdering: ['title', 'description', 'keypointPlan', 'keypoints'],
} as const;

/** Phase 2's contract: the missing keypoints, in plan order, nothing else. */
export const CONTINUATION_RESPONSE_SCHEMA = {
  type: 'OBJECT',
  properties: {
    keypoints: {
      type: 'ARRAY',
      description:
        'The remaining keypoints of the plan, in order, each written in full.',
      items: KEYPOINT_SCHEMA,
    },
  },
  required: ['keypoints'],
} as const;

/**
 * Everything about HOW to write, shared by both phases verbatim.
 *
 * Written as a goal plus constraints rather than a numbered procedure: current
 * models plan this kind of task better than a hand-written script does, and
 * over-prescribing it measurably flattens the writing. The parts that ARE
 * prescriptive are the ones we later verify -- card count and length -- so the
 * prompts and normalizeGeneratedLesson never disagree about what "done" means.
 */
function styleRules(input: LessonGenerationInput): string[] {
  const language = languageName(input.outputLocale);
  const { min: minCards, max: maxCards } = input.targetCardsPerKeypoint;
  const { min: minCardWords, max: maxCardWords } = input.targetWordsPerCard;
  const { min: minTakeawayWords, max: maxTakeawayWords } =
    input.targetWordsPerShortCard;
  const hardCap = input.hardWordsPerCard;

  return [
    `Write the entire lesson in ${language}, regardless of what language the source is in. Every title, heading, card and takeaway must be in ${language}.`,
    // Not "translate the English version": the app's hand-authored courses are
    // written natively per language, and a lesson translated word by word from an
    // English draft reads like a translation in every one of them.
    `Write NATIVELY in ${language} — think in it, do not translate an English draft. Sentence structure belongs to ${language}, not to English.`,
    `Do not leave a bare English term standing in ${language} prose. Localise it, and put the English in brackets after it only when the term itself matters, e.g. "chú ý dư thừa (attention residue)". Keep the original spelling only for names of people, institutions, chemicals and named studies.`,
    `Invented example characters get natural names that belong to ${language} (Vietnamese: Nam, Linh, Minh · English: Mark, Emma · Chinese: 小李 · Japanese: 田中さん · Korean: 민수). Real people keep their real names.`,
    '',
    'Shape of a keypoint:',
    `- Between ${minCards} and ${maxCards} theory cards, then the takeaway. Let the material pick the count within that range — a thin idea sits near ${minCards}, a rich one near ${maxCards}. Never pad cards in to reach a count, and never amputate an idea to stay under one.`,
    '- One card carries ONE point. A new point opens a new card; a card that needs two paragraphs is two cards. Cramming two or three points into one card to save space loses all of them.',
    '',
    'Exactly two card patterns exist, and every theory card is one of them:',
    '- The UNTITLED card, the default: no `title`, body paragraphs only. Story cards, examples, elaboration — anything that continues the current thought — take this shape.',
    '- The TITLED card: `title` plus body paragraphs. A title is earned only by (a) the move to a NEW major idea, or (b) a concept or definition the reader must remember.',
    '- At most THREE titled cards per keypoint, and most cards untitled. A title is an accent, not a default.',
    "- A card's heading goes in its `title` field ONLY. `blocks` is the body: paragraphs. Never repeat the title as a block, and never open a card with a heading block.",
    '',
    'The takeaway that closes every keypoint:',
    `- ONE flowing paragraph of ${minTakeawayWords}-${maxTakeawayWords} words — usually three or four short sentences folding the keypoint's two or three main ideas into a natural closing thought.`,
    '- It must stand on its own, without the cards above it, and must not restate the keypoint title.',
    '- Prose only: no bullet points, no list-style line breaks, no bold run-in headings, no emoji inside it.',
    '',
    'Length, per card, counted in words and enforced card by card:',
    // Stated as a floor as well as a ceiling, because the failure mode is not
    // long cards, it is clipped ones: a model told only "at most 45" writes
    // 20-word stubs that read as notes rather than prose.
    `- Every theory card: ${minCardWords}-${maxCardWords} words. Write them FULL, so the sentences have rhythm and the idea lands whole — do not write clipped, telegraphic cards.`,
    `- ${hardCap} words is the hard ceiling for any card, of any kind. If one runs over, cut the redundancy rather than snapping a sentence in half.`,
    '- Two or three sentences per theory card, never more. Join small ideas with connectives (and / but / so / when / because) or a colon instead of adding a fourth sentence.',
    '',
    'Voice:',
    '- Micro-learning as storytelling: write a FLOW that carries the reader from one idea to the next, like a friend who understands the subject retelling it — never a dry list of facts wearing prose.',
    '- Composed, never chatty: this is written prose, not speech. No conversational filler, no throwaway particles, and every sentence has a subject and a verb.',
    '- Stay close to everyday life: prefer examples ordinary people recognise, and carry a hard concept on a familiar image or comparison instead of an academic definition.',
    '- Every sentence starts with a capital letter, in every card and in the takeaway. All-lowercase prose is not a style here, it reads as broken text.',
    // Models reach for the em dash constantly and it is wrong for every one of
    // the five languages the app ships. Spelled out with the character itself
    // because "avoid dashes" gets read as advice.
    '- Use ONLY the hyphen "-". Never the em dash "—" and never the en dash "–", anywhere, in any language. To break mid-sentence use a comma, a colon, or a second sentence.',
    '- No markdown, no bullet characters, no numbering in the text. Structure comes from the keypoints, cards and blocks.',
    '',
    'Light markup, so a card is not a flat wall of text:',
    // The reader parses exactly these tags -- see KeypointRichText on the app
    // side. Anything else arrives as literal angle brackets on screen.
    '- `<b>…</b>` around ONE or TWO key words per card: the term being taught, the contrast that matters. Never bold a whole sentence — bolding everything highlights nothing.',
    '- `<i>…</i>` for a quotation or a word being held up as a word.',
    '- `<br>` only where a line genuinely has to break, and NEVER two in a row.',
    '- NO emoji and NO decorative icons (📌 💡 ❌ ✅ 🔑 …) anywhere — not in titles, not in card bodies, not in the takeaway. Emphasis is bold and italics, nothing else.',
    '',
    'Titles, for the lesson and for every keypoint and card:',
    '- Short: about eight to ten words.',
    '- Plain and literal, understood on first read: no metaphors, no literary headline-writing. The test: does the title alone tell the reader what the content is about? If they would have to guess, rewrite it.',
    // "Sentence case" alone was read as "lowercase", and the whole lesson came
    // back with no capital anywhere -- titles, headings and body sentences all
    // starting lower ("thức ăn của bộ não"). Both wrong shapes are named here
    // because naming only the one we do not want leaves the other looking safe.
    '- Sentence case: the first letter is a CAPITAL, the rest stay lower unless the word is a name. So "Brain food" — never "brain food", never "Brain Food".',
    '',
    // Micro-learning's real failure mode: every card fine on its own, the
    // keypoint disjointed when read end to end.
    'Flow — the thing that makes a keypoint read as one piece rather than a pile of fragments:',
    '- Map the arc BEFORE writing the cards: open on a problem or situation the learner recognises, then why it happens, then the method or principle, then an example that brings it down to earth, then the takeaway. Each card is the NEXT step of that arc, never a jump.',
    '- Open a card by hooking it to the one before ("But…", "The problem is…", "So how…", "That is when…", "The result:"). Two neighbouring cards must never read as two unrelated paragraphs.',
    '- Where it fits naturally, end a card on a thought that leans into the next one. Do not force it.',
    '- Never repeat a point already made: every card adds something new, and a card that adds nothing is cut.',
    '- Explain a new term before you use it. A term that appears out of nowhere loses the learner for the rest of the keypoint.',
    '',
    '- Teach the material: explain ideas in your own words and give concrete examples.',
    '- Do not copy long passages verbatim from the source.',
    '',
    'Ground everything in the source material. Do not invent facts that are not supported by it — when the source gives too little for a point to be written honestly, DROP the point rather than filling the gap yourself.',
    'When the source holds more than the lesson can carry, choose the ideas that matter most and leave the rest out entirely. Do not compress everything in.',
  ];
}

/**
 * The one streamed pass: commit the outline first, then write every keypoint.
 *
 * The outline is a COMMITMENT, not a sketch, and the prompt says so: the app
 * draws the full roadmap from these titles the moment the plan closes — while
 * the bodies are still being written — so a model that "improves" a title
 * mid-lesson would visibly rename a node the reader is already looking at.
 */
export function buildStreamedLessonPrompt(input: LessonGenerationInput): string {
  const { min: minKeypoints, max: maxKeypoints } = input.targetKeypointCount;
  const { min: minWords, max: maxWords } = input.targetWordCount;

  return [
    `You are writing a self-study lesson for a language-learning app, based on ${sourceDescription(input)}.`,
    '',
    'Deliver, in this exact field order:',
    '1. The lesson `title` and `description`.',
    `2. \`keypointPlan\`: the complete table of contents — every keypoint title the lesson will have, in reading order. Between ${minKeypoints} and ${maxKeypoints} keypoints. Let the material decide how many within that range — one keypoint per major idea, not a fixed number. These titles are FINAL: the reader sees this list before the bodies exist, so choose titles you can deliver on.`,
    '3. `keypoints`: every keypoint of that plan, written in full, in plan order, each `title` matching the plan exactly.',
    '',
    'Plan the arc across the whole keypointPlan before writing: order it so the lesson builds — a later keypoint may rely on an earlier one, never the reverse.',
    `The finished lesson should total between ${minWords} and ${maxWords} words, spread evenly across the keypoints. Do not front-load the detail and leave the later keypoints thin.`,
    '',
    ...styleRules(input),
  ].join('\n');
}

/**
 * Phase 2: write everything after `writtenKeypoints`, against the committed
 * plan.
 *
 * The already-written keypoints ride along IN FULL (as plain text) rather than
 * as a summary: continuity of voice and the "never repeat a point" rule are
 * only checkable against the real text, and next to a whole video the extra
 * prompt tokens are noise.
 */
export function buildContinuationPrompt(
  input: LessonContinuationInput,
): string {
  const written = input.writtenKeypoints;
  const remainingTitles = input.keypointPlan.slice(written.length);
  const { min: minWords, max: maxWords } = input.targetWordCount;

  const writtenAsText = written
    .map((keypoint, index) => renderKeypointAsText(keypoint, index))
    .join('\n\n');

  return [
    `You are CONTINUING a self-study lesson for a language-learning app, based on ${sourceDescription(input)}.`,
    '',
    `The lesson is titled "${input.lessonTitle}". Its committed table of contents, in reading order:`,
    ...input.keypointPlan.map(
      (title, index) =>
        `${index + 1}. ${title}${index < written.length ? ' (already written)' : ''}`,
    ),
    '',
    'The keypoints written so far, in full:',
    '',
    writtenAsText,
    '',
    `Your task: write the remaining ${remainingTitles.length} keypoint(s) — numbers ${written.length + 1} through ${input.keypointPlan.length} — in \`keypoints\`, in that order, using EXACTLY the committed titles above. Do not rewrite, summarise or repeat the keypoints that already exist, and do not re-teach their points.`,
    '- Open the first new keypoint as a continuation: the reader has just finished the previous keypoint, so pick up from where its takeaway left off.',
    `- The FINISHED lesson (existing keypoints plus yours) should total between ${minWords} and ${maxWords} words, spread evenly. Do not leave the later keypoints thin.`,
    '',
    ...styleRules(input),
  ].join('\n');
}

function sourceDescription(input: LessonGenerationInput): string {
  return input.source.kind === 'pdfBytes'
    ? 'the attached document'
    : input.source.kind === 'remoteUri'
      ? 'the video at the attached URL'
      : 'the transcript below';
}

/**
 * A keypoint as plain prompt text, for the continuation's context block.
 *
 * Markup is stripped the same way narration strips it: the model needs the
 * words, and feeding tags back in doubles the odds of it inventing new ones.
 */
function renderKeypointAsText(
  keypoint: ILessonKeypoint,
  index: number,
): string {
  const cards = (keypoint.sections ?? []).map((section) => {
    const body = (section.blocks ?? [])
      .map((block) => stripHtml(block.text))
      .filter((text) => text.length > 0)
      .join('\n');

    return `Card: ${stripHtml(section.title)}\n${body}`;
  });

  return [
    `Keypoint ${index + 1}: ${stripHtml(keypoint.title)}`,
    ...cards,
    keypoint.takeaway ? `Takeaway: ${stripHtml(keypoint.takeaway)}` : '',
  ]
    .filter((part) => part.length > 0)
    .join('\n\n');
}
