import { GeneratedLesson } from './ai/lesson-generation.types';
import { LessonBlockType } from './enum/learning-import.enum';
import { LEARNING_IMPORT_CONFIG } from './learning-import.config';
import {
  capitalizeFirstLetter,
  countWords,
  LessonTooShortError,
  weekWindow,
  normalizeGeneratedLesson,
  pickPoolImage,
} from './learning-import.util';
import { YoutubeSourceResolver } from './source/youtube-source.resolver';

type CardSpec = { title: string; paragraphs: string[] };

// Builds a lesson long enough to clear the acceptance floor, so each test can
// vary the ONE thing it is about instead of restating 1000 words of filler.
// Each entry is a KEYPOINT holding its own cards.
function lessonOf(
  keypoints: Array<{ title: string; cards: CardSpec[] }>,
): GeneratedLesson {
  return {
    title: 'Title',
    description: 'Description',
    keypoints: keypoints.map(keypoint => ({
      title: keypoint.title,
      sections: keypoint.cards.map(card => ({
        title: card.title,
        blocks: card.paragraphs.map(text => ({
          type: LessonBlockType.PARAGRAPH,
          text,
        })),
      })),
    })),
  };
}

// One keypoint holding one card — the shape most tests here only need in order
// to clear the floor and then assert something else.
function singleKeypoint(card: CardSpec) {
  return [{ title: 'Keypoint', cards: [card] }];
}

const longParagraph = (words: number) => 'word '.repeat(words).trim();

describe('countWords', () => {
  it('counts whitespace-delimited words', () => {
    expect(countWords('one two three')).toBe(3);
    expect(countWords('  padded   spacing  ')).toBe(2);
  });

  it('returns zero for empty input', () => {
    expect(countWords('')).toBe(0);
    expect(countWords('   ')).toBe(0);
  });

  /**
   * The reason this function exists at all.
   *
   * Japanese and Chinese are written without spaces, so a plain whitespace split
   * scores a full-length lesson as a couple of "words" and the acceptance floor
   * rejects it. Every CJK lesson would have failed with CONTENT_TOO_SHORT.
   */
  it('counts CJK characters individually', () => {
    expect(countWords('日本語')).toBe(3);
    expect(countWords('한국어')).toBe(3);
    expect(countWords('ひらがな')).toBe(4);
  });

  it('counts mixed scripts additively', () => {
    // Two Latin words plus three CJK characters.
    expect(countWords('hello 日本語 world')).toBe(5);
  });

  it('counts Vietnamese as ordinary spaced words', () => {
    expect(countWords('Tiếng Việt rất hay')).toBe(4);
  });
});

