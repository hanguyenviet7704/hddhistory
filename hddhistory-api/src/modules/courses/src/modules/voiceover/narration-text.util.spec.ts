import { sanitizeForNarration } from './narration-text.util';

describe('sanitizeForNarration', () => {
  it('drops emoji and pictographs the voice would name aloud', () => {
    expect(sanitizeForNarration('💡 Mẹo: hãy thử ngay 👉 nhé ✨')).toBe(
      'Mẹo: hãy thử ngay nhé',
    );
  });

  it('drops quotation marks but keeps the words', () => {
    expect(sanitizeForNarration('“trí nhớ” và «ký ức» hay „memory‟')).toBe(
      'trí nhớ và ký ức hay memory',
    );
    expect(sanitizeForNarration('He said "hello" and ‘hi’')).toBe(
      'He said hello and hi',
    );
  });

  it('keeps the apostrophe inside a word', () => {
    expect(sanitizeForNarration("don't stop")).toBe("don't stop");
    expect(sanitizeForNarration("'quoted' word")).toBe('quoted word');
  });

  it('drops markup leftovers, bullets and arrows', () => {
    expect(sanitizeForNarration('**quan trọng** • bước 1 → bước 2')).toBe(
      'quan trọng bước 1 bước 2',
    );
    expect(sanitizeForNarration('`code` ~x~ ^y^ ▶ chạy ✓')).toBe('code x y chạy');
  });

  it('collapses the whitespace it leaves behind', () => {
    expect(sanitizeForNarration('a  💡  b')).toBe('a b');
  });

  it('leaves ordinary sentence punctuation alone', () => {
    expect(sanitizeForNarration('Xin chào, bạn khỏe không? Tốt — rất tốt!')).toBe(
      'Xin chào, bạn khỏe không? Tốt — rất tốt!',
    );
  });
});
