import { diffBodies } from './admin-audit.diff';

/**
 * Đây là thứ biến một trang JSON thành một câu biên tập viên đọc được, nên nó
 * phải đúng — một danh sách thay đổi SAI còn tệ hơn không có danh sách nào:
 * người ta sẽ đi sửa nhầm chỗ.
 */
describe('diffBodies', () => {
  const j = (value: unknown) => JSON.stringify(value);

  it('chỉ nêu trường THẬT SỰ đổi, không nêu cả tài liệu', () => {
    const changes = diffBodies(
      j({ enabled: true, geminiModel: 'gemini-3.7-flash', onboardAskAge: true }),
      j({ enabled: true, geminiModel: 'gemini-3.8-flash', onboardAskAge: true }),
    );

    expect(changes).toEqual([
      { field: 'geminiModel', before: 'gemini-3.7-flash', after: 'gemini-3.8-flash' },
    ]);
  });

  it('chỉ tới đúng phần tử trong mảng, không nói chung chung "mảng đổi"', () => {
    const changes = diffBodies(
      j({ hotlines: [{ number: '111' }, { number: '222' }] }),
      j({ hotlines: [{ number: '111' }, { number: '999' }] }),
    );

    expect(changes).toEqual([
      { field: 'hotlines[1].number', before: '222', after: '999' },
    ]);
  });

  it('thêm và bớt trường đều hiện ra', () => {
    const changes = diffBodies(j({ a: 1 }), j({ b: 2 }))!;

    expect(changes).toContainEqual({ field: 'a', before: 1, after: undefined });
    expect(changes).toContainEqual({ field: 'b', before: undefined, after: 2 });
  });

  it('bấm lưu mà không đổi gì thì trả MẢNG RỖNG — đó là một câu trả lời thật', () => {
    expect(diffBodies(j({ a: 1 }), j({ a: 1 }))).toEqual([]);
  });

  it('chưa có bản trước thì trả null, không phải mảng rỗng', () => {
    // Hai thứ khác nhau và giao diện nói khác nhau: "lần đầu" vs "không đổi gì".
    expect(diffBodies(null, j({ a: 1 }))).toBeNull();
  });

  it('nội dung bị CẮT thì KHÔNG so — thà im còn hơn bịa ra một loạt "đã xoá"', () => {
    expect(
      diffBodies(j({ a: 1 }), j({ a: 2 }), { beforeTruncated: true }),
    ).toBeNull();
  });

  it('JSON hỏng thì không so, chứ không ném', () => {
    expect(diffBodies('{không phải json', j({ a: 1 }))).toBeNull();
  });

  it('mảng bị xoá sạch là một thay đổi nhìn thấy được', () => {
    expect(diffBodies(j({ list: [1, 2] }), j({ list: [] }))).toEqual([
      { field: 'list', before: undefined, after: [] },
      { field: 'list[0]', before: 1, after: undefined },
      { field: 'list[1]', before: 2, after: undefined },
    ]);
  });
});
