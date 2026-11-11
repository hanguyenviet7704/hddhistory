/** Một thao tác GHI mà một tài khoản ADMIN đã thực hiện. */
export interface AdminAuditRow {
  _id: string;
  actorId: string;
  actorEmail: string;
  actorName: string;
  method: string;
  /** Đường dẫn thật, đã bỏ query string: `/api/v1/paywall-config`. */
  path: string;
  /** Mẫu route có tham số, ví dụ `/coach-situations/:id`. Có thể rỗng. */
  route: string;
  statusCode: number;
  ok: boolean;
  errorMessage: string;
  /** Nội dung đã gửi lên, đã che secret. Chuỗi JSON, có thể đã bị cắt. */
  body: string;
  bodyTruncated: boolean;
  durationMs: number;
  serverDate: string;
  createdAt: string;
}

export interface AdminAuditPage {
  range: { from: string; to: string };
  page: number;
  limit: number;
  total: number;
  items: AdminAuditRow[];
  /** Những người ĐÃ TỪNG thao tác — không phải mọi admin. */
  actors: Array<{ id: string; email: string; name: string }>;
}

export interface AdminAuditQuery {
  from?: string;
  to?: string;
  actorId?: string;
  path?: string;
  result?: "ok" | "failed";
  page?: number;
  limit?: number;
}

/** Một trường đã đổi giữa hai lần lưu. */
export interface AdminAuditChange {
  /** Đường dẫn tới trường: `hotlines[1].number`. */
  field: string;
  before: unknown;
  after: unknown;
}

export interface AdminAuditDetail {
  row: AdminAuditRow;
  /**
   * `null` = KHÔNG so được (chưa có lần lưu nào trước ở khu vực này, hoặc nội
   * dung đã bị cắt). `[]` = có bấm lưu nhưng không đổi gì. Hai chuyện khác
   * nhau, và giao diện phải nói khác nhau.
   */
  changes: AdminAuditChange[] | null;
  previousAt: string | null;
  previousBy: string | null;
}
