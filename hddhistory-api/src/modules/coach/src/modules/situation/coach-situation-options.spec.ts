import { normaliseSituationOptions } from './coach-situation.service';

/**
 * The letters on a scene's three ways in.
 *
 * They matter more than they look: the reader may answer a scene by typing just
 * "A", and `resolveSceneOption` turns that letter back into the approach it
 * stands for. A gap in the sequence is therefore not a cosmetic problem — it is
 * a letter on screen that resolves to nothing, or worse to the wrong line.
 */
describe('normaliseSituationOptions', () => {
  const trio = [
    { key: 'A', label: 'Tính hệ quả lâu dài', text: 'Thêm một triệu mỗi tháng.' },
    { key: 'B', label: 'Hoãn lại quyết định', text: 'Để mình xem lại đã.' },
    { key: 'C', label: 'Đồng thuận theo cảm xúc', text: 'Nhìn cũng thích thật.' },
  ];

  it('tells "not sent" apart from "sent empty"', () => {
    // Undefined must not write the column — a form that omits the field is
    // leaving the generated trio alone, not clearing it.
    expect(normaliseSituationOptions(undefined)).toBeUndefined();
    expect(normaliseSituationOptions([])).toEqual([]);
  });

  it('re-letters from position after a middle row is deleted', () => {
    const kept = normaliseSituationOptions([trio[0], trio[2]]);

    // Not "A" and "C": the reader would see a letter with nothing between.
    expect(kept?.map((option) => option.key)).toEqual(['A', 'B']);
    expect(kept?.[1].label).toBe('Đồng thuận theo cảm xúc');
  });

  it('ignores the key the caller sent', () => {
    const shuffled = normaliseSituationOptions([
      { key: 'C', label: 'Một', text: 'x' },
      { key: 'A', label: 'Hai', text: 'y' },
    ]);

    expect(shuffled?.map((option) => option.key)).toEqual(['A', 'B']);
    expect(shuffled?.map((option) => option.label)).toEqual(['Một', 'Hai']);
  });

  it('drops a half-filled row rather than shipping a blank approach', () => {
    const cleaned = normaliseSituationOptions([
      trio[0],
      { key: 'B', label: '  ', text: 'có câu nhưng không có tên' },
      { key: 'C', label: 'Có tên nhưng không có câu', text: '   ' },
      trio[1],
    ]);

    expect(cleaned).toHaveLength(2);
    expect(cleaned?.map((option) => option.key)).toEqual(['A', 'B']);
  });

  it('trims what an editor pasted in', () => {
    const [first] = normaliseSituationOptions([
      { key: '', label: '  Hoãn lại  ', text: '  Để mình xem lại đã.  ' },
      { key: '', label: 'Tính hệ quả', text: 'Thêm một triệu mỗi tháng.' },
    ])!;

    expect(first).toEqual({
      key: 'A',
      label: 'Hoãn lại',
      text: 'Để mình xem lại đã.',
    });
  });

  /**
   * Two or three, never one (owner 2026-09-08: "không cần thiết phải luôn cố
   * định là 3 option… mà có thể là 2").
   *
   * The floor matters more than the ceiling: a single "way to answer" is not a
   * choice, it is THE answer — the one thing a scene must never hand over.
   */
  it('keeps two, and drops the set when only one survives', () => {
    expect(normaliseSituationOptions([trio[0], trio[1]])).toHaveLength(2);
    expect(normaliseSituationOptions([trio[0]])).toEqual([]);
    // One real plus one half-filled is still one.
    expect(
      normaliseSituationOptions([trio[0], { key: 'B', label: 'Chỉ có tên', text: '' }]),
    ).toEqual([]);
  });
});
