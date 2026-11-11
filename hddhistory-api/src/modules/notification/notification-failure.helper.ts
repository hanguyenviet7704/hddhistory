/**
 * Vì sao FCM từ chối, gói lại thành một dòng đọc được.
 *
 * `FirebaseService.sendToTokens` trả về mã lỗi của TỪNG token — nó có sẵn, và
 * còn được log ở mức error kèm câu giải thích của Firebase. Nhưng cả ba chỗ ghi
 * bản ghi gửi (campaign + hai nhánh của dispatch) đều bỏ qua mảng đó và ghi
 * đúng một hằng chuỗi `'all tokens failed'`.
 *
 * Hậu quả thấy trên bảng log của admin: 2235 dòng lỗi, dòng nào cũng ghi y hệt
 * một câu, không phân biệt nổi
 *
 *   - `messaging/registration-token-not-registered` — token chết, user gỡ app
 *     hoặc cài lại; chuyện bình thường, tự dọn được;
 *   - `messaging/third-party-auth-error` — khoá APNs chưa cấu hình cho bundle;
 *   - `messaging/mismatched-credential` — service account của server không cùng
 *     project Firebase với app.
 *
 * Ba thứ đó cần ba cách xử lý khác hẳn nhau, và cái hằng chuỗi kia giấu sạch.
 *
 * Gộp theo mã và đếm, nhiều nhất trước. Rơi về câu cũ khi không có mã nào —
 * trường hợp đó là thất bại KHÔNG do FCM trả lời (không token nào để gửi), giữ
 * nguyên chữ cũ cho khỏi đọc ra thành một lỗi mới.
 */
export function describeSendFailure(failures: string[] | undefined): string {
  const counts = new Map<string, number>();
  for (const code of failures ?? []) {
    if (!code) continue;
    counts.set(code, (counts.get(code) ?? 0) + 1);
  }
  if (counts.size === 0) return 'all tokens failed';

  return [...counts.entries()]
    .sort((left, right) => right[1] - left[1])
    .map(([code, count]) => (count > 1 ? `${code} ×${count}` : code))
    .join(', ');
}
