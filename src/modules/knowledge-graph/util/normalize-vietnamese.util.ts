/**
 * Bỏ dấu tiếng Việt, hạ chữ thường, gom khoảng trắng — để người dùng gõ
 * "tran hung dao" vẫn tìm ra "Trần Hưng Đạo".
 *
 * Chữ đ/Đ phải xử lý riêng: chúng là ký tự Latin mở rộng độc lập, không phân
 * rã thành "d + dấu gạch" qua NFD như các nguyên âm có dấu, nên nếu chỉ dùng
 * normalize('NFD') thì "Đạo" sẽ ra "Đao" chứ không phải "dao".
 */
export function normalizeVietnamese(input: string): string {
  return input
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .trim()
    .replace(/\s+/g, ' ');
}
