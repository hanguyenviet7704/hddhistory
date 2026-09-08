import { courseService } from "./courseService";
import axiosClient from "./axiosClient";

jest.mock("./axiosClient", () => ({
  __esModule: true,
  default: { get: jest.fn(), post: jest.fn(), put: jest.fn(), delete: jest.fn() },
}));

const mocked = axiosClient as unknown as { post: jest.Mock };

/**
 * `CourseList` gọi `syncResults.length` rồi `.map` ngay trong render. Trả cả
 * phong bì thì `.map` không tồn tại -> throw -> trắng toàn bộ trang admin.
 */
describe("courseService.syncFromDrive", () => {
  it("trả mảng kết quả, không trả phong bì", async () => {
    const results = [{ fileName: "a.xlsx", autoTaggedAs: "v1.0.1" }];
    mocked.post.mockResolvedValue({
      data: { statusCode: 201, message: "Success", data: results },
    });

    const got = await courseService.syncFromDrive(undefined, true);

    expect(Array.isArray(got)).toBe(true);
    expect(got).toEqual(results);
  });
});
