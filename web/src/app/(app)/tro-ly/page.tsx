import { CoachChat } from '@/components/coach/coach-chat';
import { coachTeaser } from '@/components/coach/coach-copy';
import { getCoachBubble, type CoachBubble } from '@/lib/coach';

export default async function CoachPage() {
  let bubble: CoachBubble | null = null;
  try {
    bubble = await getCoachBubble();
  } catch {
    // Bong bóng chỉ là lời mời; hỏng thì vẫn cho mở trò chuyện — chính lời
    // mở phiên sẽ nói đúng chuyện gì đang xảy ra nếu Coach thật sự không chạy.
    bubble = null;
  }

  // KHÔNG chặn trang khi `visible: false`: cờ đó chỉ nói bong bóng mời ở
  // Trang chủ có hiện hay không (sau phần làm quen, kho thói quen trống là nó
  // ẩn), không phải Coach bị tắt. Coach tắt thật thì chính lời mở phiên trả
  // `silent` và `CoachChat` tự hiện trạng thái tạm nghỉ.
  // Lời hẹn của chính người đọc được ưu tiên hơn câu cố định.
  const teaser = bubble?.teaser || coachTeaser(bubble?.teaserKey);

  return (
    <div className="pt-5">
      <h1 className="text-2xl font-bold tracking-tight text-brand-900">
        HDDhistory Coach
      </h1>
      {teaser ? (
        <p className="mt-1 text-ink-muted">
          {bubble?.dot ? (
            <span
              aria-label="Có nhắc hẹn đang chờ"
              className="mr-2 inline-block size-2 rounded-full bg-red-600 align-middle"
            />
          ) : null}
          {teaser}
        </p>
      ) : null}
      <p className="mt-1 text-xs text-ink-faint">
        Mình là AI, không thay thế được chuyên gia tâm lý.
      </p>
      <CoachChat />
    </div>
  );
}
