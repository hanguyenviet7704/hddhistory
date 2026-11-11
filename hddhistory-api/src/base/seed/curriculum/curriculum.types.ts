/**
 * Cây nội dung dùng để seed: Chủ đề → Course → Lesson → Keypoint.
 *
 * Chỉ mang tiếng Việt (`...Vi`). Builder mới là chỗ bọc thành `ITranslation`
 * của app — tách vậy để file nội dung người biên tập đọc/sửa gọn hơn.
 */

export interface CurriculumKeypoint {
  titleVi: string;
  descriptionVi: string;
  /** id thực thể trong vn_history_seed.json, dùng để đối chiếu, không bắt buộc. */
  entityIds?: string[];
  /**
   * Ảnh minh hoạ từ Wikimedia Commons (https; public domain, CC0, CC BY hoặc CC BY-SA).
   * Builder dùng `image` cho khối ảnh và `imageAuthor`/`imageLicense` cho dòng ghi
   * công nằm trong `data.content` của chính khối ảnh — các trường này mang nghĩa
   * vụ pháp lý, không chỉ để kiểm tra.
   */
  image?: string;
  imageFile?: string;
  imageLicense?: string;
  imageSource?: string;
  imageAuthor?: string;
}

/** Các trường ghi công đi kèm một ảnh Wikimedia Commons. */
export type CurriculumImageMeta = Pick<
  CurriculumKeypoint,
  'imageAuthor' | 'imageLicense'
>;

export interface CurriculumLesson {
  titleVi: string;
  descriptionVi: string;
  /**
   * Ảnh bìa của bài (https, Wikimedia Commons). Có thì builder dùng cho
   * `Lesson.image` thay ảnh placeholder của thời kỳ; vắng thì giữ placeholder.
   * Cùng bộ trường ghi công với thẻ để lời ghi công đi theo ảnh.
   */
  image?: string;
  imageFile?: string;
  imageLicense?: string;
  imageSource?: string;
  imageAuthor?: string;
  keypoints: CurriculumKeypoint[];
}

export interface CurriculumCourse {
  titleVi: string;
  descriptionVi: string;
  lessons: CurriculumLesson[];
}

export interface CurriculumCategory {
  /** khớp `periods[].id` trong vn_history_seed.json */
  periodId: string;
  courses: CurriculumCourse[];
}

export interface CurriculumFile {
  categories: CurriculumCategory[];
}