describe('normalizeGeneratedLesson', () => {
  it('accepts a lesson at the floor and reports its size', () => {
    // Sized just over `minAcceptedWordCount` on purpose: a test that clears the
    // floor by 3000 words would keep passing if the floor were raised by
    // mistake, which is the regression it exists to catch.
    const result = normalizeGeneratedLesson(
      lessonOf([
        { title: 'One', cards: [{ title: 'A', paragraphs: [longParagraph(240)] }] },
        { title: 'Two', cards: [{ title: 'B', paragraphs: [longParagraph(240)] }] },
      ]),
    );

    expect(result.wordCount).toBeGreaterThanOrEqual(
      LEARNING_IMPORT_CONFIG.minAcceptedWordCount,
    );
    expect(result.keypoints).toHaveLength(2);
    expect(result.estimatedMinutes).toBeGreaterThan(0);
  });

  it('counts the keypoint titles towards the lesson length', () => {
    // The titles are read aloud and shown on screen, so they are part of the
    // lesson. Counting only the cards would score a lesson short by however many
    // keypoints it happens to have.
    const result = normalizeGeneratedLesson(
      lessonOf([
        {
          title: 'A keypoint title of exactly six words',
          cards: [{ title: '', paragraphs: [longParagraph(470)] }],
        },
      ]),
    );

    expect(result.wordCount).toBe(477);
  });

  it('rejects a lesson under the floor', () => {
    expect(() =>
      normalizeGeneratedLesson(
        lessonOf(
          singleKeypoint({ title: 'Thin', paragraphs: ['barely anything'] }),
        ),
      ),
    ).toThrow(LessonTooShortError);
  });

  it('drops empty blocks and the cards left empty by that', () => {
    const result = normalizeGeneratedLesson(
      lessonOf([
        {
          title: 'Keypoint',
          cards: [
            { title: 'Real', paragraphs: [longParagraph(470)] },
            { title: 'Hollow', paragraphs: ['', '   '] },
          ],
        },
      ]),
    );

    expect(result.keypoints[0].sections).toHaveLength(1);
    expect(result.keypoints[0].sections[0].title).toBe('Real');
  });

  /**
   * A keypoint with no readable card cannot be entered — the reader would open
   * an empty deck and the completion screen would fire on arrival.
   */
  it('drops a keypoint left with no cards at all', () => {
    const result = normalizeGeneratedLesson(
      lessonOf([
        {
          title: 'Real',
          cards: [{ title: 'A', paragraphs: [longParagraph(470)] }],
        },
        { title: 'Hollow', cards: [{ title: 'B', paragraphs: ['', '  '] }] },
      ]),
    );

    expect(result.keypoints).toHaveLength(1);
    expect(result.keypoints[0].title).toBe('Real');
  });

  it('falls back to the first keypoint heading when the title is blank', () => {
    const lesson = lessonOf([
      {
        title: 'Fallback heading',
        cards: [{ title: 'A', paragraphs: [longParagraph(470)] }],
      },
    ]);
    lesson.title = '   ';

    expect(normalizeGeneratedLesson(lesson).title).toBe('Fallback heading');
  });

  /**
   * The reader draws the keypoint title above every card under it, so an unnamed
   * keypoint leaves a blank strip across the whole sitting.
   */
  it('names an untitled keypoint after its first card', () => {
    const lesson = lessonOf([
      {
        title: '  ',
        cards: [{ title: 'Card heading', paragraphs: [longParagraph(470)] }],
      },
    ]);

    expect(normalizeGeneratedLesson(lesson).keypoints[0].title).toBe(
      'Card heading',
    );
  });

  it('names an untitled keypoint by position when its cards are untitled too', () => {
    const lesson = lessonOf([
      { title: '', cards: [{ title: '', paragraphs: [longParagraph(470)] }] },
    ]);

    expect(normalizeGeneratedLesson(lesson).keypoints[0].title).toBe('Part 1');
  });

  it('coerces an unknown block type to paragraph rather than dropping the text', () => {
    const lesson = lessonOf(
      singleKeypoint({ title: 'One', paragraphs: [longParagraph(470)] }),
    );
    (lesson.keypoints[0].sections[0].blocks[0] as any).type = 'bullet';

    const result = normalizeGeneratedLesson(lesson);

    expect(result.keypoints[0].sections[0].blocks[0].type).toBe(
      LessonBlockType.PARAGRAPH,
    );
  });
});

describe('weekWindow', () => {
  it('starts on the Monday of the week containing the date', () => {
    // Wednesday 12 Aug 2026.
    const { from, to } = weekWindow(new Date(2026, 7, 12, 13, 45));

    expect(from.getDate()).toBe(10);
    expect(from.getDay()).toBe(1);
    expect(from.getHours()).toBe(0);
    expect(from.getMinutes()).toBe(0);

    expect(to.getDate()).toBe(17);
    expect(to.getDay()).toBe(1);
  });

  it('treats Sunday as the last day of the week, not the first', () => {
    // Sunday 16 Aug 2026 — the window must still open on the 10th, or a Sunday
    // import would be counted against the week that has not started yet.
    const { from, to } = weekWindow(new Date(2026, 7, 16, 23, 59));

    expect(from.getDate()).toBe(10);
    expect(to.getDate()).toBe(17);
  });

  it('rolls back over a month boundary', () => {
    // Wednesday 2 Sep 2026 — its Monday is 31 Aug.
    const { from } = weekWindow(new Date(2026, 8, 2, 9, 0));

    expect(from.getMonth()).toBe(7);
    expect(from.getDate()).toBe(31);
  });

  it('rolls the year over at the end of December', () => {
    // Wednesday 30 Dec 2026 — the window closes on 4 Jan 2027.
    const { to } = weekWindow(new Date(2026, 11, 30, 12, 0));

    expect(to.getFullYear()).toBe(2027);
    expect(to.getMonth()).toBe(0);
    expect(to.getDate()).toBe(4);
  });
});

