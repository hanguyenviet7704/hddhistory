/**
 * Câu hỏi mẫu cho trang xem thử `/luyen-tap/xem-thu`.
 *
 * Database local chưa có bài tập nào (mọi learning item đều là `theory`), nên
 * đây là JSON THÔ đúng hình dạng API trả về — theo các interface
 * `hddhistory-api/.../learning-item/interface/excercises/*.ts` — và đi qua
 * cùng `toQuestions()` như dữ liệu thật. Đáp án vị trí là chỉ số 1-based,
 * `answer[].id` của dạng sắp xếp/điền chỗ trống trùng id phương án như dữ
 * liệu admin soạn.
 */
const doc = (vi: string) => [{ id: 1, type: 'text', data: { content: { vi } } }];
const id24 = (n: number) => `65f0000000000000000000${String(n).padStart(2, '0')}`;

export const FIXTURE_QUESTIONS: unknown[] = [
  {
    id: 1,
    exerciseId: id24(1),
    type: 'single_choice',
    tagId: '',
    document: doc(
      'Ngày 2/9/1945, ai đọc bản Tuyên ngôn Độc lập tại Quảng trường Ba Đình?',
    ),
    explanation: {
      vi: 'Chủ tịch Hồ Chí Minh đọc Tuyên ngôn Độc lập, khai sinh nước Việt Nam Dân chủ Cộng hoà.',
    },
    options: [
      { value: { vi: 'Hồ Chí Minh' }, isCorrect: true },
      { value: { vi: 'Võ Nguyên Giáp' }, isCorrect: false },
      { value: { vi: 'Phạm Văn Đồng' }, isCorrect: false },
      { value: { vi: 'Trường Chinh' }, isCorrect: false },
    ],
    level: [],
    maxScore: 10,
  },
  {
    id: 2,
    exerciseId: id24(2),
    type: 'multiple_choice',
    tagId: '',
    document: doc('Những chiến dịch nào thuộc cuộc kháng chiến chống Pháp (1945–1954)?'),
    explanation: {
      vi: 'Chiến dịch Hồ Chí Minh (1975) thuộc cuộc kháng chiến chống Mỹ.',
    },
    options: [
      { value: { vi: 'Chiến dịch Việt Bắc (1947)' }, isCorrect: true },
      { value: { vi: 'Chiến dịch Biên giới (1950)' }, isCorrect: true },
      { value: { vi: 'Chiến dịch Điện Biên Phủ (1954)' }, isCorrect: true },
      { value: { vi: 'Chiến dịch Hồ Chí Minh (1975)' }, isCorrect: false },
    ],
    level: [],
    maxScore: 9,
  },
  {
    id: 3,
    exerciseId: id24(3),
    type: 'single_choice_no_correct_answer',
    tagId: '',
    document: doc('Bạn muốn tìm hiểu thêm về giai đoạn nào?'),
    explanation: { vi: '' },
    options: [
      { value: { vi: 'Thời Lý – Trần' }, documentGroupId: 'g-ly-tran' },
      { value: { vi: 'Thời cận đại' }, documentGroupId: 'g-can-dai' },
    ],
    documentGroups: [
      {
        id: 'g-ly-tran',
        documents: [
          { id: 1, type: 'title', data: { content: { vi: 'Thời Lý – Trần' } } },
          {
            id: 2,
            type: 'text',
            data: {
              content: {
                vi: 'Hơn ba thế kỷ dựng nền độc lập: dời đô về Thăng Long, ba lần thắng quân Mông Nguyên.',
              },
            },
          },
        ],
      },
      {
        id: 'g-can-dai',
        documents: [
          {
            id: 1,
            type: 'text',
            data: { content: { vi: 'Từ khi Pháp nổ súng ở Đà Nẵng (1858) tới Cách mạng tháng Tám.' } },
          },
        ],
      },
    ],
    level: [],
    maxScore: 0,
  },
  {
    id: 4,
    exerciseId: id24(4),
    type: 'drag_drop',
    form: 'Text Gap Filling',
    tagId: '',
    document: doc('Điền vào chỗ trống.'),
    explanation: { vi: 'Chiến thắng Điện Biên Phủ (7/5/1954) dẫn tới Hiệp định Giơ-ne-vơ.' },
    targetArea: { vi: 'Chiến thắng ___ năm ___ buộc Pháp ký Hiệp định Giơ-ne-vơ.' },
    answer: [
      { id: 1, correctAnswer: { vi: 'Điện Biên Phủ' } },
      { id: 2, correctAnswer: { vi: '1954' } },
    ],
    options: [
      { id: 3, text: { vi: '1975' } },
      { id: 1, text: { vi: 'Điện Biên Phủ' } },
      { id: 4, text: { vi: 'Bạch Đằng' } },
      { id: 2, text: { vi: '1954' } },
    ],
    level: [],
    maxScore: 10,
  },
  {
    id: 5,
    exerciseId: id24(5),
    type: 'drag_drop',
    form: 'Cues Placement',
    tagId: '',
    document: doc('Đặt dấu ngắt vào đúng chỗ.'),
    explanation: { vi: 'Ngắt sau tên hiệp định và sau "đất nước" để câu rõ nghĩa.' },
    targetArea: { vi: 'Hiệp định Giơ-ne-vơ chia đôi đất nước tại vĩ tuyến 17' },
    answer: [
      { id: 1, correctAnswer: { vi: '3' } },
      { id: 2, correctAnswer: { vi: '7' } },
    ],
    options: [
      { id: 1, text: { vi: '/' } },
      { id: 2, text: { vi: '/' } },
    ],
    level: [],
    maxScore: 10,
  },
  {
    id: 6,
    exerciseId: id24(6),
    type: 'drag_drop',
    form: 'Stress Placement',
    tagId: '',
    document: doc('Đánh dấu các từ khoá của câu.'),
    explanation: { vi: 'Triều đại (Trần) và đối thủ (Mông Nguyên) là hai ý chính.' },
    targetArea: { vi: 'Nhà Trần ba lần đánh thắng quân Mông Nguyên' },
    answer: [
      { id: 1, correctAnswer: { vi: '2' } },
      { id: 2, correctAnswer: { vi: '8' } },
      { id: 3, correctAnswer: { vi: '9' } },
    ],
    options: [{ id: 1, text: { vi: '•' } }],
    level: [],
    maxScore: 9,
  },
  {
    id: 7,
    exerciseId: id24(7),
    type: 'drag_drop',
    form: 'Arrange the Sequence',
    tagId: '',
    document: doc('Sắp xếp các sự kiện theo thời gian.'),
    explanation: { vi: '1945 → 1954 → 1975 → 1986.' },
    answer: [
      { id: 1, correctAnswer: { vi: 'Cách mạng tháng Tám (1945)' } },
      { id: 2, correctAnswer: { vi: 'Chiến thắng Điện Biên Phủ (1954)' } },
      { id: 3, correctAnswer: { vi: 'Giải phóng miền Nam (1975)' } },
      { id: 4, correctAnswer: { vi: 'Đổi Mới (1986)' } },
    ],
    options: [
      { id: 3, text: { vi: 'Giải phóng miền Nam (1975)' } },
      { id: 1, text: { vi: 'Cách mạng tháng Tám (1945)' } },
      { id: 4, text: { vi: 'Đổi Mới (1986)' } },
      { id: 2, text: { vi: 'Chiến thắng Điện Biên Phủ (1954)' } },
    ],
    level: [],
    maxScore: 12,
  },
  {
    id: 8,
    exerciseId: id24(8),
    type: 'record',
    tagId: '',
    document: doc('Kể lại ngắn gọn ý nghĩa của Cách mạng tháng Tám.'),
    explanation: { vi: '' },
    record: '',
    maxDuration: 60,
    scoringCriteria: [{ maxScore: 10, criteria: { vi: 'Nêu được ý nghĩa chính' } }],
    level: [],
    maxScore: 10,
  },
];

