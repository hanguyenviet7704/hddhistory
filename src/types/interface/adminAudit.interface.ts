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