describe('YoutubeSourceResolver.parseVideoId', () => {
  const id = 'dQw4w9WgXcQ';

  it.each([
    `https://www.youtube.com/watch?v=${id}`,
    `https://youtube.com/watch?v=${id}&t=42s`,
    `https://m.youtube.com/watch?v=${id}`,
    `https://youtu.be/${id}`,
    `https://www.youtube.com/shorts/${id}`,
    `https://www.youtube.com/embed/${id}`,
    `https://www.youtube.com/live/${id}`,
    `  https://www.youtube.com/watch?v=${id}  `,
  ])('accepts %s', url => {
    expect(YoutubeSourceResolver.parseVideoId(url)).toBe(id);
  });

  it.each([
    'not a url',
    'https://vimeo.com/12345',
    'https://www.youtube.com/watch?v=tooshort',
    'https://www.youtube.com/',
    '',
  ])('rejects %s', url => {
    expect(YoutubeSourceResolver.parseVideoId(url)).toBeNull();
  });
});

describe('capitalizeFirstLetter', () => {
  it('raises a lowercase opening letter', () => {
    expect(capitalizeFirstLetter('thức ăn của bộ não')).toBe(
      'Thức ăn của bộ não',
    );
  });

  it('steps over an emoji signpost to reach the letter', () => {
    expect(capitalizeFirstLetter('📌 thức ăn của bộ não')).toBe(
      '📌 Thức ăn của bộ não',
    );
  });

  it('steps over markup rather than counting it as the first letter', () => {
    expect(capitalizeFirstLetter('<b>thông tin</b> là đồ ăn')).toBe(
      '<b>Thông tin</b> là đồ ăn',
    );
  });

  it('leaves a word that capitalises itself later alone', () => {
    // "IPhone" would be a worse error than the lowercase this function exists to
    // fix, and the same goes for eSIM and macOS.
    expect(capitalizeFirstLetter('iPhone không có cơ chế đó')).toBe(
      'iPhone không có cơ chế đó',
    );
  });

  it('touches nothing when the first letter is already a capital', () => {
    expect(capitalizeFirstLetter('Thức ăn của bộ não')).toBe(
      'Thức ăn của bộ não',
    );
  });

  it('leaves the rest of the line exactly as written', () => {
    expect(capitalizeFirstLetter('mạng xã hội và AI trong 2026')).toBe(
      'Mạng xã hội và AI trong 2026',
    );
  });

  it('passes a caseless script through untouched', () => {
    expect(capitalizeFirstLetter('信息就像食物')).toBe('信息就像食物');
  });

  it('returns text with no letters in it unchanged', () => {
    expect(capitalizeFirstLetter('📌 ...')).toBe('📌 ...');
    expect(capitalizeFirstLetter('')).toBe('');
  });
});

describe('normalizeGeneratedLesson capitalisation', () => {
  // The model was asked for sentence case and returned an all-lowercase lesson.
  // The prompt now says it in plainer words; this is the guarantee, because a
  // prompt is a request and this is the last place that can insist.
  it('capitalises every line the reader sees', () => {
    const result = normalizeGeneratedLesson({
      title: 'thừa mứa và đói khát',
      description: 'bài học về nạp thông tin',
      keypoints: [
        {
          title: 'mạng xã hội và lượng thông tin',
          takeaway: 'thông tin cần được chọn lọc',
          sections: [
            {
              title: '📌 thức ăn của bộ não',
              blocks: [
                {
                  type: LessonBlockType.PARAGRAPH,
                  text: `thông tin giống như đồ ăn. ${longParagraph(240)}`,
                },
              ],
            },
            {
              title: 'lượng vừa đủ',
              blocks: [
                {
                  type: LessonBlockType.PARAGRAPH,
                  text: longParagraph(240),
                },
              ],
            },
          ],
        },
      ],
    });

    expect(result.title).toBe('Thừa mứa và đói khát');
    expect(result.description).toBe('Bài học về nạp thông tin');
    expect(result.keypoints[0].title).toBe('Mạng xã hội và lượng thông tin');
    expect(result.keypoints[0].takeaway).toBe('Thông tin cần được chọn lọc');
    expect(result.keypoints[0].sections[0].title).toBe(
      '📌 Thức ăn của bộ não',
    );
    expect(result.keypoints[0].sections[0].blocks[0].text).toMatch(
      /^Thông tin giống như đồ ăn\./,
    );
    expect(result.keypoints[0].sections[1].title).toBe('Lượng vừa đủ');
  });
});

