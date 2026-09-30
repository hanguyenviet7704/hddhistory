import {
  buildKeypointNarrationScripts,
  buildSectionCues,
  buildSectionNarrationScripts,
  computeNarrationHash,
  stripHtml,
} from './user-lesson-narration.util';
import { LessonBlockType } from '../enum/learning-import.enum';
import { ILessonSection } from '../interface/learning-import.interface';

function section(title: string, ...paragraphs: string[]): ILessonSection {
  return {
    title,
    blocks: paragraphs.map((text) => ({
      type: LessonBlockType.PARAGRAPH,
      text,
    })),
  };
}

describe('buildSectionNarrationScripts', () => {
  it('reads the heading then the paragraphs, separated by blank lines', () => {
    const scripts = buildSectionNarrationScripts([
      section('Heading', 'First para.', 'Second para.'),
    ]);

    expect(scripts).toEqual(['Heading\n\nFirst para.\n\nSecond para.']);
  });

  /**
   * The index alignment the whole cue map rests on.
   *
   * A section that has nothing sayable must still occupy its slot. Dropping it
   * would slide every later index by one, and the reader would land on the wrong
   * card for the rest of the lesson.
   */
  it('keeps one entry per section, including empty ones', () => {
    const scripts = buildSectionNarrationScripts([
      section('One', 'text'),
      section('', ''),
      section('Three', 'more text'),
    ]);

    expect(scripts).toHaveLength(3);
    expect(scripts[1]).toBe('');
  });

  it('strips html a model occasionally slips in', () => {
    const scripts = buildSectionNarrationScripts([
      section('Title', '<b>bold</b> and <i>italic</i>'),
    ]);

    expect(scripts[0]).toBe('Title\n\nbold and italic');
  });

  it('survives malformed sections without throwing', () => {
    const scripts = buildSectionNarrationScripts([
      { title: undefined, blocks: undefined } as any,
      null as any,
    ]);

    expect(scripts).toEqual(['', '']);
  });
});

describe('stripHtml', () => {
  it('decodes the entities that actually show up', () => {
    expect(stripHtml('a&nbsp;b &amp; c &lt;d&gt;')).toBe('a b & c <d>');
  });

  it('collapses runs of whitespace', () => {
    expect(stripHtml('a   \n\n  b')).toBe('a b');
  });
});

describe('buildSectionCues', () => {
  it('lays durations end to end', () => {
    const { cues, durationMs } = buildSectionCues([1000, 2000, 500]);

    expect(cues).toEqual([
      { cardIndex: 0, startMs: 0, durMs: 1000 },
      { cardIndex: 1, startMs: 1000, durMs: 2000 },
      { cardIndex: 2, startMs: 3000, durMs: 500 },
    ]);
    expect(durationMs).toBe(3500);
  });

  /**
   * A silent card keeps its cue at zero length, so the cue at index `i` always
   * addresses card `i` no matter how many cards produced no audio.
   */
  it('gives a silent card a zero-length cue rather than skipping it', () => {
    const { cues, durationMs } = buildSectionCues([1000, 0, 500]);

    expect(cues.map((cue) => cue.cardIndex)).toEqual([0, 1, 2]);
    expect(cues[1]).toEqual({ cardIndex: 1, startMs: 1000, durMs: 0 });
    expect(cues[2].startMs).toBe(1000);
    expect(durationMs).toBe(1500);
  });

  /**
   * Every keypoint's cues start at zero, because each keypoint is its own file.
   * A lesson-wide offset here would seek keypoint two's player past the end of
   * its own audio.
   */
  it('starts each keypoint at zero', () => {
    expect(buildSectionCues([800, 400]).cues[0].startMs).toBe(0);
  });

  it('handles a keypoint with no audio at all', () => {
    expect(buildSectionCues([])).toEqual({ cues: [], durationMs: 0 });
  });
});

