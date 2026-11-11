import { GeneratedLessonOutline } from './lesson-generation.types';
import { LessonStreamAssembler } from './lesson-stream-assembler';
import { ILessonKeypoint } from '../interface/learning-import.interface';

/**
 * The assembler is what makes streamed generation safe to act on, so what is
 * pinned here is exactly what the runner relies on:
 *  - the outline fires ONCE, the moment the plan closes, before any body;
 *  - each keypoint fires the moment ITS object closes, in order;
 *  - none of that depends on where the network happened to split the text —
 *    including inside escapes and inside multi-byte emoji;
 *  - a stream that dies mid-keypoint yields exactly the completed prefix.
 */

const LESSON = {
  title: 'Bẫy "tư duy" thường gặp',
  description: 'Hai bài học về cách suy nghĩ — có cả ký tự { } [ ] trong chuỗi.',
  keypointPlan: ['Cái bẫy suy diễn 🧠', 'Thoát khỏi lối mòn'],
  keypoints: [
    {
      title: 'Cái bẫy suy diễn 🧠',
      takeaway: 'Đừng sao chép "công thức" của người khác.',
      sections: [
        {
          title: 'Mở quán vì thấy quán đông',
          blocks: [
            { type: 'paragraph', text: 'Bạn thấy 1 quán đông khách... {thế là} mở theo.' },
          ],
        },
      ],
    },
    {
      title: 'Thoát khỏi lối mòn',
      takeaway: 'Bắt đầu từ vấn đề, không phải từ mô hình.',
      sections: [
        {
          title: 'Câu hỏi đúng',
          blocks: [{ type: 'paragraph', text: 'Hỏi "ai đau ở đâu" trước.' }],
        },
      ],
    },
  ],
};

const RAW = JSON.stringify(LESSON);

/** Feed [raw] in slices of [size]; collect everything the assembler emits. */
function run(raw: string, size: number) {
  const assembler = new LessonStreamAssembler();
  const outlines: GeneratedLessonOutline[] = [];
  const heads: { index: number; title: string; takeaway: string }[] = [];
  const sections: { keypointIndex: number; section: unknown }[] = [];
  const keypoints: { index: number; keypoint: ILessonKeypoint }[] = [];

  for (let at = 0; at < raw.length; at += size) {
    const result = assembler.push(raw.slice(at, at + size));
    if (result.outline) outlines.push(result.outline);
    heads.push(...result.heads);
    sections.push(...result.sections);
    keypoints.push(...result.keypoints);
  }

  return { assembler, outlines, heads, sections, keypoints };
}

describe('LessonStreamAssembler', () => {
  // Chunk sizes chosen to hit every ugly boundary somewhere: 1 splits inside
  // every escape sequence and every emoji surrogate pair, the primes make the
  // boundaries land differently each run through the document.
  it.each([1, 7, 64, 1024, RAW.length])(
    'emits the outline once and every keypoint in order (chunk size %i)',
    size => {
      const { outlines, keypoints } = run(RAW, size);

      expect(outlines).toHaveLength(1);
      expect(outlines[0].title).toBe(LESSON.title);
      expect(outlines[0].keypointPlan).toEqual(LESSON.keypointPlan);

      expect(keypoints.map(entry => entry.index)).toEqual([0, 1]);
      expect(keypoints[0].keypoint).toEqual(LESSON.keypoints[0]);
      expect(keypoints[1].keypoint).toEqual(LESSON.keypoints[1]);
    },
  );

  it.each([1, 64, RAW.length])(
    'emits a head (takeaway) and every card before each keypoint closes (chunk size %i)',
    size => {
      const { heads, sections } = run(RAW, size);

      // One head per keypoint, carrying the takeaway the prefetcher needs.
      expect(heads.map(head => head.index)).toEqual([0, 1]);
      expect(heads[0].takeaway).toBe(LESSON.keypoints[0].takeaway);

      // Every card of every keypoint, keyed to its keypoint, in order.
      expect(sections.map(event => event.keypointIndex)).toEqual([0, 1]);
      expect(sections[0].section).toEqual(LESSON.keypoints[0].sections[0]);
      expect(sections[1].section).toEqual(LESSON.keypoints[1].sections[0]);
    },
  );

  it('emits the outline BEFORE any keypoint body has closed', () => {
    const assembler = new LessonStreamAssembler();
    // Everything up to (not including) the `[` that opens the keypoints array.
    const bodiesOpenAt = RAW.indexOf('"keypoints":[') + '"keypoints":'.length;

    const early = assembler.push(RAW.slice(0, bodiesOpenAt));
    expect(early.outline).toBeUndefined();

    // One character further — the keypoints array opens — the outline lands.
    const next = assembler.push(RAW.slice(bodiesOpenAt, bodiesOpenAt + 1));
    expect(next.outline?.keypointPlan).toEqual(LESSON.keypointPlan);
    expect(next.keypoints).toHaveLength(0);
  });

  it('a stream dying mid-keypoint yields exactly the completed prefix', () => {
    // Cut inside keypoint 2's BODY (lastIndexOf: its title also appears in the
    // plan, which sits before every body): keypoint 1 closed, keypoint 2 not.
    const cutAt = RAW.lastIndexOf('Thoát khỏi lối mòn') + 5;
    const { assembler, keypoints } = run(RAW.slice(0, cutAt), 13);

    expect(keypoints.map(entry => entry.index)).toEqual([0]);
    expect(assembler.snapshotKeypoints()).toHaveLength(1);
    expect(assembler.snapshotKeypoints()[0].title).toBe(
      LESSON.keypoints[0].title,
    );
  });

  it('structural characters inside strings are data, not structure', () => {
    // The lesson text above deliberately carries { } [ ] " (escaped) and emoji
    // inside strings; reaching the right counts at chunk size 1 proves the
    // scanner never mistook one for a bracket. Belt-and-braces on the quote:
    const tricky = JSON.stringify({
      title: 'a"b\\c{d[e',
      description: '\\\\"',
      keypointPlan: ['p1'],
      keypoints: [{ title: 'p1', takeaway: '', sections: [] }],
    });
    const { outlines, keypoints } = run(tricky, 1);

    expect(outlines).toHaveLength(1);
    expect(outlines[0].title).toBe('a"b\\c{d[e');
    expect(keypoints).toHaveLength(1);
  });
});
