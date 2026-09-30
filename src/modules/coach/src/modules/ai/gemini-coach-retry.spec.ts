import { Configuration } from '@base/config/configuration';

import { CoachAiError } from './coach-ai.types';
import { GeminiCoachService } from './gemini-coach.service';
import { withCoachDeadline } from '../../shared/coach-deadline';
import { withCoachStream } from '../../shared/coach-stream';
import { CoachAiUsageService } from '../ai-usage/coach-ai-usage.service';
import { CoachConfigService } from '../config/coach-config.service';

/**
 * Hai chuyện mà `tsc`, `nest build` và cả mắt người đọc diff đều không thấy —
 * thêm 2026-09-16.
 *
 * 1. Mọi lỗi phải được GHI. Trước đó chỉ những lệnh gọi đã có 2xx mới vào sổ,
 *    nên timeout và 429/503 không nằm ở đâu cả: báo cáo chi phí hiện
 *    `failedCalls: 0` suốt 8.955 lệnh gọi trong khi từng lượt một đang chết câm.
 * 2. Retry phải BIẾT ĐIỀU. 503 là "model đang đầy" nên thử lại một lần là đúng;
 *    429 xin chờ 23 giây thì thử lại là sai — không ai giữ màn hình chat mở lâu
 *    thế, và chờ xong vẫn kịp bị cắt bởi ngân sách của lượt.
 */
const okBody = {
  candidates: [{ content: { parts: [{ text: '{"level":"none"}' }] } }],
  usageMetadata: { promptTokenCount: 10, candidatesTokenCount: 2 },
};

function jsonResponse(body: unknown, status = 200): Response {
  return {
    ok: status >= 200 && status < 300,
    status,
    json: async () => body,
    text: async () => JSON.stringify(body),
  } as unknown as Response;
}

function refusal(status: number, message: string): Response {
  return {
    ok: false,
    status,
    json: async () => ({ error: { message } }),
    text: async () => JSON.stringify({ error: { code: status, message } }),
  } as unknown as Response;
}

