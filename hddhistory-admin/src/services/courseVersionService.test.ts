import { courseVersionService } from "./courseVersionService";
import axiosClient from "./axiosClient";

// axios là ESM nên jest của CRA không transform được; mock hẳn module client.
jest.mock("./axiosClient", () => ({
  __esModule: true,
  default: { get: jest.fn(), post: jest.fn(), put: jest.fn(), delete: jest.fn() },
}));

const mocked = axiosClient as unknown as {
  get: jest.Mock;
  post: jest.Mock;
  put: jest.Mock;
  delete: jest.Mock;
};

/**
 * API bọc MỌI response trong `{ statusCode, message, data }` — đã probe thật
 * trên api-dev. Service trả `res.data` sẽ trả cả phong bì, và caller đọc
 * `nextTag` ra `undefined`; chỗ đó làm trắng cả trang admin.
 */
describe("courseVersionService bóc phong bì của API", () => {
  const payload = {
    versions: [],
    currentTag: null,
    nextTag: "v1.0.0",
    pending: { added: [], changed: [], removed: [], total: 0 },
  };

  beforeEach(() => jest.clearAllMocks());

  it("list trả payload, không trả phong bì", async () => {
    mocked.get.mockResolvedValue({
      data: { statusCode: 200, message: "Success", data: payload },
    });

    expect(await courseVersionService.list("c1")).toEqual(payload);
  });

  it("create trả tag vừa tạo, không trả phong bì", async () => {
    const version = { _id: "v1", tag: "v1.0.1", isCurrent: true };
    mocked.post.mockResolvedValue({
      data: { statusCode: 201, message: "Success", data: version },
    });

    expect(
      await courseVersionService.create("c1", { tag: "v1.0.1" })
    ).toEqual(version);
  });

  /** Có endpoint trả thẳng, không bọc — bóc phải chịu được cả hai. */
  it("chịu được response không bọc phong bì", async () => {
    mocked.get.mockResolvedValue({ data: payload });

    expect(await courseVersionService.list("c1")).toEqual(payload);
  });
});
