/**
 * Biến mà một campaign gửi thủ công thay được, và cách thay.
 *
 * Tách khỏi bộ render của noti có lịch (`NotificationDispatchService.render`) vì
 * hai bên có luật KHÁC nhau ở đúng chỗ quan trọng nhất: user chưa có tên.
 * Noti có lịch có nhiều biến thể, nên bộ chọn biến thể bỏ qua wording nào dùng
 * một biến rỗng và chọn wording khác — user không tên vẫn nhận được noti, chỉ là
 * một câu khác. Campaign chỉ có MỘT wording mỗi ngôn ngữ: bỏ qua nghĩa là người
 * đó không nhận gì, mà một campaign broadcast thì con số "sẽ gửi tới N người"
 * phải đúng. Nên ở đây biến rỗng được thay bằng một từ đại từ, không phải cái cớ
 * để bỏ gửi.
 */

/** Biến duy nhất campaign hiểu. Mọi biến khác bị từ chối lúc lưu. */
export const CAMPAIGN_COPY_VARIABLES = ['user_name'];

/**
 * Từ thay cho `{user_name}` khi user chưa có tên — theo NGÔN NGỮ CỦA WORDING
 * được chọn, không theo ngôn ngữ của user: một user `vi` không có bản Việt sẽ
 * nhận bản `en`, và "for bạn" thì hỏng câu.
 */
const NAME_FALLBACK: Record<string, string> = {
  vi: 'bạn',
  en: 'you',
  zh: '你',
  ja: 'あなた',
  ko: '회원님',
};

/** Tên hiển thị của người đọc trong một wording, đã tính cả trường hợp trống. */
export function campaignReaderName(
  rawName: string | undefined | null,
  copyLocale: string,
): { value: string; isFallback: boolean } {
  const name = (rawName ?? '').trim();
  if (name) return { value: name, isFallback: false };

  const locale = (copyLocale ?? '').toLowerCase().split(/[-_]/)[0];
  return {
    value: NAME_FALLBACK[locale] ?? NAME_FALLBACK.en,
    isFallback: true,
  };
}

/**
 * Thay biến trong một câu của campaign.
 *
 * Từ thay thế được viết hoa khi nó đứng ĐẦU câu ("{user_name} ơi, ..." →
 * "Bạn ơi, ..."). Chỉ viết hoa từ dự phòng: tên thật do người dùng tự nhập, và
 * sửa chữ của họ là việc không ai nhờ.
 */
export function renderCampaignCopy(
  template: string,
  reader: { value: string; isFallback: boolean },
): string {
  if (!template) return '';

  return template.replace(/\{(\w+)\}/g, (match, key: string, offset: number) => {
    if (key !== 'user_name') return match;
    if (reader.isFallback && offset === 0) {
      return reader.value.charAt(0).toUpperCase() + reader.value.slice(1);
    }
    return reader.value;
  });
}

/**
 * Các biến trong câu mà campaign KHÔNG thay được — dùng để từ chối ngay lúc lưu.
 *
 * Không có bước này thì `{course_name}` (biến của noti có lịch, campaign không
 * có gì để điền) đi thẳng ra máy người ta dưới dạng dấu ngoặc nhọn. Đó đúng là
 * cách `{user_name}` từng lên màn hình thật.
 */
export function unknownCampaignVariables(text: string): string[] {
  const found = (text ?? '').match(/\{(\w+)\}/g) ?? [];
  return Array.from(
    new Set(
      found
        .map(token => token.slice(1, -1))
        .filter(name => !CAMPAIGN_COPY_VARIABLES.includes(name)),
    ),
  );
}
