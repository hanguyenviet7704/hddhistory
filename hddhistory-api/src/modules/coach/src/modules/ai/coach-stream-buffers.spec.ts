import { CoachJsonFieldStream } from './coach-json-field-stream';
import { CoachSentenceHold } from './coach-sentence-hold';

/** Feeds a string one character at a time — the worst case a socket can hand us. */
function drip(sink: { push(s: string): string }, text: string): string {
  return [...text].map(character => sink.push(character)).join('');
}

describe('CoachJsonFieldStream', () => {
  it('đọc được trường khi JSON mới về một nửa', () => {
    const stream = new CoachJsonFieldStream('reply');

    expect(stream.push('{"reply": "Xin ch')).toBe('Xin ch');
    expect(stream.push('ào bạn')).toBe('ào bạn');
    expect(stream.isClosed).toBe(false);
  });

  it('nhỏ từng ký tự vẫn ra đúng nguyên văn', () => {
    const stream = new CoachJsonFieldStream('reply');
    const out = drip(stream, '{"reply":"Hôm nay thế nào?","kind":"ask"}');

    expect(out).toBe('Hôm nay thế nào?');
    expect(stream.isClosed).toBe(true);
  });

  it('KHÔNG đoán khi buffer đứt giữa một escape', () => {
    const stream = new CoachJsonFieldStream('reply');

    // Dấu \ lửng: có thể thành \" (dấu nháy) hoặc \\ (gạch chéo). Đoán là hỏng chữ.
    expect(stream.push('{"reply":"anh ấy nói \\')).toBe('anh ấy nói ');
    expect(stream.push('"ừ\\" rồi đi')).toBe('"ừ" rồi đi');
  });

  it('giải mã \\n và \\uXXXX, và chờ đủ bốn chữ số hex', () => {
    const stream = new CoachJsonFieldStream('reply');

    expect(stream.push('{"reply":"dòng một\\nd')).toBe('dòng một\nd');
    expect(stream.push('òng hai \\u00')).toBe('òng hai ');
    expect(stream.push('e9')).toBe('é');
  });

  it('đóng lại ở dấu nháy cuối và câm với mọi thứ sau đó', () => {
    const stream = new CoachJsonFieldStream('reply');

    expect(stream.push('{"reply":"xong","kind":"tell"}')).toBe('xong');
    expect(stream.isClosed).toBe(true);
    expect(stream.push('{"more":"bỏ qua"}')).toBe('');
  });

  it('không nhầm khi tên trường xuất hiện bên trong một câu', () => {
    const stream = new CoachJsonFieldStream('prompt');
    const out = stream.push(
      '{"other":"chữ prompt nằm trong câu này","prompt":"cảnh thật"}',
    );

    expect(out).toBe('cảnh thật');
  });

  it('chưa thấy trường thì không nhả gì', () => {
    const stream = new CoachJsonFieldStream('prompt');

    expect(stream.push('{"samples":["a","b"],')).toBe('');
    expect(stream.isOpen).toBe(false);
  });
});

describe('CoachSentenceHold', () => {
  it('giữ lại câu cuối — đây là lý do cả tính năng này tồn tại', () => {
    const hold = new CoachSentenceHold();

    // Câu hai đã trọn, nhưng chưa có gì sau nó: nó có thể là câu chốt.
    expect(hold.push('Mình hiểu rồi. Bạn kể tiếp đi.')).toBe('Mình hiểu rồi.');
    expect(hold.pending).toBe(' Bạn kể tiếp đi.');
  });

  it('câu nào có chữ đứng sau thì chắc chắn không phải câu chốt — thả ra', () => {
    const hold = new CoachSentenceHold();
    hold.push('Một. Hai. Ba');

    expect(hold.pending).toBe(' Ba');
  });

  it('chưa hết câu đầu thì chưa thả gì', () => {
    const hold = new CoachSentenceHold();

    expect(hold.push('Mình đang nghe')).toBe('');
    expect(hold.pending).toBe('Mình đang nghe');
  });

  it('ghép lại đúng nguyên văn, không mất và không thừa ký tự', () => {
    const reply = 'Nghe mệt thật. Sáng nay có chuyện gì trước đó không?';
    const hold = new CoachSentenceHold();
    const streamed = drip(hold, reply);

    expect(streamed + hold.flush()).toBe(reply);
  });

  it('câu hỏi cấm nằm trọn trong phần bị giữ, không rò ra ngoài', () => {
    const hold = new CoachSentenceHold();
    const streamed = drip(
      hold,
      'Bạn đã cố rồi. Điều đó có ý nghĩa gì với bạn?',
    );

    expect(streamed).not.toContain('ý nghĩa gì');
    expect(hold.pending).toContain('Điều đó có ý nghĩa gì với bạn?');
  });

  it('dấu chấm trong số thập phân không bị tính là hết câu', () => {
    const hold = new CoachSentenceHold();
    hold.push('Bạn ngủ 6.5 tiếng. Vậy là ít hơn hôm qua');

    expect(hold.pending).toBe(' Vậy là ít hơn hôm qua');
  });

  it('tiếng Trung/Nhật viết không khoảng trắng vẫn tách được câu', () => {
    const hold = new CoachSentenceHold();
    hold.push('我明白了。你继续说。还有别的吗');

    expect(hold.pending).toBe('还有别的吗');
  });

  it('flush trả nốt phần giữ và dọn sạch', () => {
    const hold = new CoachSentenceHold();
    hold.push('Xong rồi.');

    expect(hold.flush()).toBe('Xong rồi.');
    expect(hold.pending).toBe('');
  });
});
