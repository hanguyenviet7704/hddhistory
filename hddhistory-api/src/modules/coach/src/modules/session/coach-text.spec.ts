import { fold, looksLikeEcho, addressVi, splitScene } from './coach-text';

describe('fold — the same sentence typed two ways', () => {
  it('ignores accents, because readers drop them and models add them', () => {
    expect(fold('Ông bán xôi chè')).toBe(fold('ong ban xoi che'));
  });

  it('handles đ by hand — NFD does not decompose it', () => {
    expect(fold('đi ngủ đủ')).toBe('di ngu du');
  });
});

describe('looksLikeEcho — replies that are just the reader read back', () => {
  // Every one of these was said to a real reader before the guard existed.
  it.each([
    ['chị tôi không uống trà sữa. Việc này làm chị thay đổi thế nào?', 'hôm nay chị tôi không uống trà sữa'],
    ['Bạn chọn cố làm xong việc rồi mới ngủ.', 'Tôi cố làm xong việc rồi mới ngủ.'],
    ['Người yêu cũ đi lấy chồng.', 'hôm nay người yêu cũ tôi đi lấy chồng'],
  ])('catches %j', (reply, input) => {
    expect(looksLikeEcho(reply, input)).toBe(true);
  });

  it('lets a real reply through even when it names what they named', () => {
    expect(
      looksLikeEcho(
        'Ngủ đủ là điều bạn đang muốn. Lúc bận rộn đó, bạn đã chọn làm việc tiếp hay đi ngủ?',
        'tôi thật sự muốn ngủ đủ nhưng mà tôi rất bận',
      ),
    ).toBe(false);
  });

  it('does not judge a line too short to be a copy of anything', () => {
    expect(looksLikeEcho('Nghe nặng.', 'hôm nay người yêu cũ tôi đi lấy chồng')).toBe(
      false,
    );
  });

  it('catches the copy even when the reader typed without accents', () => {
    expect(
      looksLikeEcho('Bạn cố làm xong việc rồi mới ngủ.', 'toi co lam xong viec roi moi ngu'),
    ).toBe(true);
  });
});

describe("addressVi — the fixed lines follow the reader's address", () => {
  it('replaces the second-person "bạn", keeping the case', () => {
    expect(addressVi('Cảm ơn bạn đã kể.', 'anh')).toBe('Cảm ơn anh đã kể.');
    expect(addressVi('Bạn vừa thêm “X”.', 'chị')).toBe('Chị vừa thêm “X”.');
    expect(addressVi('Cảm ơn bạn đã kể.', 'Hà')).toBe('Cảm ơn Hà đã kể.');
  });

  it('leaves the noun alone, and does nothing for "bạn" or no address', () => {
    expect(addressVi('Kể với bạn bè hay người bạn thân?', 'anh')).toBe('Kể với bạn bè hay người bạn thân?');
    // "bạn ấy" is he/she — the person being talked about, not the reader. Scene
    // prose says this about the other person in the moment; a fixed line never
    // does, which is why it only started mattering once scenes went through here.
    expect(addressVi('Bạn ấy nhắn lại ngay.', 'Hà')).toBe('Bạn ấy nhắn lại ngay.');
    expect(addressVi('Quân là bạn ấy à?', 'anh')).toBe('Quân là bạn ấy à?');
    // Still substituted when "ấy" belongs to the next clause, not to "bạn".
    expect(addressVi('Nam nhắn cho bạn, ấy là hôm qua.', 'Hà')).toBe('Nam nhắn cho Hà, ấy là hôm qua.');
    expect(addressVi('Cảm ơn bạn.', 'bạn')).toBe('Cảm ơn bạn.');
    expect(addressVi('Cảm ơn bạn.', null)).toBe('Cảm ơn bạn.');
    expect(addressVi('Thanks for telling me.', 'anh')).toBe('Thanks for telling me.');
  });
});

/**
 * Splitting a scene from its question.
 *
 * The failure this guards is one only a device shows: the reader saw a bubble
 * that began with a stray apostrophe — "' Bạn nói gì với Nam?" — because the
 * sentence before it ended inside a quotation and the closing mark was left to
 * open the next one. Scenes quote people in almost every scene, so it was the
 * ordinary case rather than a rare one.
 */
describe('splitScene — the question comes off the prose cleanly', () => {
  it('keeps a closing quote with the sentence it closes', () => {
    const { setup, question } = splitScene(
      "Bàn thư viện vắng, bài kiểm tra nằm trước mặt bạn. Nam kéo ghế lại bảo: 'Đề dễ mà, ngồi chữa luôn mấy câu sai với tớ đi.' Bạn nói gì với Nam?",
    );

    expect(question).toBe('Bạn nói gì với Nam?');
    expect(setup.endsWith("với tớ đi.'")).toBe(true);
  });

  it('handles the curly quotes a model actually emits', () => {
    const { setup, question } = splitScene(
      'Linh nhắn: “Mai họp sớm nhé.” Bạn trả lời thế nào?',
    );

    expect(question).toBe('Bạn trả lời thế nào?');
    expect(setup).toBe('Linh nhắn: “Mai họp sớm nhé.”');
  });

  it('splits an ordinary scene with no quotation at all', () => {
    const { setup, question } = splitScene(
      'Chín giờ tối, phòng vẫn sáng đèn. Bạn mở mục nào trước?',
    );

    expect(setup).toBe('Chín giờ tối, phòng vẫn sáng đèn.');
    expect(question).toBe('Bạn mở mục nào trước?');
  });

  it('takes the LAST question when the prose quotes one on the way', () => {
    const { setup, question } = splitScene(
      'Quân hỏi: "Đi không?" Bạn đáp lại thế nào?',
    );

    expect(question).toBe('Bạn đáp lại thế nào?');
    expect(setup).toBe('Quân hỏi: "Đi không?"');
  });

  it('gives back the whole thing when there is no question to cut', () => {
    const whole = 'Chín giờ tối, phòng vẫn sáng đèn.';

    expect(splitScene(whole)).toEqual({ setup: whole, question: null });
  });

  it('does not cut a scene that is nothing BUT its question', () => {
    // cut <= 0 — there is no prose to leave behind, so the caller shows it whole.
    expect(splitScene('Bạn nói gì với Nam?')).toEqual({
      setup: 'Bạn nói gì với Nam?',
      question: null,
    });
  });
});