/** Câu phụ hỏi lại khi trả lời sai câu chính có `id` = `mainQuestion`. */
export const FIXTURE_SUB_QUESTIONS: unknown[] = [
  {
    id: 101,
    exerciseId: id24(11),
    mainQuestion: 1,
    type: 'single_choice',
    tagId: '',
    document: doc('Bản Tuyên ngôn Độc lập năm 1945 được đọc ở đâu?'),
    explanation: { vi: 'Quảng trường Ba Đình, Hà Nội.' },
    options: [
      { value: { vi: 'Quảng trường Ba Đình' }, isCorrect: true },
      { value: { vi: 'Dinh Độc Lập' }, isCorrect: false },
    ],
    level: [],
    maxScore: 10,
  },
  {
    id: 104,
    exerciseId: id24(14),
    mainQuestion: 4,
    type: 'drag_drop',
    form: 'Text Gap Filling',
    tagId: '',
    document: doc('Điền vào chỗ trống.'),
    explanation: { vi: 'Hiệp định Giơ-ne-vơ được ký năm 1954.' },
    targetArea: { vi: 'Hiệp định Giơ-ne-vơ được ký năm ___.' },
    answer: [{ id: 1, correctAnswer: { vi: '1954' } }],
    options: [
      { id: 1, text: { vi: '1954' } },
      { id: 2, text: { vi: '1945' } },
    ],
    level: [],
    maxScore: 10,
  },
];