describe('normalizeGeneratedLesson title echo', () => {
  // The reported shape: the model put the heading in `title` AND as the first
  // block, so the app and the admin panel each printed it twice.
  it('drops an opening block that repeats the card title', () => {
    const result = normalizeGeneratedLesson({
      title: 'Why sleep matters',
      description: 'A lesson',
      keypoints: [
        {
          title: 'The high cost of sleep deprivation',
          sections: [
            {
              title: '📌 The hidden price of late nights',
              blocks: [
                {
                  type: LessonBlockType.HEADING,
                  text: '📌 The hidden price of late nights',
                },
                { type: LessonBlockType.PARAGRAPH, text: longParagraph(240) },
              ],
            },
            {
              title: 'How lack of sleep ages men',
              blocks: [
                // Same line, arriving as a PARAGRAPH and with the emoji only on
                // one side — still the same visible line.
                {
                  type: LessonBlockType.PARAGRAPH,
                  text: '❌ How lack of sleep ages men',
                },
                { type: LessonBlockType.PARAGRAPH, text: longParagraph(240) },
              ],
            },
          ],
        },
      ],
    });

    const sections = result.keypoints[0].sections;
    expect(sections[0].blocks).toHaveLength(1);
    // What survives is the BODY, not the echo (capitalised on the way through,
    // like every other line).
    expect(sections[0].blocks[0].text).toBe(
      capitalizeFirstLetter(longParagraph(240)),
    );
    expect(sections[1].blocks).toHaveLength(1);
    // The titles themselves are untouched.
    expect(sections[0].title).toBe('📌 The hidden price of late nights');
  });

  it('keeps a heading block that says something else', () => {
    const result = normalizeGeneratedLesson({
      title: 'Title',
      description: 'A lesson',
      keypoints: [
        {
          title: 'Keypoint',
          sections: [
            {
              title: 'The hidden price of late nights',
              blocks: [
                { type: LessonBlockType.HEADING, text: 'What the studies show' },
                { type: LessonBlockType.PARAGRAPH, text: longParagraph(480) },
              ],
            },
          ],
        },
      ],
    });

    expect(result.keypoints[0].sections[0].blocks).toHaveLength(2);
  });

  it('keeps a body block that merely starts with the same words', () => {
    const result = normalizeGeneratedLesson({
      title: 'Title',
      description: 'A lesson',
      keypoints: [
        {
          title: 'Keypoint',
          sections: [
            {
              title: 'Sleep debt',
              blocks: [
                {
                  type: LessonBlockType.PARAGRAPH,
                  text: `Sleep debt is not a metaphor. ${longParagraph(480)}`,
                },
              ],
            },
          ],
        },
      ],
    });

    expect(result.keypoints[0].sections[0].blocks).toHaveLength(1);
  });
});

// The art dealer for admin-curated cover pools: deterministic, sequence-per-
// lesson, and honest about an empty pool.
describe('pickPoolImage', () => {
  const pool = ['a.png', 'b.png', 'c.png'];

  it('returns empty on an empty or all-blank pool', () => {
    expect(pickPoolImage([], 'seed')).toBe('');
    expect(pickPoolImage(['', ''], 'seed')).toBe('');
  });

  it('is deterministic for the same seed and offset', () => {
    expect(pickPoolImage(pool, 'job-123', 2)).toBe(
      pickPoolImage(pool, 'job-123', 2),
    );
  });

  it('walks the pool with the offset, so neighbouring keypoints differ', () => {
    const first = pickPoolImage(pool, 'job-123', 0);
    const second = pickPoolImage(pool, 'job-123', 1);
    const third = pickPoolImage(pool, 'job-123', 2);
    expect(new Set([first, second, third]).size).toBe(3);
  });

  it('wraps when a lesson has more keypoints than the pool has images', () => {
    expect(pickPoolImage(pool, 'job-123', 3)).toBe(
      pickPoolImage(pool, 'job-123', 0),
    );
  });

  it('skips blank entries rather than dealing them', () => {
    expect(['x.png']).toContain(pickPoolImage(['', 'x.png'], 'seed', 0));
  });
});
