/**
 * Cây nội dung dùng để seed: Skillset → Course → Lesson → Keypoint.
 *
 * Chỉ mang tiếng Việt (`...Vi`). Builder mới là chỗ bọc thành `ITranslation`
 * của app — tách vậy để file nội dung người biên tập đọc/sửa gọn hơn.
 */

export interface CurriculumKeypoint {
  titleVi: string;
  descriptionVi: string;
  /** id thực thể trong vn_history_seed.json, dùng để đối chiếu, không bắt buộc. */
  entityIds?: string[];
  /** Ảnh minh hoạ public-domain (https). Chỉ builder dùng `image`; các trường sau để kiểm tra nguồn. */
  image?: string;
  imageFile?: string;
  imageLicense?: string;
  imageSource?: string;
  imageAuthor?: string;
}

export interface CurriculumLesson {
  titleVi: string;
  descriptionVi: string;
  keypoints: CurriculumKeypoint[];
}

export interface CurriculumCourse {
  titleVi: string;
  descriptionVi: string;
  lessons: CurriculumLesson[];
}

export interface CurriculumSkillset {
  /** khớp `periods[].id` trong vn_history_seed.json */
  periodId: string;
  courses: CurriculumCourse[];
}

export interface CurriculumFile {
  skillsets: CurriculumSkillset[];
}