describe('buildKeypointNarrationScripts', () => {
  const keypoint = (titles: string[]) => ({
    title: 'Keypoint',
    sections: titles.map((title) => ({
      title,
      blocks: [{ type: LessonBlockType.PARAGRAPH, text: `${title} body` }],
    })),
  });

  it('flattens the scripts and records where each keypoint starts', () => {
    const { scripts, groups } = buildKeypointNarrationScripts([
      keypoint(['a', 'b']),
      keypoint(['c']),
    ]);

    expect(scripts).toHaveLength(3);
    expect(groups).toEqual([
      { start: 0, count: 2 },
      { start: 2, count: 1 },
    ]);
  });

  /**
   * The groups are what slice the flat clip list back into per-keypoint merges.
   * A keypoint whose cards are all silent must still claim its slots, or every
   * later keypoint would merge the wrong clips.
   */
  it('keeps the slots of a keypoint whose cards say nothing', () => {
    const silent = {
      title: 'Silent',
      sections: [{ title: '', blocks: [] }, { title: '', blocks: [] }],
    };
    const { scripts, groups } = buildKeypointNarrationScripts([
      silent,
      keypoint(['c']),
    ]);

    expect(scripts.slice(0, 2)).toEqual(['', '']);
    expect(groups[1]).toEqual({ start: 2, count: 1 });
  });

  /**
   * The recap card that closes a keypoint reads its takeaway, so the takeaway is
   * a clip like any other -- appended AFTER the cards, at card index
   * `sections.length`. Without it narration stopped one card short and the last
   * flip card sat silent.
   */
  it('dubs the takeaway as one more clip after the cards', () => {
    const { scripts, groups } = buildKeypointNarrationScripts([
      { ...keypoint(['a', 'b']), takeaway: 'Nạp có chọn lọc.' },
      keypoint(['c']),
    ]);

    expect(scripts).toHaveLength(4);
    expect(scripts[2]).toBe('Nạp có chọn lọc.');
    // The group grew with it, so the merge still cuts this keypoint's clips at
    // the right place and the next keypoint starts after the takeaway.
    expect(groups).toEqual([
      { start: 0, count: 3 },
      { start: 3, count: 1 },
    ]);
  });

  it('strips markup out of the takeaway on the way to the ear', () => {
    const { scripts } = buildKeypointNarrationScripts([
      { ...keypoint(['a']), takeaway: 'Nạp <b>có chọn lọc</b>.' },
    ]);

    // A tag becomes a space, which is `stripHtml`'s long-standing behaviour and
    // leaves "lọc ." here. Inaudible, so the claim under test is that no tag
    // reaches the synthesiser -- not the spacing around the full stop.
    expect(scripts[1]).not.toContain('<');
    expect(scripts[1]).toContain('Nạp có chọn lọc');
  });

  /**
   * An empty entry would still claim a cue, and the reader would hand its recap
   * card a zero-length clip -- narration that announces itself and says nothing.
   */
  it('appends nothing when the keypoint has no takeaway', () => {
    const { scripts, groups } = buildKeypointNarrationScripts([
      keypoint(['a', 'b']),
      { ...keypoint(['c']), takeaway: '   ' },
    ]);

    expect(scripts).toHaveLength(3);
    expect(groups).toEqual([
      { start: 0, count: 2 },
      { start: 2, count: 1 },
    ]);
  });

  it('handles a lesson with no keypoints', () => {
    expect(buildKeypointNarrationScripts([])).toEqual({
      scripts: [],
      groups: [],
    });
  });
});

describe('computeNarrationHash', () => {
  it('is stable for the same voice and scripts', () => {
    expect(computeNarrationHash('voice-a', ['one', 'two'])).toBe(
      computeNarrationHash('voice-a', ['one', 'two']),
    );
  });

  it('changes when the text changes', () => {
    expect(computeNarrationHash('voice-a', ['one'])).not.toBe(
      computeNarrationHash('voice-a', ['two']),
    );
  });

  /**
   * The reason the voice is in the hash at all: a narrator swap re-synthesises
   * audio under the SAME deterministic R2 key, so without this the url would
   * stay identical while the sound behind it changed, and every cache in the
   * chain would keep serving the old narrator.
   */
  it('changes when only the voice changes', () => {
    expect(computeNarrationHash('voice-a', ['one'])).not.toBe(
      computeNarrationHash('voice-b', ['one']),
    );
  });
});
