
import { CoachTurnContext } from './coach-ai.types';
import {
  buildClosingLinePrompt,
  buildLessonTalkPrompt,
  buildReflectPrompt,
  buildStoryTalkPrompt,
} from './coach-prompt';
import { CoachPersona, CoachStep } from '../../shared/coach.enum';

/**
 * Bug owner gặp 2026-09-04: Coach vừa nhắc "gõ code trên màn hình công ty" ở
 * phiên trước, rồi ngay phiên sau trả lời "mình không biết bạn làm nghề gì".
 *
 * Hai nguyên nhân, cả hai ở tầng dựng prompt: transcript chỉ trong phạm vi một
 * phiên, và profile onboarding chưa bao giờ vào prompt hội thoại (nó chỉ có ở
 * prompt sinh cảnh). Spec này khoá cả hai — build gate và tsc đều không thấy
 * được một khối prompt bị thiếu.
 */
const base: CoachTurnContext = {
  locale: 'vi',
  step: CoachStep.STORY_TALK,
  persona: CoachPersona.FRIEND,
  script: null,
  transcript: [{ role: 'user', text: 'Hôm nay mệt' }],
  input: 'Tôi làm nghề gì?',
};

describe('buildStoryTalkPrompt · ngữ cảnh về người đọc', () => {
  it('KHÔNG có khối nào khi thiếu dữ liệu — danh sách rỗng tệ hơn là không có', () => {
    const p = buildStoryTalkPrompt(base);
    expect(p).not.toContain('EARLIER conversations');
    expect(p).not.toContain('told the app when they set up');
  });

  it('đưa lời thoại các phiên TRƯỚC vào prompt, nguyên văn', () => {
    const p = buildStoryTalkPrompt({
      ...base,
      priorTranscript: [
        { role: 'coach', text: 'Hà gõ code liên tục từ sáng đến giờ à?' },
        { role: 'user', text: 'uh' },
      ],
    });
    expect(p).toContain('EARLIER conversations');
    expect(p).toContain('Hà gõ code liên tục từ sáng đến giờ à?');
    // Phải tách khỏi khối phiên hiện tại, không nhập một cục.
    expect(p).toContain('What has been said so far in this conversation');
    expect(p.indexOf('EARLIER conversations')).toBeLessThan(
      p.indexOf('What has been said so far in this conversation'),
    );
  });

  it('đưa profile onboarding vào, và nới luật cho Coach ĐƯỢC trả lời khi bị hỏi', () => {
    const p = buildStoryTalkPrompt({
      ...base,
      readerFacts: '- what they do: Văn phòng (their own words: "dev")',
    });
    expect(p).toContain('told the app when they set up');
    expect(p).toContain('Văn phòng');
    expect(p).toContain('instead of saying you do not know');
  });

  it('hai khối độc lập nhau', () => {
    const p = buildStoryTalkPrompt({
      ...base,
      priorTranscript: [{ role: 'user', text: 'chuyện cũ' }],
      readerFacts: '- what they do: Kỹ thuật',
    });
    expect(p).toContain('chuyện cũ');
    expect(p).toContain('Kỹ thuật');
  });
});

/**
 * 2026-09-17 — thẻ nhớ phải có mặt ở MỌI prompt có nói chuyện.
 *
 * Trước bản này nó chỉ ở `buildStoryTalkPrompt`, nên ngoài luồng kể chuyện thì
 * Coach thật sự không nhớ gì. Không có cổng nào khác bắt được việc một khối bị
 * rơi khỏi danh sách: `tsc` không thấy, `npm run build` không thấy, và trên
 * thiết bị thì nó chỉ là một câu trả lời nhạt hơn bình thường.
 */
describe('thẻ nhớ · có mặt ở mọi prompt có nói chuyện', () => {
  const card = 'About them:\n- Làm marketing (heard 3×)';
  const withCard: CoachTurnContext = { ...base, readerCard: card };

  it('vào prompt kể chuyện, kèm luật "để nối, không đọc lại"', () => {
    const p = buildStoryTalkPrompt(withCard);
    expect(p).toContain('Làm marketing');
    expect(p).toContain('Use it to CONNECT');
    expect(p).toContain('If today contradicts a line here, today wins');
  });

  it('vào prompt nhìn lại', () => {
    expect(buildReflectPrompt(withCard)).toContain('Làm marketing');
  });

  it('vào prompt bài học', () => {
    expect(
      buildLessonTalkPrompt(withCard, { mode: 'reply' }),
    ).toContain('Làm marketing');
  });

  it('vào prompt câu chốt', () => {
    expect(
      buildClosingLinePrompt(
        withCard,
        { context: 'khi bị ngắt lời', action: 'nói lại một câu' },
        null,
      ),
    ).toContain('Làm marketing');
  });

  it('không có thẻ thì không có khối — phiên đầu không mang bóng phiên chưa từng có', () => {
    expect(buildStoryTalkPrompt(base)).not.toContain('What you already know about this reader');
    expect(buildReflectPrompt(base)).not.toContain('What you already know about this reader');
  });
});

describe('khối tra cứu · chỉ khi user hỏi về quá khứ', () => {
  it('mang chữ nguyên văn VÀ lệnh không được bịa', () => {
    const p = buildStoryTalkPrompt({
      ...base,
      readerRecall: '- they said: hôm trước họp bị ngắt lời ba lần',
    });
    expect(p).toContain('hôm trước họp bị ngắt lời ba lần');
    // Câu quan trọng nhất của khối: hỏi về quá khứ là chỗ model bịa nhiều nhất.
    expect(p).toContain('say honestly that you do not remember it clearly');
    expect(p).toContain('Never invent a detail about their life');
  });

  it('lượt bình thường thì không có khối nào', () => {
    expect(buildStoryTalkPrompt(base)).not.toContain('asking you about their own past');
  });
});
