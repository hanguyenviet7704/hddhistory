import { Injectable } from '@nestjs/common';
import { Types } from 'mongoose';

import { ILessonKeypoint } from './interface/learning-import.interface';
import { UserLessonRepository } from './repository/user-lesson.repository';

/**
 * Output practice for a lesson the reader generated themselves.
 *
 * The catalogue answers "what should the practice AI know" by walking
 * roadmap node -> outputId -> an OUTPUT lesson an editor wrote an `AIConfig` for.
 * A generated lesson has none of those: no roadmap, no output lesson, nobody to
 * write the prompt. So the prompt is BUILT from the lesson itself, here, and
 * handed to the same AI service through the same field.
 *
 * Kept in learning-import rather than in output-practice because the thing being
 * read is the user-lesson shape, and that shape belongs to this module. Output
 * practice only has to ask a question -- "is this section one of yours, and if so
 * what is its config" -- and stays ignorant of keypoints and cards.
 */
@Injectable()
export class UserLessonPracticeService {
  /**
   * How a generated lesson names itself in a `sectionId` field.
   *
   * Catalogue node ids are uuids, so a prefixed id cannot collide with one, and
   * an old client sending a raw uuid still takes the catalogue path unchanged.
   */
  static readonly SECTION_PREFIX = 'user-lesson:';

  /**
   * The budget for the lesson text pasted into the prompt.
   *
   * A generated lesson runs 600-1000 words, which fits comfortably. The cap is
   * for the legacy long-form imports still in the collection (v1 asked for
   * 3500-5000): a prompt that carries all of one would cost more per practice
   * turn than the import that produced it.
   */
  private static readonly MAX_CONTEXT_CHARS = 6000;

  constructor(private readonly userLessonRepository: UserLessonRepository) {}

  static sectionIdFor(userLessonId: string): string {
    return `${UserLessonPracticeService.SECTION_PREFIX}${userLessonId}`;
  }

  /**
   * The lesson id inside a section id, or null when this is not one of ours.
   *
   * Validates the id shape as well as the prefix: the value arrives from the
   * client, goes into a Mongo `findOne`, and `new Types.ObjectId(junk)` throws
   * where a null return is wanted.
   */
  static parseSectionId(sectionId: string): string | null {
    if (!sectionId?.startsWith(UserLessonPracticeService.SECTION_PREFIX)) {
      return null;
    }

    const id = sectionId
      .slice(UserLessonPracticeService.SECTION_PREFIX.length)
      .trim();

    return Types.ObjectId.isValid(id) ? id : null;
  }

  /**
   * The practice prompt for a generated lesson, or '' when there is nothing to
   * practise against.
   *
   * Empty rather than an exception on a missing lesson: the AI service accepts an
   * empty config and runs a generic session, which is a far better outcome for a
   * reader whose lesson was deleted mid-session than a failed conversation. The
   * lookup is owner-scoped, so another user's id resolves to nothing the same
   * way a deleted one does.
   */
  async buildAiConfig(sectionId: string, userId: string): Promise<string> {
    const lessonId = UserLessonPracticeService.parseSectionId(sectionId);
    if (!lessonId) return '';

    const lesson = await this.userLessonRepository.findOwned(lessonId, userId);
    if (!lesson) return '';

    const keypoints = (lesson.keypoints || []) as ILessonKeypoint[];
    const body = this.renderLessonBody(keypoints);
    if (!body) return '';

    return [
      'You are a practice partner for ONE lesson the learner made from their own material.',
      `Speak ${lesson.outputLocale || 'en'}.`,
      '',
      `LESSON: ${lesson.title || 'Untitled'}`,
      lesson.description ? `SUMMARY: ${lesson.description}` : '',
      '',
      'LESSON CONTENT:',
      body,
      '',
      'HOW TO RUN THE SESSION:',
      '- Ask the learner to say one idea from the lesson back in their own words.',
      '- One idea at a time, starting with the first keypoint above.',
      '- React to what they actually said: name what they got, then add the one thing they missed.',
      '- Never quote the lesson at them verbatim; this is recall practice, not a reread.',
      '- Stay inside the lesson. If they ask about something it does not cover, say so and return to it.',
      '- Keep every turn short enough to read on a phone.',
    ]
      .filter(Boolean)
      .join('\n');
  }

  /**
   * The lesson as plain text: a heading per keypoint, its cards underneath.
   *
   * Keypoint boundaries are kept because they are the order the reader met the
   * material in, and the session walks it in that order.
   */
  private renderLessonBody(keypoints: ILessonKeypoint[]): string {
    const lines: string[] = [];
    let length = 0;

    for (const [index, keypoint] of keypoints.entries()) {
      const parts = [`${index + 1}. ${keypoint?.title || `Part ${index + 1}`}`];

      for (const section of keypoint?.sections || []) {
        const text = (section?.blocks || [])
          .map(block => block?.text?.trim())
          .filter(Boolean)
          .join(' ');

        if (text) parts.push(`   - ${text}`);
      }

      const block = parts.join('\n');
      // Whole keypoints, never half of one: a prompt cut mid-card would ask the
      // learner to recall an idea it only has the first sentence of.
      if (length + block.length > UserLessonPracticeService.MAX_CONTEXT_CHARS) {
        break;
      }

      lines.push(block);
      length += block.length;
    }

    return lines.join('\n');
  }
}