describe('GeminiCoachService · retry và sổ lỗi', () => {
  let service: GeminiCoachService;
  let recorded: any[];
  let fetchMock: jest.Mock;

  /** Dòng coach-config admin đang sửa được, cho các ca đổi chuỗi model. */
  let configRow: Record<string, unknown>;

  /** Model id của từng lệnh gọi, đọc ra từ URL — thứ tự chuỗi nằm ở đây. */
  const modelsCalled = () =>
    fetchMock.mock.calls.map(
      call => String(call[0]).split('/models/')[1]?.split(':')[0],
    );

  beforeEach(() => {
    recorded = [];
    const usage = {
      record: (row: any) => recorded.push(row),
    } as unknown as CoachAiUsageService;
    const configuration = {
      getGeminiApiKey: 'test-key',
      getGeminiModel: 'gemini-3.7-flash',
      getGeminiSceneModel: '',
    } as unknown as Configuration;
    configRow = {};
    const coachConfig = {
      get: async () => configRow,
    } as unknown as CoachConfigService;

    service = new GeminiCoachService(configuration, usage, coachConfig);
    fetchMock = jest.fn();
    global.fetch = fetchMock as unknown as typeof fetch;
  });

  it('503 — sang model khác NGAY, và cả hai lần đều vào sổ', async () => {
    fetchMock
      .mockResolvedValueOnce(refusal(503, 'model is overloaded'))
      .mockResolvedValueOnce(jsonResponse(okBody));

    const verdict = await service.classifyRisk('hôm nay mệt', 'vi');

    expect(verdict.risk).toBe(false);
    expect(fetchMock).toHaveBeenCalledTimes(2);
    // Lần hai KHÔNG phải model vừa báo đầy — đó là điểm khác với bản cũ.
    expect(modelsCalled()).toEqual([
      'gemini-flash-lite-latest',
      'gemini-flash-latest',
    ]);
    expect(recorded.map(row => row.errorCode)).toEqual(['503', null]);
    // Lần bị từ chối không tốn token, nhưng vẫn phải là một dòng ok:false —
    // nó là một người đọc nhìn ba chấm rồi không nhận được gì.
    expect(recorded[0]).toMatchObject({ ok: false, inputTokens: 0 });
  });

  it('503 ở MỌI model trong chuỗi — chịu thua, không quay vòng', async () => {
    fetchMock.mockResolvedValue(refusal(503, 'model is overloaded'));

    await expect(service.classifyRisk('x', 'vi')).rejects.toBeInstanceOf(
      CoachAiError,
    );
    // Chuỗi mặc định của cú phân loại: model lite của chính nó, rồi
    // gemini-flash-latest (bản lite trong danh sách dự phòng trùng đầu chuỗi
    // nên bị loại). Model cuối được thử lại đúng một lần như trước.
    expect(modelsCalled()).toEqual([
      'gemini-flash-lite-latest',
      'gemini-flash-latest',
      'gemini-flash-latest',
    ]);
    expect(recorded).toHaveLength(3);
  });

  it('429 xin chờ 23 giây — không chờ, nhưng sang model khác NGAY', async () => {
    fetchMock
      .mockResolvedValueOnce(
        refusal(429, 'Quota exceeded. Please retry in 23.610698153s.'),
      )
      .mockResolvedValueOnce(jsonResponse(okBody));

    await service.classifyRisk('x', 'vi');

    // Điều cấm vẫn là CHỜ 23 giây, không phải thử lại: hop sang model khác
    // tốn 0 giây của người đọc, nên đây đúng là lúc đáng hop nhất.
    expect(modelsCalled()).toEqual([
      'gemini-flash-lite-latest',
      'gemini-flash-latest',
    ]);
    expect(recorded[0].errorCode).toBe('429');
  });

  it('429 xin chờ 23 giây mà hết model để sang — chịu thua, không ai chờ lâu thế', async () => {
    configRow = { geminiFallbackModels: 'off' };
    fetchMock.mockResolvedValue(
      refusal(429, 'Quota exceeded. Please retry in 23.610698153s.'),
    );

    await expect(service.classifyRisk('x', 'vi')).rejects.toBeInstanceOf(
      CoachAiError,
    );
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(recorded[0].errorCode).toBe('429');
  });

  it('429 xin chờ 1 giây — chờ đúng chừng đó rồi thử lại', async () => {
    fetchMock
      .mockResolvedValueOnce(refusal(429, 'Please retry in 1s.'))
      .mockResolvedValueOnce(jsonResponse(okBody));

    await service.classifyRisk('x', 'vi');

    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it('400 là lỗi của mình, không phải provider bận — thử lại chỉ tổ tốn giây', async () => {
    fetchMock.mockResolvedValue(refusal(400, 'Invalid argument'));

    await expect(service.classifyRisk('x', 'vi')).rejects.toBeInstanceOf(
      CoachAiError,
    );
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('ngân sách của lượt đã cạn — không quay số nữa, và nói rõ vì sao', async () => {
    fetchMock.mockResolvedValue(jsonResponse(okBody));

    await withCoachDeadline(0, async () => {
      await expect(service.classifyRisk('x', 'vi')).rejects.toBeInstanceOf(
        CoachAiError,
      );
    });

    expect(fetchMock).not.toHaveBeenCalled();
    expect(recorded[0].errorCode).toBe('budget_spent');
  });

  it('câu trả lời rỗng vì cụt token được ghi RIÊNG — đó là lỗi trần, sửa được', async () => {
    fetchMock.mockResolvedValue(
      jsonResponse({
        candidates: [{ finishReason: 'MAX_TOKENS', content: { parts: [] } }],
        usageMetadata: { promptTokenCount: 10, candidatesTokenCount: 300 },
      }),
    );

    await expect(service.classifyRisk('x', 'vi')).rejects.toBeInstanceOf(
      CoachAiError,
    );
    expect(recorded[0]).toMatchObject({
      ok: false,
      errorCode: 'max_tokens',
      // Cụt token thì VẪN bị tính tiền — đây là loại lỗi tốn kém nhất.
      inputTokens: 10,
    });
  });

  it('model không hiểu thinkingConfig — bỏ nó ra, gọi lại NGAY, không chờ', async () => {
    fetchMock
      .mockResolvedValueOnce(
        refusal(400, 'Unknown name "thinkingLevel" at generation_config'),
      )
      .mockResolvedValueOnce(jsonResponse(okBody));

    const verdict = await service.classifyRisk('x', 'vi');

    expect(verdict.level).toBe('none');
    expect(fetchMock).toHaveBeenCalledTimes(2);
    // Lần hai không được mang theo cái mà model vừa từ chối.
    const retryBody = JSON.parse(fetchMock.mock.calls[1][1].body);
    expect(retryBody.generationConfig.thinkingConfig).toBeUndefined();
  });

  it('400 vì thinking hai lần liên tiếp thì thôi — không quay vòng vô hạn', async () => {
    fetchMock.mockResolvedValue(
      refusal(400, 'Unknown name "thinkingLevel" at generation_config'),
    );

    await expect(service.classifyRisk('x', 'vi')).rejects.toBeInstanceOf(
      CoachAiError,
    );
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it('chuỗi dự phòng của admin thắng mặc định, và không lặp lại model đầu', async () => {
    configRow = {
      geminiFallbackModels:
        ' gemini-flash-lite-latest , gemini-3.7-flash ,, gemini-flash-latest ',
    };
    fetchMock
      .mockResolvedValueOnce(refusal(503, 'overloaded'))
      .mockResolvedValueOnce(jsonResponse(okBody));

    await service.classifyRisk('x', 'vi');

    // Dấu cách thừa bị cắt, ô rỗng bị bỏ, và model đầu chuỗi (chính là model
    // lite của cú phân loại) không được xếp hàng lần thứ hai.
    expect(modelsCalled()).toEqual([
      'gemini-flash-lite-latest',
      'gemini-3.7-flash',
    ]);
  });

  it('admin gõ "off" — không sang model khác, quay lại đúng nếp cũ', async () => {
    configRow = { geminiFallbackModels: 'off' };
    fetchMock
      .mockResolvedValueOnce(refusal(503, 'overloaded'))
      .mockResolvedValueOnce(jsonResponse(okBody));

    await service.classifyRisk('x', 'vi');

    // Vẫn thử lại một lần — nhưng trên CHÍNH model vừa báo đầy.
    expect(modelsCalled()).toEqual([
      'gemini-flash-lite-latest',
      'gemini-flash-lite-latest',
    ]);
  });

  it('400 không phải "đang bận" — không đổi model, chỉ tổ tốn giây của người đọc', async () => {
    fetchMock.mockResolvedValue(refusal(400, 'Invalid argument'));

    await expect(service.classifyRisk('x', 'vi')).rejects.toBeInstanceOf(
      CoachAiError,
    );
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('lượt sắp hết giờ — thà trả câu cố định ngay còn hơn quay số model khác', async () => {
    fetchMock.mockResolvedValue(refusal(503, 'overloaded'));

    // Đủ cho MỘT lệnh gọi (>= 2,5s) nhưng không đủ chỗ cho một lệnh trọn vẹn
    // nữa (> 3s), nên không hop và cũng không chờ để thử lại.
    await withCoachDeadline(2_800, async () => {
      await expect(service.classifyRisk('x', 'vi')).rejects.toBeInstanceOf(
        CoachAiError,
      );
    });

    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('cú hội thoại xin mức nghĩ thấp; cú viết cảnh thì không', async () => {
    fetchMock.mockResolvedValue(jsonResponse(okBody));
    await service.classifyRisk('x', 'vi');

    const body = JSON.parse(fetchMock.mock.calls[0][1].body);
    expect(body.generationConfig.thinkingConfig).toEqual({
      thinkingLevel: 'low',
    });
  });
});

/**
 * Cả đường ống xem trước, ráp lại: SSE -> bóc trường -> giữ câu cuối -> kênh.
 *
 * Ba mảnh đã có spec riêng; cái đáng sợ nằm ở chỗ nối chúng, và ở chỗ chỉ bật
 * khi ĐÚNG hai điều kiện — người gọi xin stream, và có ai đó đang xem.
 */
describe('GeminiCoachService · xem trước khi đang viết', () => {
  const CHUNKS = [
    '{"kind":"tell","reply":"Nghe mệt th',
    'ật. Sáng nay có chuy',
    'ện gì trước đó không?"}',
  ];

  function sseResponse(pieces: string[]): Response {
    const lines = pieces.map(
      text =>
        `data: ${JSON.stringify({
          candidates: [{ content: { parts: [{ text }] } }],
        })}\n\n`,
    );
    lines.push(
      `data: ${JSON.stringify({
        candidates: [{ finishReason: 'STOP' }],
        usageMetadata: { promptTokenCount: 40, candidatesTokenCount: 12 },
      })}\n\n`,
    );

    return {
      ok: true,
      status: 200,
      body: (async function* () {
        const encoder = new TextEncoder();
        for (const line of lines) yield encoder.encode(line);
      })(),
    } as unknown as Response;
  }

  let service: GeminiCoachService;
  let recorded: any[];
  let fetchMock: jest.Mock;

  beforeEach(() => {
    recorded = [];
    service = new GeminiCoachService(
      {
        getGeminiApiKey: 'k',
        getGeminiModel: 'gemini-3.7-flash',
        getGeminiSceneModel: '',
      } as unknown as Configuration,
      { record: (r: any) => recorded.push(r) } as unknown as CoachAiUsageService,
      { get: async () => ({}) } as unknown as CoachConfigService,
    );
    fetchMock = jest.fn().mockResolvedValue(sseResponse(CHUNKS));
    global.fetch = fetchMock as unknown as typeof fetch;
  });

  const context = {
    locale: 'vi',
    step: 'storyTalk',
    persona: 'friend',
    script: null,
    transcript: [],
    input: 'mệt quá',
  } as any;

  it('có người xem thì gọi streamGenerateContent và nhả chữ dần', async () => {
    const seen: string[] = [];
    const result = await withCoachStream(
      { push: (delta: string) => seen.push(delta) },
      () => service.talkStory(context),
    );

    expect(fetchMock.mock.calls[0][0]).toContain('streamGenerateContent?alt=sse');
    expect(seen.length).toBeGreaterThan(0);
    // Câu trả lời đầy đủ vẫn về nguyên vẹn qua đường thường.
    expect(result.reply).toBe('Nghe mệt thật. Sáng nay có chuyện gì trước đó không?');
    expect(recorded[0]).toMatchObject({ ok: true, inputTokens: 40 });
  });

  it('CÂU HỎI CUỐI không bao giờ lọt ra kênh — chốt câu cấm còn chưa phán', async () => {
    const seen: string[] = [];
    await withCoachStream(
      { push: (delta: string) => seen.push(delta) },
      () => service.talkStory(context),
    );

    const shown = seen.join('');
    expect(shown).toContain('Nghe mệt thật.');
    expect(shown).not.toContain('chuyện gì trước đó');
  });

  it('không ai xem thì đi đường cũ, từng byte y như trước', async () => {
    fetchMock.mockResolvedValue(
      jsonResponse({
        candidates: [{ content: { parts: [{ text: '{"kind":"tell","reply":"ừ"}' }] } }],
        usageMetadata: { promptTokenCount: 1, candidatesTokenCount: 1 },
      }),
    );

    const result = await service.talkStory(context);

    expect(fetchMock.mock.calls[0][0]).toContain(':generateContent');
    expect(fetchMock.mock.calls[0][0]).not.toContain('stream');
    expect(result.reply).toBe('ừ');
  });

  it('luồng đứt giữa chừng: giữ phần đã về, KHÔNG ném lỗi ra ngoài', async () => {
    fetchMock.mockResolvedValue({
      ok: true,
      status: 200,
      body: (async function* () {
        const encoder = new TextEncoder();
        yield encoder.encode(
          `data: ${JSON.stringify({
            candidates: [{ content: { parts: [{ text: '{"kind":"tell","reply":"nửa chừng' }] } }],
          })}\n\n`,
        );
        throw new Error('socket hangup');
      })(),
    } as unknown as Response);

    // JSON dở dang không parse được -> lỗi có kiểm soát, không phải lỗi socket
    // thoát ra ngoài rồi lọt vào nhánh retry và gõ lại câu trả lời lần hai.
    await expect(
      withCoachStream({ push: () => undefined }, () => service.talkStory(context)),
    ).rejects.toBeInstanceOf(CoachAiError);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });
});

/**
 * Sinh cảnh hai pha — thêm 2026-09-16.
 *
 * Cảnh là cú chờ dài nhất trong cả tính năng (đo trên dev: TB 6.950ms, đỉnh
 * 13.968ms), và 39% đầu ra của nó là ba trường người đọc CHƯA cần lúc mở. Tách
 * ra thì cú đầu nhẹ đi chừng ấy.
 *
 * Cái dễ hỏng âm thầm: schema bỏ trường đi nhưng PROMPT vẫn dặn model viết
 * chúng. Lúc đó model viết ra thứ schema không nhận, đầu ra không giảm, và mọi
 * lợi ích biến mất mà không có lỗi nào nổi lên. Spec này khoá cả hai đầu.
 */
describe('GeminiCoachService · sinh cảnh hai pha', () => {
  let service: GeminiCoachService;
  let fetchMock: jest.Mock;

  const sceneInput = {
    locale: 'vi',
    variant: 'default',
    habitTitle: 'Đọc lại bài trong ngày',
  } as any;

  function sceneReply(extra: Record<string, unknown> = {}) {
    return jsonResponse({
      candidates: [
        {
          content: {
            parts: [
              {
                text: JSON.stringify({
                  prompt: 'Lớp vừa tan, vở vẫn mở. Bạn làm gì với 15 phút này?',
                  counterpart: '',
                  openingOptions: [
                    { key: 'A', label: 'Đọc lại một lượt', text: 'Mở lại trang vừa ghi.' },
                    { key: 'B', label: 'Tự nhớ trước đã', text: 'Gấp vở, viết ý còn nhớ.' },
                  ],
                  ...extra,
                }),
              },
            ],
          },
        },
      ],
      usageMetadata: { promptTokenCount: 3000, candidatesTokenCount: 200 },
    });
  }

  beforeEach(() => {
    service = new GeminiCoachService(
      {
        getGeminiApiKey: 'k',
        getGeminiModel: 'gemini-3.7-flash',
        getGeminiSceneModel: '',
      } as unknown as Configuration,
      { record: () => undefined } as unknown as CoachAiUsageService,
      { get: async () => ({}) } as unknown as CoachConfigService,
    );
    fetchMock = jest.fn().mockResolvedValue(sceneReply());
    global.fetch = fetchMock as unknown as typeof fetch;
  });

  const bodyOf = (call = 0) => JSON.parse(fetchMock.mock.calls[call][1].body);

  it('pha một KHÔNG xin ba trường bị hoãn — trong schema lẫn trong prompt', async () => {
    await service.generateSituation({ ...sceneInput, openingOnly: true });

    const body = bodyOf();
    const schema = body.generationConfig.responseSchema;
    expect(Object.keys(schema.properties)).toEqual([
      'prompt',
      'counterpart',
      'openingOptions',
    ]);

    // Và prompt cũng phải im về chúng: schema bỏ mà prompt vẫn dặn thì model
    // cứ viết, đầu ra không giảm, lợi ích bay sạch mà không có lỗi nào nổi lên.
    const prompt = body.contents[0].parts[0].text;
    expect(prompt).not.toContain('"promptStage2"');
    expect(prompt).not.toContain('"takeaway"');
    expect(prompt).not.toContain('"goodMove"');
    // Chip thì PHẢI còn — nó hiện cùng lúc với câu hỏi của cảnh.
    expect(prompt).toContain('"openingOptions"');
  });

  it('`prompt` vẫn đứng đầu — đó là thứ kênh xem trước chảy về trước', async () => {
    await service.generateSituation({ ...sceneInput, openingOnly: true });

    expect(bodyOf().generationConfig.responseSchema.propertyOrdering[0]).toBe('prompt');
  });

  it('không bật cờ thì vẫn xin đủ sáu trường như cũ', async () => {
    fetchMock.mockResolvedValue(
      sceneReply({ promptStage2: 'Minh nhắn lại. Giờ bạn nói gì?', takeaway: 'x', goodMove: 'y' }),
    );
    await service.generateSituation(sceneInput);

    expect(
      Object.keys(bodyOf().generationConfig.responseSchema.properties),
    ).toContain('promptStage2');
  });

  it('pha hai chỉ xin ba trường đó, và viết TỪ cảnh đã chốt', async () => {
    fetchMock.mockResolvedValue(
      jsonResponse({
        candidates: [
          {
            content: {
              parts: [
                {
                  text: JSON.stringify({
                    promptStage2: 'Minh thả một icon cười trừ. Giờ bạn nói gì?',
                    takeaway: 'Nhắc lại đề nghị bằng một câu ngắn thì dễ được nghe hơn.',
                    goodMove: 'Mình hỏi lại một câu ngắn.',
                  }),
                },
              ],
            },
          },
        ],
        usageMetadata: { promptTokenCount: 400, candidatesTokenCount: 90 },
      }),
    );

    const rest = await service.completeSituation(sceneInput, {
      prompt: 'Lớp vừa tan, vở vẫn mở. Bạn làm gì với 15 phút này?',
      counterpart: 'Minh',
    });

    expect(Object.keys(bodyOf().generationConfig.responseSchema.properties)).toEqual([
      'promptStage2',
      'takeaway',
      'goodMove',
    ]);
    // Cảnh đã chốt phải nằm trong prompt, không thì chặng hai lạc người lạc chỗ.
    const prompt = bodyOf().contents[0].parts[0].text;
    expect(prompt).toContain('Lớp vừa tan');
    expect(prompt).toContain('Minh');
    expect(rest.promptStage2).toContain('icon cười trừ');
  });

  it('pha hai kể hộ câu trả lời thì BỎ chặng hai, không sinh lại', async () => {
    fetchMock.mockResolvedValue(
      jsonResponse({
        candidates: [
          {
            content: {
              parts: [
                {
                  text: JSON.stringify({
                    promptStage2: 'Bạn vừa nhắn hỏi Minh lấy số liệu ở đâu. Rồi sao nữa?',
                    takeaway: 'x',
                    goodMove: 'y',
                  }),
                },
              ],
            },
          },
        ],
        usageMetadata: { promptTokenCount: 400, candidatesTokenCount: 90 },
      }),
    );

    const rest = await service.completeSituation(sceneInput, {
      prompt: 'Lớp vừa tan.',
      counterpart: null,
    });

    // Cảnh đã ở trên màn hình rồi — chạy một chặng còn hơn đặt lời vào miệng họ.
    expect(rest.promptStage2).toBeNull();
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });
});
