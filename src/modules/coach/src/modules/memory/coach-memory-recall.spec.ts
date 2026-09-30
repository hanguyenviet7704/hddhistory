import { looksLikeRecallQuestion, recallKeywords } from './coach-memory-recall';

/**
 * Cái giá của bắt oan ở đây không phải sai kết quả mà là một query + sáu dòng
 * log thô nhét vào prompt của một lượt KỂ bình thường. Nên bộ test này phần lớn
 * là các câu KHÔNG được khớp.
 */
describe('looksLikeRecallQuestion', () => {
  it('khớp câu hỏi thẳng về quá khứ', () => {
    expect(looksLikeRecallQuestion('còn nhớ chuyện họp hôm trước không')).toBe(true);
    expect(looksLikeRecallQuestion('bạn nhớ không?')).toBe(true);
    expect(looksLikeRecallQuestion('mình từng kể về ông trưởng phòng rồi mà')).toBe(true);
    expect(looksLikeRecallQuestion('hôm trước tôi kể gì ấy nhỉ')).toBe(true);
    expect(looksLikeRecallQuestion('bạn biết gì về mình')).toBe(true);
    expect(looksLikeRecallQuestion('do you remember what I said')).toBe(true);
  });

  it('mốc thời gian chỉ tính khi có dấu hỏi — nhắc mốc là kể, không phải hỏi', () => {
    expect(looksLikeRecallQuestion('hôm trước tôi đi ăn với nó')).toBe(false);
    expect(looksLikeRecallQuestion('lần trước nó cũng làm thế')).toBe(false);
    expect(looksLikeRecallQuestion('hôm trước mình bảo gì với nó ấy?')).toBe(true);
  });

  it('không bắt oan mấy chữ đã từng làm regex của Coach sai', () => {
    // Bẫy thật của `routeHub`: regex không neo khớp vào giữa từ.
    expect(looksLikeRecallQuestion('trong trường hợp này thì sao')).toBe(false);
    expect(looksLikeRecallQuestion('mình không tập trung được')).toBe(false);
    expect(looksLikeRecallQuestion('tôi nói với nó là thôi đi')).toBe(false);
    expect(looksLikeRecallQuestion('em cần nhớ lịch họp')).toBe(false);
    expect(looksLikeRecallQuestion('')).toBe(false);
    expect(looksLikeRecallQuestion(null)).toBe(false);
  });
});

describe('recallKeywords', () => {
  it('bỏ hư từ và chính mấy chữ dùng để nhận ra câu hỏi', () => {
    expect(recallKeywords('còn nhớ mình từng kể về ông trưởng phòng không')).toEqual([
      'ông',
      'trưởng',
      'phòng',
    ]);
  });

  it('không trùng lặp, và cắt theo hạn', () => {
    expect(
      recallKeywords('họp họp họp deadline lương thưởng đồng nghiệp', 3),
    ).toEqual(['họp', 'deadline', 'lương']);
  });

  it('câu chỉ có hư từ thì không có từ khoá nào — chỗ gọi phải chịu được rỗng', () => {
    expect(recallKeywords('còn nhớ không')).toEqual([]);
  });
});
