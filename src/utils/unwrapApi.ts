/**
 * hddhistory-api bọc MỌI response JSON trong `{ statusCode, message, data }` —
 * `ResponseInterceptor` gắn toàn cục trong `main.ts`. Response ghi thẳng bằng
 * `@Res()` (tải file/blob) thì KHÔNG bị bọc.
 *
 * Trả nguyên `res.data` cho caller là trả cả phong bì, và caller đọc field ra
 * `undefined`. Hậu quả không hề nhẹ: một `undefined.trim()` hay `.map()` trong
 * render làm React unmount cả cây và TRẮNG toàn bộ trang admin, không toast,
 * không log.
 *
 * Nhận diện phong bì bằng `statusCode` chứ không chỉ bằng key `data`, vì
 * payload cũng có thể có key tên `data`.
 */
export const unwrapApi = <T>(body: any): T =>
  body && typeof body === "object" && "statusCode" in body && "data" in body
    ? (body.data as T)
    : (body as T);

export default unwrapApi;
