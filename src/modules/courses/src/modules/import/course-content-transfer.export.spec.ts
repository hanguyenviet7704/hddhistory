import mongoose from 'mongoose';

import { CourseContentTransferService } from './course-content-transfer.service';

// `createMultiSheetTemplateWorkbook` dùng `import ExcelJS from 'exceljs'`
// (default import) — tsconfig.json (cái ts-jest đọc) không bật
// esModuleInterop trong khi tsconfig.build.json thì có, nên dưới jest
// `ExcelJS` là undefined và `new ExcelJS.Workbook()` nổ. Test này không quan
// tâm workbook thật được dựng ra sao — chỉ cần soi ĐÚNG đối số được truyền
// vào `buildCourseExportSheets`, nên mock hàm này để bỏ qua cả cụm ExcelJS.
// Xem thêm `hddhistory-api-build-gate-is-stricter-than-tsc` (memory).
jest.mock('./excel-import.util', () => ({
  ...jest.requireActual('./excel-import.util'),
  createMultiSheetTemplateWorkbook: jest.fn().mockResolvedValue(Buffer.from('')),
}));

/**
 * Production 2026-09-10: export theo TAG (`exportCourseAtVersion`) ném
 * "Cannot read properties of undefined (reading 'toString')" — một 500 thô,
 * không liên quan gì tới Drive.
 *
 * Root cause: `courseRepository.findById` trả về một MONGOOSE DOCUMENT thật
 * (không `.lean()`), và `{ ...liveCourse, ...frozenCourse }` SPREAD một
 * Document không sao chép được field nào — Mongoose lộ `_id`/`title`/... qua
 * getter trên prototype, còn spread chỉ lấy own-enumerable-property, nên kết
 * quả chỉ có `$__`/`_doc` nội bộ. `courseDoc._id` thành `undefined`, và
 * `buildCourseExportSheets` gọi `course._id.toString()` không có guard.
 *
 * Test này dựng một Mongoose Document THẬT (không chạm DB — `new Model()`),
 * y hệt những gì `courseRepository.findById` trả về, để chứng minh đúng cơ
 * chế lỗi chứ không phải một mock đã giả định sẵn hình dạng đúng.
 */
const CourseSchema = new mongoose.Schema({
  title: mongoose.Schema.Types.Mixed,
  description: mongoose.Schema.Types.Mixed,
  image: String,
  currentVersionId: String,
});
const TestCourseModel =
  (mongoose.models.__TestCourseForExportSpec as mongoose.Model<any>) ??
  mongoose.model('__TestCourseForExportSpec', CourseSchema);

const realMongooseCourseDocument = () =>
  new TestCourseModel({
    title: { vi: 'Bản sống', en: 'Live' },
    description: { vi: 'Mô tả sống' },
    image: 'live.png',
  });

function makeService() {
  const liveCourse = realMongooseCourseDocument();
  const courseId = String(liveCourse._id);

  const courseRepository = {
    findById: jest.fn().mockResolvedValue(liveCourse),
  };
  const publishedContentRepository = {
    findEntity: jest.fn().mockResolvedValue({
      title: { vi: 'Bản đóng băng', en: 'Frozen' },
      description: { vi: 'Mô tả đóng băng' },
      image: 'frozen.png',
    }),
    findAllOfType: jest.fn().mockResolvedValue([]),
  };
  const contentSource = {
    getRoadmap: jest.fn().mockResolvedValue(null),
    getLessonsByCourse: jest.fn().mockResolvedValue([]),
    getKeypointsByIds: jest.fn().mockResolvedValue([]),
    getLearningItemsByKeypointIds: jest.fn().mockResolvedValue([]),
  };
  const courseService = {
    buildCourseExportSheets: jest.fn().mockResolvedValue([
      { sheetName: 'courses', headers: [], sampleRows: [] },
      { sheetName: 'roadmap_levels', headers: [], sampleRows: [] },
      { sheetName: 'roadmap_nodes', headers: [], sampleRows: [] },
    ]),
  };
  const lessonService = {
    buildLessonExportSheet: jest
      .fn()
      .mockResolvedValue({ sheetName: 'lessons', headers: [], sampleRows: [] }),
  };
  const keypointService = {
    buildKeypointExportSheet: jest
      .fn()
      .mockResolvedValue({ sheetName: 'keypoints', headers: [], sampleRows: [] }),
  };
  const learningItemService = {
    buildTheoryExportSheets: jest.fn().mockResolvedValue([]),
    buildExerciseExportSheets: jest.fn().mockResolvedValue([]),
  };
  const courseVersionService = {
    versionOverview: jest.fn().mockResolvedValue({
      liveTag: 'v1.0.0',
      contentTag: 'v1.0.0',
      history: [],
    }),
  };

  const service = new CourseContentTransferService(
    courseService as any,
    lessonService as any,
    keypointService as any,
    learningItemService as any,
    {} as any, // lessonRepository — không dùng ở đường tag
    courseRepository as any,
    contentSource as any,
    publishedContentRepository as any,
    courseVersionService as any,
  );

  return { service, courseId, courseService };
}

describe('CourseContentTransferService.exportCourseFull — đường TAG', () => {
  it('courseDoc truyền vào buildCourseExportSheets phải còn _id', async () => {
    const { service, courseId, courseService } = makeService();

    await service.exportCourseFull(courseId, 'v1');

    const [{ courses }] = courseService.buildCourseExportSheets.mock.calls[0].slice(1);
    expect(courses[0]._id).toBeDefined();
    expect(() => courses[0]._id.toString()).not.toThrow();
    expect(String(courses[0]._id)).toBe(courseId);
  });

  it('field đóng băng (title/description) vẫn đè lên được, không bị mất khi giữ _id', async () => {
    const { service, courseId, courseService } = makeService();

    await service.exportCourseFull(courseId, 'v1');

    const [{ courses }] = courseService.buildCourseExportSheets.mock.calls[0].slice(1);
    expect(courses[0].title).toEqual({ vi: 'Bản đóng băng', en: 'Frozen' });
    expect(courses[0].image).toBe('frozen.png');
  });
});
