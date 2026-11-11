import { unwrapApi } from "./unwrapApi";

/**
 * Phong bì `{ statusCode, message, data }` do `ResponseInterceptor` của
 * hddhistory-api gắn toàn cục. Bóc sai ở đây làm trắng cả trang admin.
 */
describe("unwrapApi", () => {
  it("bóc phong bì ra payload", () => {
    expect(
      unwrapApi({ statusCode: 200, message: "Success", data: { nextTag: "v1.0.0" } })
    ).toEqual({ nextTag: "v1.0.0" });
  });

  it("trả nguyên response không bọc", () => {
    expect(unwrapApi({ nextTag: "v1.0.0" })).toEqual({ nextTag: "v1.0.0" });
  });

  /** Payload cũng có thể có key `data` — chỉ `statusCode` mới là dấu phong bì. */
  it("không bóc payload chỉ vì nó có key data", () => {
    const payload = { data: [1, 2], total: 2 };
    expect(unwrapApi(payload)).toEqual(payload);
  });

  it("chịu được null và mảng", () => {
    expect(unwrapApi(null)).toBeNull();
    expect(unwrapApi([1, 2])).toEqual([1, 2]);
  });
});
